defmodule Plurality.AgidTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Corpus tests derived from the Automatically Generated Inflection Database
  (AGID) by Kevin Atkinson. Tests 32,625 noun singular/plural pairs in both
  directions against Plurality's engine.

  The AGID corpus (v2016.01.19) contains ~35K lowercase noun entries. Pairs
  that pass both pluralize and singularize are stored in
  `test/support/agid_pairs.txt` and verified here.

  Excluded pairs (by design, not bugs):
  - Words Plurality treats as uncountable that AGID considers countable
  - Classical Latin plurals where Plurality prefers modern English forms
  - Archaic or extremely rare variant forms

  AGID is in the public domain. See dev/research/agid/agid-2016.01.19/README.
  """

  @pairs_path "test/support/agid_pairs.txt"

  defp stream_pairs do
    @pairs_path
    |> File.stream!()
    |> Stream.map(fn line ->
      [singular, plural] = line |> String.trim_trailing() |> String.split("\t")
      {singular, plural}
    end)
  end

  describe "AGID corpus" do
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
