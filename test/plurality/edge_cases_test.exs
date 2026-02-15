defmodule Plurality.EdgeCasesTest do
  use ExUnit.Case

  describe "empty and minimal input" do
    test "empty string" do
      assert Plurality.pluralize("") == ""
      assert Plurality.singularize("") == ""
      assert Plurality.plural?("") == false
      assert Plurality.singular?("") == false
      assert Plurality.inflect("", 1) == ""
      assert Plurality.inflect("", 2) == ""
    end

    test "single character" do
      # "a" is in uncountables (it's an article, not a noun)
      assert Plurality.pluralize("a") == "a"
      assert Plurality.pluralize("x") == "xes"
      assert Plurality.pluralize("s") == "ses"
    end

    test "two characters" do
      assert Plurality.pluralize("ox") == "oxen"
      assert Plurality.pluralize("ax") == "axes"
    end
  end

  describe "already-plural with check mode" do
    test "does not double-pluralize" do
      assert Plurality.pluralize("posts", check: true) == "posts"
      assert Plurality.pluralize("categories", check: true) == "categories"
      assert Plurality.pluralize("boxes", check: true) == "boxes"
      assert Plurality.pluralize("churches", check: true) == "churches"
      assert Plurality.pluralize("wolves", check: true) == "wolves"
    end

    test "does not double-pluralize irregulars" do
      assert Plurality.pluralize("children", check: true) == "children"
      assert Plurality.pluralize("people", check: true) == "people"
      assert Plurality.pluralize("mice", check: true) == "mice"
      assert Plurality.pluralize("geese", check: true) == "geese"
      assert Plurality.pluralize("feet", check: true) == "feet"
    end
  end

  describe "singularize traps" do
    test "taxes → tax (not taxis)" do
      assert Plurality.singularize("taxes") == "tax"
    end

    test "buses → bus" do
      assert Plurality.singularize("buses") == "bus"
    end

    test "statuses → status" do
      assert Plurality.singularize("statuses") == "status"
    end

    test "-ss words don't lose an s" do
      assert Plurality.singularize("boss") == "boss"
      assert Plurality.singularize("class") == "class"
      assert Plurality.singularize("glass") == "glass"
      assert Plurality.singularize("moss") == "moss"
    end
  end

  describe "identity words" do
    test "uncountables are unchanged in both directions" do
      uncountables = ~w[sheep fish deer moose software hardware news information]

      for word <- uncountables do
        assert Plurality.pluralize(word) == word,
               "pluralize(#{word}) should return #{word}"

        assert Plurality.singularize(word) == word,
               "singularize(#{word}) should return #{word}"
      end
    end

    test "identity irregulars are unchanged by singularize" do
      for word <- ["cat-o'-nine-tails", "faux-pas", "helium", "quartz", "sleep"] do
        assert Plurality.singularize(word) == word,
               "singularize(#{word}) should return #{word}"

        assert Plurality.pluralize(word) == word,
               "pluralize(#{word}) should return #{word}"
      end
    end
  end

  describe "pronouns are not inflected as nouns" do
    test "singularize does not map plural pronouns to unrelated singular pronouns" do
      assert Plurality.singularize("their") != "her"
      assert Plurality.singularize("them") != "he"
      assert Plurality.singularize("they") != "it"
      assert Plurality.singularize("they") != "she"
      assert Plurality.singularize("themselves") != "herself"
    end
  end

  describe "style preservation edge cases" do
    test "mixed case not recognized as pattern" do
      result = Plurality.pluralize("lEaF")
      assert result == "leaves" or result == "lEaFs"
    end

    test "all caps single word" do
      assert Plurality.pluralize("CAT") == "CATS"
    end

    test "title case irregular" do
      assert Plurality.pluralize("Child") == "Children"
      assert Plurality.pluralize("Person") == "People"
    end

    test "all caps irregular" do
      assert Plurality.pluralize("CHILD") == "CHILDREN"
      assert Plurality.pluralize("PERSON") == "PEOPLE"
    end

    test "singularize preserves case" do
      assert Plurality.singularize("CHILDREN") == "CHILD"
      assert Plurality.singularize("Children") == "Child"
      assert Plurality.singularize("LEAVES") == "LEAF"
      assert Plurality.singularize("Leaves") == "Leaf"
    end
  end

  describe "inflect/2" do
    test "negative counts return plural" do
      assert Plurality.inflect("cat", -1) == "cats"
    end

    test "zero returns plural" do
      assert Plurality.inflect("cat", 0) == "cats"
    end

    test "one returns singular" do
      assert Plurality.inflect("cats", 1) == "cat"
      assert Plurality.inflect("cat", 1) == "cat"
    end

    test "large counts return plural" do
      assert Plurality.inflect("cat", 1000) == "cats"
    end
  end
end
