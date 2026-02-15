defmodule Plurality.NihTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Corpus tests derived from the NIH SPECIALIST Lexicon (2025 release).
  Tests 47,566 noun singular/plural pairs in both directions against
  Plurality's engine.

  The NIH SPECIALIST Lexicon contains ~106K noun entry groups with rich
  morphological data covering medical, scientific, and general English
  vocabulary. Pairs that pass both pluralize and singularize are stored
  in `test/support/nih_pairs.txt` and verified here.

  Excluded pairs (by design, not bugs):
  - Classical Latin/Greek plurals where Plurality prefers modern English
    (e.g., -us → -i, -um → -a, -a → -ae, -itis → -itides)
  - Words Plurality treats as uncountable that NIH considers countable

  The NIH SPECIALIST Lexicon is freely available from the National Library
  of Medicine. See dev/research/nih/ for source data.
  """

  @pairs_path "test/support/nih_pairs.txt"

  defp stream_pairs do
    @pairs_path
    |> File.stream!()
    |> Stream.map(fn line ->
      [singular, plural] = line |> String.trim_trailing() |> String.split("\t")
      {singular, plural}
    end)
  end

  describe "NIH SPECIALIST Lexicon corpus" do
    test "pluralize" do
      {count, failures} =
        Enum.reduce(stream_pairs(), {0, []}, fn {singular, plural}, {n, acc} ->
          result = Plurality.pluralize(singular)

          if result == plural do
            {n + 1, acc}
          else
            {n + 1, [{singular, plural, result} | acc]}
          end
        end)

      assert failures == [],
             "#{length(failures)}/#{count} pluralize failures:\n" <>
               Enum.map_join(Enum.take(failures, 20), "\n", fn {s, expected, got} ->
                 "  #{s} → expected #{expected}, got #{got}"
               end)
    end

    test "singularize" do
      {count, failures} =
        Enum.reduce(stream_pairs(), {0, []}, fn {singular, plural}, {n, acc} ->
          result = Plurality.singularize(plural)

          if result == singular do
            {n + 1, acc}
          else
            {n + 1, [{singular, plural, result} | acc]}
          end
        end)

      assert failures == [],
             "#{length(failures)}/#{count} singularize failures:\n" <>
               Enum.map_join(Enum.take(failures, 20), "\n", fn {s, plural, got} ->
                 "  #{plural} → expected #{s}, got #{got}"
               end)
    end
  end
end
