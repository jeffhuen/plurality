defmodule Plurality.Style do
  @moduledoc """
  Case and style preservation for inflected words.

  When a word is inflected, the transformation happens on a downcased copy.
  This module detects the casing style of the original input and reapplies it
  to the inflected result, so that `"LEAF"` becomes `"LEAVES"` (not `"leaves"`)
  and `"Leaf"` becomes `"Leaves"` (not `"leaves"`).

  ## Supported styles

  | Style | Detection rule | Example |
  |-------|---------------|---------|
  | ALL CAPS | Every letter is uppercase, at least one letter present | `"LEAF"` → `"LEAVES"` |
  | Title Case | First character uppercase, rest lowercase | `"Leaf"` → `"Leaves"` |
  | lowercase | Default (no transformation applied) | `"leaf"` → `"leaves"` |

  ## Edge cases

  * If the original and result are identical, the result is returned as-is
    (no unnecessary string allocation).
  * Single-character words are not detected as Title Case (they have no
    "rest" to verify as lowercase).
  * Words with mixed casing (e.g., `"camelCase"`) are not detected as any
    special style and pass through unchanged.

  ## Usage

  This module is used internally by `Plurality.Engine`. It is not typically
  called directly, but is public so that `Plurality.Custom` can use it
  for consistent style handling.
  """

  @doc """
  Matches the casing style of `original` and applies it to `result`.

  Returns `result` unchanged if `original` is lowercase or has mixed casing.
  Applies `String.upcase/1` if `original` is ALL CAPS, or capitalizes the
  first character if `original` is Title Case.

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
      "camelcases"
  """
  @spec match_style(original :: String.t(), result :: String.t()) :: String.t()
  def match_style(original, result) when is_binary(original) and is_binary(result) do
    cond do
      original == result -> result
      all_upper?(original) -> String.upcase(result)
      title_case?(original) -> title_case(result)
      true -> result
    end
  end

  # Returns true if every character is uppercase and at least one character
  # has a case distinction (i.e., not all digits/punctuation).
  @spec all_upper?(String.t()) :: boolean()
  defp all_upper?(<<c, _rest::binary>> = word) when c in ?A..?Z do
    word == String.upcase(word)
  end

  defp all_upper?(_), do: false

  # Returns true if the first character is uppercase and all remaining
  # characters are lowercase. Requires at least 2 characters.
  @spec title_case?(String.t()) :: boolean()
  defp title_case?(<<c, rest::binary>>) when c in ?A..?Z and byte_size(rest) > 0 do
    rest == String.downcase(rest)
  end

  defp title_case?(_), do: false

  # Capitalizes the first character of a word, leaving the rest unchanged.
  @spec title_case(String.t()) :: String.t()
  defp title_case(<<c::utf8, rest::binary>>) do
    <<String.upcase(<<c::utf8>>)::binary, rest::binary>>
  end

  defp title_case(word), do: word
end
