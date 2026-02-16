defmodule Plurality.Style do
  @moduledoc """
  Case and style preservation for inflected words.

  When a word is inflected, the transformation happens on a downcased copy.
  This module detects the casing style of the original input and reapplies it
  to the inflected result, so that `"LEAF"` becomes `"LEAVES"` (not `"leaves"`)
  and `"Leaf"` becomes `"Leaves"` (not `"leaves"`).

  ## How it works

  Inflection only changes the suffix of a word. This module finds the shared
  prefix between the original and the result via a byte-walking scan, slices
  it from the original (zero-copy sub-binary), and appends the remaining
  suffix from the inflected result.

  For ALL CAPS input, a single `String.upcase/1` on the whole result is
  faster and used instead.

  ## Examples

  | Original | Inflected | Output |
  |----------|-----------|--------|
  | `"LEAF"` | `"leaves"` | `"LEAVES"` |
  | `"Leaf"` | `"leaves"` | `"Leaves"` |
  | `"leaf"` | `"leaves"` | `"leaves"` |
  | `"ResourceAttachment"` | `"resourceattachments"` | `"ResourceAttachments"` |
  | `"camelCase"` | `"camelcases"` | `"camelCases"` |

  ## Usage

  This module is used internally by `Plurality.Engine` and `Plurality.Custom`.
  """

  @doc """
  Transfers the casing pattern of `original` onto `result`.

  Returns `result` unchanged when `original` and `result` are identical.

  ## Examples

      iex> Plurality.Style.match_style("LEAF", "leaves")
      "LEAVES"

      iex> Plurality.Style.match_style("Leaf", "leaves")
      "Leaves"

      iex> Plurality.Style.match_style("leaf", "leaves")
      "leaves"

      iex> Plurality.Style.match_style("sheep", "sheep")
      "sheep"

      iex> Plurality.Style.match_style("camelCase", "camelcases")
      "camelCases"

      iex> Plurality.Style.match_style("ResourceAttachment", "resourceattachments")
      "ResourceAttachments"
  """
  @spec match_style(String.t(), String.t()) :: String.t()
  def match_style(original, result) when is_binary(original) and is_binary(result) do
    cond do
      original == result -> result
      all_upper?(original) -> String.upcase(result)
      true -> transfer_by_prefix(original, result)
    end
  end

  # ── Fast-path detector ──────────────────────────────────────────

  @spec all_upper?(String.t()) :: boolean()
  defp all_upper?(<<c, _rest::binary>> = word) when c in ?A..?Z do
    word == String.upcase(word)
  end

  defp all_upper?(_), do: false

  # ── Prefix slicing ─────────────────────────────────────────────

  # Finds the shared prefix between `downcase(original)` and `result`
  # via byte walking, slices it from `original` (zero-copy sub-binary),
  # and appends the remaining tail from `result` as-is.
  #
  # ALL CAPS input is handled before this function is called (via
  # `all_upper?/1` + `String.upcase/1`), so the tail never needs
  # uppercasing here.
  @spec transfer_by_prefix(String.t(), String.t()) :: String.t()
  defp transfer_by_prefix(original, result) do
    shared = shared_prefix_size(original, result, 0)
    prefix = binary_part(original, 0, shared)
    tail = binary_part(result, shared, byte_size(result) - shared)
    prefix <> tail
  end

  # Counts leading bytes where `downcase(original)` matches `result`.
  @spec shared_prefix_size(String.t(), String.t(), non_neg_integer()) :: non_neg_integer()
  defp shared_prefix_size(<<o, orig_rest::binary>>, <<r, res_rest::binary>>, n)
       when o in ?A..?Z and r == o + 32 do
    shared_prefix_size(orig_rest, res_rest, n + 1)
  end

  defp shared_prefix_size(<<o, orig_rest::binary>>, <<r, res_rest::binary>>, n)
       when o == r do
    shared_prefix_size(orig_rest, res_rest, n + 1)
  end

  defp shared_prefix_size(
         <<o_char::utf8, orig_rest::binary>>,
         <<r_char::utf8, res_rest::binary>>,
         n
       )
       when o_char > 127 do
    o_str = <<o_char::utf8>>

    if String.downcase(o_str) == <<r_char::utf8>> do
      shared_prefix_size(orig_rest, res_rest, n + byte_size(o_str))
    else
      n
    end
  end

  defp shared_prefix_size(_original, _result, n), do: n
end
