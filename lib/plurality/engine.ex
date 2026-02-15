defmodule Plurality.Engine do
  @moduledoc """
  Three-tier resolution engine for English noun inflection.

  This module is the core of Plurality. It loads irregular pairs, uncountable
  words, and suffix rules at compile time, then exposes functions that resolve
  any English noun through three tiers in order:

  ## Resolution tiers

  ### Tier 1 — Uncountables (`MapSet`, O(1) membership test)

  Words like `"sheep"`, `"software"`, and `"news"` that have no distinct plural
  form. Returned unchanged by both `pluralize/2` and `singularize/1`.

  Built from ~1,022 words curated from multiple sources and verified against
  Oxford and Merriam-Webster dictionaries.

  ### Tier 2 — Irregulars (`Map`, O(1) lookup)

  Direct singular↔plural mappings for words whose plural form cannot be
  predicted by suffix rules (e.g., `"child"` → `"children"`,
  `"person"` → `"people"`).

  Built from ~1,110 pairs curated from multiple sources, with modern English
  forms preferred over classical Latin (e.g., `"schema"` → `"schemas"`
  instead of `"schemata"`).

  Two maps are maintained:

  * `singular → plural` — used by `pluralize/2`
  * `plural → singular` — used by `singularize/1`, built from ALL sources
    (including overridden entries) so both old and new plural forms resolve

  ### Tier 3 — Suffix rules (last-byte dispatch, O(1))

  Pattern-based transformation using `Plurality.Rules`. Extracts the last byte
  of the word, dispatches via BEAM `select_val` jump table, then confirms the
  full suffix with a sized-skip binary match. See `Plurality.Rules` for details.

  ## Compile-time data pipeline

  All data is loaded from TSV and TXT files in `priv/` at compile time via
  module attributes. The pipeline:

  1. Load pre-merged data from `priv/data/irregulars.tsv` and
     `priv/data/uncountables.txt`
  2. Build forward map (singular → plural) and reverse map (plural → singular)
  3. Auto-exclude words from uncountables if they appear in irregulars
     with a different plural form (e.g., `"data"` is uncountable but
     `"data"` → `"datum"` exists in irregulars)
  4. Apply force overrides (`@force_uncountable`, `@force_countable`)
  5. Build downcased lookup maps with lowercase-entry priority

  There is zero runtime file I/O, zero regex, and zero ETS usage.

  ## Case-insensitive matching

  All lookups are performed against downcased maps. When case-variant entries
  exist in the source data (e.g., `"jerry"` → `"jerries"` AND
  `"Jerry"` → `"Jerrys"`), the lowercase entry takes priority since it
  represents the common noun form. This is implemented by sorting entries
  lowercase-first and using `Map.put_new/3`.

  ## Singularize ordering

  `singularize/1` checks the irregular reverse map **before** the uncountables
  set. This is intentional: words like `"data"`, `"graffiti"`, and `"testes"`
  appear in both sets, and singularization should resolve them to their base
  forms (`"datum"`, `"graffito"`, `"testis"`).

  ## Usage

  This module is not typically called directly. Use the public API in
  `Plurality` instead, which delegates to this module.
  """

  alias Plurality.Rules
  alias Plurality.Style

  # ══════════════════════════════════════════════════════════════════
  # Data Loading — compile-time
  # ══════════════════════════════════════════════════════════════════

  @priv_dir :code.priv_dir(:plurality) |> to_string()

  @external_resource Path.expand("../../priv/data/classical_overrides.tsv", __DIR__)
  @external_resource Path.expand("../../priv/data/irregulars.tsv", __DIR__)
  @external_resource Path.expand("../../priv/data/uncountables.txt", __DIR__)

  # Load classical overrides from priv/data/classical_overrides.tsv
  # Format: singular<TAB>modern_plural<TAB>classical_plural
  # Only contains words where the default is modern but a classical form exists.
  # ~69 entries curated from NIH SPECIALIST Lexicon and verified against
  # standard references.
  @classical_overrides @priv_dir
                       |> Path.join("data/classical_overrides.tsv")
                       |> File.read!()
                       |> String.split("\n", trim: true)
                       |> Enum.map(fn line ->
                         case String.split(line, "\t", parts: 3) do
                           [singular, modern, classical] ->
                             {String.trim(singular), String.trim(modern), String.trim(classical)}

                           _ ->
                             nil
                         end
                       end)
                       |> Enum.reject(&is_nil/1)

  # Load pre-merged irregular pairs from priv/data/irregulars.tsv
  # Format: singular<TAB>plural, one pair per line, sorted alphabetically.
  # This file is the pre-merged result of all data sources with proper
  # precedence already applied. ~1,110 pairs.
  @irregulars @priv_dir
              |> Path.join("data/irregulars.tsv")
              |> File.read!()
              |> String.split("\n", trim: true)
              |> Enum.map(fn line ->
                case String.split(line, "\t", parts: 2) do
                  [singular, plural] -> {String.trim(singular), String.trim(plural)}
                  _ -> nil
                end
              end)
              |> Enum.reject(&is_nil/1)

  # Load pre-merged uncountable words from priv/data/uncountables.txt
  # One word per line, sorted alphabetically. ~1,022 words.
  @raw_uncountables @priv_dir
                    |> Path.join("data/uncountables.txt")
                    |> File.read!()
                    |> String.split("\n", trim: true)
                    |> Enum.map(&String.trim/1)
                    |> Enum.reject(&(&1 == ""))

  # ══════════════════════════════════════════════════════════════════
  # Tier 2: Irregulars — Map, O(1) lookup both directions
  # ══════════════════════════════════════════════════════════════════

  # Singular → plural map (forward lookup for pluralization)
  @singular_to_plural Map.new(@irregulars)

  # Plural → singular map (reverse lookup for singularization).
  # Identity entries (singular == plural) are excluded to avoid infinite loops.
  @plural_to_singular @irregulars
                      |> Enum.reject(fn {s, p} -> s == p end)
                      |> Enum.reduce(%{}, fn {s, p}, acc -> Map.put_new(acc, p, s) end)

  # ══════════════════════════════════════════════════════════════════
  # Tier 1: Uncountables — MapSet, O(1) lookup
  # (Built AFTER irregulars to resolve conflicts)
  # ══════════════════════════════════════════════════════════════════

  # Auto-exclusion: words in both uncountables AND irregulars with a *different*
  # plural form are NOT truly uncountable. Irregulars take priority.
  @exception_singulars @singular_to_plural
                       |> Enum.reject(fn {s, p} -> String.downcase(s) == String.downcase(p) end)
                       |> Enum.map(fn {s, _p} -> String.downcase(s) end)
                       |> MapSet.new()

  # Force-keep as uncountable even if they appear in irregulars
  @force_uncountable MapSet.new(~w[chassis])

  # Force-remove from uncountables (countable words incorrectly listed as uncountable)
  @force_countable MapSet.new(~w[access])

  @uncountables @raw_uncountables
                |> Enum.map(&String.downcase/1)
                |> MapSet.new()
                |> MapSet.difference(@exception_singulars)
                |> MapSet.union(@force_uncountable)
                |> MapSet.difference(@force_countable)

  # ══════════════════════════════════════════════════════════════════
  # Downcased lookup maps — case-insensitive matching
  # ══════════════════════════════════════════════════════════════════

  # When case-variant entries exist (e.g., jerry→jerries AND Jerry→Jerrys),
  # lowercase originals sort first (preferred) via Map.put_new.
  @singular_to_plural_down @singular_to_plural
                           |> Enum.reject(fn {s, _p} ->
                             MapSet.member?(@force_uncountable, String.downcase(s))
                           end)
                           |> Enum.map(fn {s, p} ->
                             {s, String.downcase(s), String.downcase(p)}
                           end)
                           |> Enum.sort_by(fn {original, _dk, _dp} ->
                             if original == String.downcase(original), do: 0, else: 1
                           end)
                           |> Enum.reduce(%{}, fn {_original, dk, dp}, acc ->
                             Map.put_new(acc, dk, dp)
                           end)

  @plural_to_singular_down @plural_to_singular
                           |> Enum.map(fn {p, s} ->
                             {p, String.downcase(p), String.downcase(s)}
                           end)
                           |> Enum.sort_by(fn {original, _dk, _ds} ->
                             if original == String.downcase(original), do: 0, else: 1
                           end)
                           |> Enum.reduce(%{}, fn {_original, dk, ds}, acc ->
                             Map.put_new(acc, dk, ds)
                           end)

  @uncountables_down @uncountables

  # ══════════════════════════════════════════════════════════════════
  # Classical overrides — compile-time maps
  # ══════════════════════════════════════════════════════════════════

  # Singular → classical plural (used when classical: true)
  @singular_to_classical_down @classical_overrides
                              |> Enum.map(fn {s, _m, c} ->
                                {String.downcase(s), String.downcase(c)}
                              end)
                              |> Map.new()

  # Enrich the reverse map with classical plural forms so that
  # singularize works for BOTH modern and classical plurals.
  # e.g., both "antennas"→"antenna" AND "antennae"→"antenna"
  @plural_to_singular_down @classical_overrides
                           |> Enum.reject(fn {s, _m, c} ->
                             String.downcase(s) == String.downcase(c)
                           end)
                           |> Enum.reduce(@plural_to_singular_down, fn {s, _m, c}, acc ->
                             Map.put_new(acc, String.downcase(c), String.downcase(s))
                           end)

  # ══════════════════════════════════════════════════════════════════
  # Public API
  # ══════════════════════════════════════════════════════════════════

  @doc """
  Converts a word to its plural form.

  See `Plurality.pluralize/2` for full documentation.
  """
  @spec pluralize(word :: String.t(), opts :: Plurality.pluralize_opts()) :: String.t()
  def pluralize(word, opts \\ [])

  def pluralize("", _opts), do: ""

  def pluralize(word, opts) do
    downcased = downcase(word)

    cond do
      # Tier 2 first: irregulars are the most common special cases.
      # No word appears in both irregulars and uncountables (auto-excluded
      # at compile time), so this reorder is output-safe.
      Map.has_key?(@singular_to_plural_down, downcased) ->
        # Check cheap map lookup before evaluating classical?(opts) —
        # only 95 of 1,110 irregulars have classical overrides
        if Map.has_key?(@singular_to_classical_down, downcased) and classical?(opts) do
          apply_style(word, downcased, @singular_to_classical_down[downcased])
        else
          apply_style(word, downcased, @singular_to_plural_down[downcased])
        end

      opts[:check] && known_plural?(downcased) ->
        word

      uncountable?(downcased) ->
        word

      opts[:check] && already_plural?(downcased) ->
        word

      true ->
        if has_space?(word) do
          {prefix, last} = split_at_last_space(word)
          prefix <> pluralize(last, opts)
        else
          apply_style(word, downcased, Rules.apply_plural_rule(downcased, classical?(opts)))
        end
    end
  end

  @doc """
  Converts a word to its singular form.

  See `Plurality.singularize/1` for full documentation.
  """
  @spec singularize(word :: String.t()) :: String.t()
  def singularize(""), do: ""

  def singularize(word) do
    downcased = downcase(word)

    cond do
      # Irregular reverse lookup BEFORE uncountable check.
      # Words like "data", "graffiti", "testes" appear in both sets;
      # singularization should resolve them to their base forms.
      Map.has_key?(@plural_to_singular_down, downcased) ->
        apply_style(word, downcased, @plural_to_singular_down[downcased])

      uncountable?(downcased) ->
        word

      true ->
        # No irregular/uncountable match — try compound splitting before rules
        case split_compound(word) do
          {prefix, last} ->
            prefix <> singularize(last)

          nil ->
            result = Rules.apply_singular_rule(downcased)
            apply_style(word, downcased, result)
        end
    end
  end

  @doc """
  Returns `true` if the word is in plural form or is uncountable.

  See `Plurality.plural?/1` for full documentation.
  """
  @spec plural?(word :: String.t()) :: boolean()
  def plural?(""), do: false

  def plural?(word) do
    downcased = downcase(word)

    cond do
      uncountable?(downcased) ->
        true

      known_plural?(downcased) ->
        true

      already_plural?(downcased) ->
        true

      true ->
        case split_compound(word) do
          {_prefix, last} -> plural?(last)
          nil -> false
        end
    end
  end

  @doc """
  Returns `true` if the word is in singular form or is uncountable.

  See `Plurality.singular?/1` for full documentation.
  """
  @spec singular?(word :: String.t()) :: boolean()
  def singular?(""), do: false

  def singular?(word) do
    downcased = downcase(word)

    cond do
      uncountable?(downcased) ->
        true

      Map.has_key?(@singular_to_plural_down, downcased) ->
        true

      Map.has_key?(@plural_to_singular_down, downcased) ->
        false

      not already_plural?(downcased) ->
        true

      true ->
        case split_compound(word) do
          {_prefix, last} -> singular?(last)
          nil -> false
        end
    end
  end

  @doc """
  Inflects a word based on count.

  See `Plurality.inflect/2` for full documentation.
  """
  @spec inflect(word :: String.t(), count :: integer(), opts :: Plurality.pluralize_opts()) ::
          String.t()
  def inflect(word, 1, _opts), do: singularize(word)
  def inflect(word, _count, opts), do: pluralize(word, opts)

  # ══════════════════════════════════════════════════════════════════
  # Internal helpers
  # ══════════════════════════════════════════════════════════════════

  # Fast space check: byte-by-byte scan that bails on the first byte.
  # For typical single-word inputs (99%+), this returns false after
  # checking just the first byte — much cheaper than :binary.match setup.
  @spec has_space?(String.t()) :: boolean()
  defp has_space?(<<?\s, _::binary>>), do: true
  defp has_space?(<<_, rest::binary>>), do: has_space?(rest)
  defp has_space?(<<>>), do: false

  # Splits a compound noun at the last space.
  # Only called when has_space? returned true.
  # "status code" → {"status ", "code"}
  # "post office box" → {"post office ", "box"}
  @spec split_at_last_space(String.t()) :: {String.t(), String.t()}
  defp split_at_last_space(word) do
    {pos, 1} =
      :binary.match(word, <<?\s>>, [{:scope, {byte_size(word), -byte_size(word)}}])

    prefix = binary_part(word, 0, pos + 1)
    last = binary_part(word, pos + 1, byte_size(word) - pos - 1)
    {prefix, last}
  end

  # Splits a compound noun on the last space.
  # Returns {prefix_with_space, last_word} or nil if no space found.
  # Used by singularize, plural?, and singular?.
  @spec split_compound(String.t()) :: {String.t(), String.t()} | nil
  defp split_compound(word) do
    case :binary.match(word, <<?\s>>, [{:scope, {byte_size(word), -byte_size(word)}}]) do
      {pos, 1} ->
        prefix = binary_part(word, 0, pos + 1)
        last = binary_part(word, pos + 1, byte_size(word) - pos - 1)
        {prefix, last}

      :nomatch ->
        nil
    end
  end

  # Fast downcase: skip String.downcase when the first byte is already lowercase ASCII.
  # Covers the vast majority of calls (lowercase English words).
  @spec downcase(String.t()) :: String.t()
  defp downcase(<<c, _rest::binary>> = word) when c in ?a..?z do
    word
  end

  defp downcase(word), do: String.downcase(word)

  # Fast style application: skip Style.match_style when word is already lowercase
  # (word == downcased means no case transformation needed).
  @spec apply_style(String.t(), String.t(), String.t()) :: String.t()
  defp apply_style(word, downcased, result) when word == downcased, do: result
  defp apply_style(word, _downcased, result), do: Style.match_style(word, result)

  # Resolves the classical? flag from per-call opts, falling back to app config.
  # Uses :persistent_term for near-zero-cost reads on the hot path.
  @spec classical?(keyword()) :: boolean()
  defp classical?([]), do: classical_default()
  defp classical?(classical: val) when is_boolean(val), do: val
  defp classical?(check: _), do: classical_default()

  defp classical?(opts) do
    case Keyword.get(opts, :classical) do
      nil -> classical_default()
      val -> val
    end
  end

  @spec classical_default() :: boolean()
  defp classical_default do
    case :persistent_term.get({__MODULE__, :classical}, :unset) do
      :unset ->
        val = Application.get_env(:plurality, :classical, false)
        :persistent_term.put({__MODULE__, :classical}, val)
        val

      val ->
        val
    end
  end

  @doc false
  @spec reset_classical_cache() :: :ok
  def reset_classical_cache do
    :persistent_term.erase({__MODULE__, :classical})
    :ok
  rescue
    ArgumentError -> :ok
  end

  @spec uncountable?(String.t()) :: boolean()
  defp uncountable?(downcased), do: MapSet.member?(@uncountables_down, downcased)

  @spec known_plural?(String.t()) :: boolean()
  defp known_plural?(downcased), do: Map.has_key?(@plural_to_singular_down, downcased)

  # Attempts round-trip singularization→pluralization to detect if a word
  # is already plural. Returns true if singularize produces a different word
  # and pluralizing that result gives back the original.
  @spec already_plural?(String.t()) :: boolean()
  defp already_plural?(downcased) do
    singular = Rules.apply_singular_rule(downcased)
    singular != downcased and Rules.apply_plural_rule(singular) == downcased
  end
end
