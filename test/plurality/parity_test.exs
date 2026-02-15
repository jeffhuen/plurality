defmodule Plurality.ParityTest do
  @moduledoc """
  Parity test: every pair from the irregulars data file should produce
  correct output from Plurality. This ensures we don't regress on
  the ~1,110 irregular pairs.

  Some pairs are intentionally overridden — see @overrides below.
  """
  use ExUnit.Case

  @priv_dir :code.priv_dir(:plurality) |> to_string()

  @pairs @priv_dir
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

  # Intentional overrides where Plurality uses a different preferred form.
  # Key = downcased singular, value = our preferred plural.
  # Pronouns listed as noun exceptions but aren't noun inflection.
  # We skip these entirely in parity tests.
  @pronoun_singulars MapSet.new(~w[her his its itself himself herself hers themself])
  @pronoun_plurals MapSet.new(~w[their theirs them themselves they])

  # Proper nouns with case-sensitive entries (e.g., Jerry→Jerrys
  # vs jerry→jerries). We prefer the common noun lowercase form.
  @proper_noun_skip MapSet.new(
                      @pairs
                      |> Enum.filter(fn {s, _p} ->
                        first = String.first(s)

                        starts_upper? =
                          first == String.upcase(first) and first != String.downcase(first)

                        lower = String.downcase(s)
                        has_lower? = Enum.any?(@pairs, fn {s2, _p2} -> s2 == lower end)
                        starts_upper? and has_lower?
                      end)
                      |> Enum.map(fn {s, _p} -> s end)
                    )

  @pluralize_overrides %{
    # Modern English overrides (prefer modern forms over classical Latin)
    "premium" => "premiums",
    "persona" => "personas",
    "vertex" => "vertices",
    "appendix" => "appendices",
    "schema" => "schemas",
    "index" => "indices",
    # chassis — uncountable, same form singular and plural
    "chassis" => "chassis"
  }

  # Singularize overrides: plural→singular where we intentionally differ
  @singularize_overrides %{
    # taxes → tax (not taxis — "taxis" is the plural of "taxi", a different word)
    "taxes" => "tax",
    # axes: both "axis" and "axe" pluralize to "axes". Genuine ambiguity.
    "axes" => :skip,
    # annexe vs annex — both valid singulars of annexes
    "annexes" => :skip,
    # Noe is a proper name, no→noes is handled by suffix rules
    "noes" => :skip,
    # Maries→Marie is a proper noun variant. We return "mary" (common noun).
    # Marie doesn't have a lowercase counterpart in exceptions.tsv so proper_noun_skip
    # doesn't catch it. Both forms are valid.
    "maries" => :skip
  }

  # Skip pluralize test for words where we intentionally use a different form
  @pluralize_skip MapSet.new(
                    @pluralize_overrides
                    |> Map.keys()
                    |> Enum.map(&String.downcase/1)
                  )

  describe "irregular parity — pluralize" do
    for {singular, plural} <- @pairs do
      singular_down = String.downcase(singular)

      skip? =
        MapSet.member?(@pluralize_skip, singular_down) or
          MapSet.member?(@pronoun_singulars, singular_down) or
          MapSet.member?(@proper_noun_skip, singular)

      unless skip? do
        @singular singular
        @plural plural

        test "pluralize(#{inspect(singular)}) == #{inspect(plural)}" do
          result = Plurality.pluralize(@singular)
          downcased_result = String.downcase(result)
          downcased_expected = String.downcase(@plural)

          assert downcased_result == downcased_expected,
                 "pluralize(#{inspect(@singular)}) returned #{inspect(result)}, expected #{inspect(@plural)}"
        end
      end
    end
  end

  describe "irregular parity — singularize" do
    for {singular, plural} <- @pairs do
      singular_down = String.downcase(singular)
      plural_down = String.downcase(plural)

      skip? =
        singular == plural or
          Map.has_key?(@singularize_overrides, plural_down) or
          MapSet.member?(@pronoun_plurals, plural_down) or
          MapSet.member?(@pronoun_singulars, singular_down) or
          MapSet.member?(@proper_noun_skip, singular)

      unless skip? do
        @singular singular
        @plural plural

        test "singularize(#{inspect(plural)}) == #{inspect(singular)}" do
          result = Plurality.singularize(@plural)
          downcased_result = String.downcase(result)
          downcased_expected = String.downcase(@singular)

          assert downcased_result == downcased_expected,
                 "singularize(#{inspect(@plural)}) returned #{inspect(result)}, expected #{inspect(@singular)}"
        end
      end
    end
  end

  describe "intentional overrides — pluralize" do
    test "premium → premiums (not premia)" do
      assert Plurality.pluralize("premium") == "premiums"
    end

    test "persona → personas (not personae)" do
      assert Plurality.pluralize("persona") == "personas"
    end

    test "vertex → vertices (not vertexes)" do
      assert Plurality.pluralize("vertex") == "vertices"
    end

    test "appendix → appendices (not appendixes)" do
      assert Plurality.pluralize("appendix") == "appendices"
    end

    test "schema → schemas (not schemata)" do
      assert Plurality.pluralize("schema") == "schemas"
    end

    test "index → indices (not indexes)" do
      assert Plurality.pluralize("index") == "indices"
    end
  end

  describe "intentional overrides — singularize" do
    test "taxes → tax (not taxis)" do
      assert Plurality.singularize("taxes") == "tax"
    end
  end
end
