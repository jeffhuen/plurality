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

    test "title case irregular with stem change" do
      assert Plurality.pluralize("Goose") == "Geese"
      assert Plurality.pluralize("Mouse") == "Mice"
      assert Plurality.pluralize("Tooth") == "Teeth"
      assert Plurality.pluralize("Foot") == "Feet"
      assert Plurality.pluralize("Man") == "Men"
      assert Plurality.pluralize("Woman") == "Women"
    end

    test "all caps irregular" do
      assert Plurality.pluralize("CHILD") == "CHILDREN"
      assert Plurality.pluralize("PERSON") == "PEOPLE"
    end

    test "all caps irregular with stem change" do
      assert Plurality.pluralize("GOOSE") == "GEESE"
      assert Plurality.pluralize("MOUSE") == "MICE"
      assert Plurality.pluralize("TOOTH") == "TEETH"
      assert Plurality.pluralize("FOOT") == "FEET"
      assert Plurality.pluralize("MAN") == "MEN"
    end

    test "singularize preserves case" do
      assert Plurality.singularize("CHILDREN") == "CHILD"
      assert Plurality.singularize("Children") == "Child"
      assert Plurality.singularize("LEAVES") == "LEAF"
      assert Plurality.singularize("Leaves") == "Leaf"
    end

    test "singularize preserves title case with stem change" do
      assert Plurality.singularize("Geese") == "Goose"
      assert Plurality.singularize("Mice") == "Mouse"
      assert Plurality.singularize("Teeth") == "Tooth"
      assert Plurality.singularize("Feet") == "Foot"
      assert Plurality.singularize("Men") == "Man"
      assert Plurality.singularize("Women") == "Woman"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # Bug-fix regression tests
  # ══════════════════════════════════════════════════════════════════

  describe "fix #1: trout is uncountable" do
    test "pluralize returns trout unchanged" do
      assert Plurality.pluralize("trout") == "trout"
    end

    test "singularize returns trout unchanged" do
      assert Plurality.singularize("trout") == "trout"
    end
  end

  describe "fix #2: modern/classical split" do
    test "modern defaults for previously-classical words" do
      pairs = [
        {"cactus", "cactuses"},
        {"chateau", "chateaus"},
        {"cherub", "cherubs"},
        {"curriculum", "curriculums"},
        {"fungus", "funguses"},
        {"octopus", "octopuses"},
        {"plateau", "plateaus"},
        {"seraph", "seraphs"},
        {"syllabus", "syllabuses"},
        {"tableau", "tableaus"}
      ]

      for {singular, modern} <- pairs do
        assert Plurality.pluralize(singular) == modern,
               "pluralize(#{singular}) should be #{modern}, got #{Plurality.pluralize(singular)}"
      end
    end

    test "classical mode returns classical plurals" do
      pairs = [
        {"cactus", "cacti"},
        {"chateau", "chateaux"},
        {"cherub", "cherubim"},
        {"curriculum", "curricula"},
        {"fungus", "fungi"},
        {"octopus", "octopi"},
        {"plateau", "plateaux"},
        {"seraph", "seraphim"},
        {"syllabus", "syllabi"},
        {"tableau", "tableaux"}
      ]

      for {singular, classical} <- pairs do
        assert Plurality.pluralize(singular, classical: true) == classical,
               "pluralize(#{singular}, classical: true) should be #{classical}, got #{Plurality.pluralize(singular, classical: true)}"
      end
    end

    test "singularize handles both modern and classical forms" do
      assert Plurality.singularize("octopuses") == "octopus"
      assert Plurality.singularize("octopi") == "octopus"
      assert Plurality.singularize("cherubs") == "cherub"
      assert Plurality.singularize("cherubim") == "cherub"
      assert Plurality.singularize("chateaus") == "chateau"
      assert Plurality.singularize("chateaux") == "chateau"
    end
  end

  describe "fix #3: head of state compound" do
    test "pluralize head of state" do
      assert Plurality.pluralize("head of state") == "heads of state"
    end

    test "singularize heads of state" do
      assert Plurality.singularize("heads of state") == "head of state"
    end
  end

  describe "fix #4: -oes irregulars" do
    test "pluralize -o words to -oes" do
      pairs = [
        {"mango", "mangoes"},
        {"veto", "vetoes"},
        {"domino", "dominoes"},
        {"embargo", "embargoes"},
        {"mosquito", "mosquitoes"}
      ]

      for {singular, plural} <- pairs do
        assert Plurality.pluralize(singular) == plural,
               "pluralize(#{singular}) should be #{plural}, got #{Plurality.pluralize(singular)}"
      end
    end

    test "singularize -oes words" do
      assert Plurality.singularize("mangoes") == "mango"
      assert Plurality.singularize("vetoes") == "veto"
    end
  end

  describe "fix #7: compound irregulars" do
    test "pluralize compound nouns" do
      assert Plurality.pluralize("mother-in-law") == "mothers-in-law"
      assert Plurality.pluralize("attorney general") == "attorneys general"
      assert Plurality.pluralize("court-martial") == "courts-martial"
      assert Plurality.pluralize("sergeant major") == "sergeants major"
    end

    test "singularize compound nouns" do
      assert Plurality.singularize("mothers-in-law") == "mother-in-law"
      assert Plurality.singularize("attorneys general") == "attorney general"
    end
  end

  describe "fix #11a: glass is countable" do
    test "pluralize glass to glasses" do
      assert Plurality.pluralize("glass") == "glasses"
    end

    test "singularize glasses to glass" do
      assert Plurality.singularize("glasses") == "glass"
    end
  end

  describe "fix #12: axis is canonical singular of axes" do
    test "singularize axes to axis" do
      assert Plurality.singularize("axes") == "axis"
    end

    test "pluralize axe to axes" do
      assert Plurality.pluralize("axe") == "axes"
    end
  end

  describe "fix #14: hovercraft is uncountable" do
    test "pluralize hovercraft unchanged" do
      assert Plurality.pluralize("hovercraft") == "hovercraft"
    end

    test "singularize hovercraft unchanged" do
      assert Plurality.singularize("hovercraft") == "hovercraft"
    end
  end

  describe "fix #15: pluralia tantum are uncountable" do
    test "shorts stays unchanged" do
      assert Plurality.pluralize("shorts") == "shorts"
      assert Plurality.singularize("shorts") == "shorts"
    end

    test "tweezers stays unchanged" do
      assert Plurality.pluralize("tweezers") == "tweezers"
      assert Plurality.singularize("tweezers") == "tweezers"
    end

    test "briefs stays unchanged" do
      assert Plurality.pluralize("briefs") == "briefs"
      assert Plurality.singularize("briefs") == "briefs"
    end
  end

  describe "fix #16: PascalCase compound words preserve casing" do
    test "singularize preserves PascalCase" do
      assert Plurality.singularize("ResourceAttachments") == "ResourceAttachment"
      assert Plurality.singularize("WorkingDays") == "WorkingDay"
      assert Plurality.singularize("CustomDays") == "CustomDay"
    end

    test "pluralize preserves PascalCase" do
      assert Plurality.pluralize("ResourceAttachment") == "ResourceAttachments"
      assert Plurality.pluralize("WorkingDay") == "WorkingDays"
    end

    test "pluralize with check preserves PascalCase" do
      assert Plurality.pluralize("ResourceAttachment", check: true) == "ResourceAttachments"
    end

    test "PascalCase with irregular last segment" do
      assert Plurality.singularize("SalesPersonPeople") == "SalesPersonPerson"
      assert Plurality.pluralize("SalesPersonChild") == "SalesPersonChildren"
    end

    test "all-caps compound words" do
      assert Plurality.pluralize("RESOURCEATTACHMENT") == "RESOURCEATTACHMENTS"
      assert Plurality.singularize("RESOURCEATTACHMENTS") == "RESOURCEATTACHMENT"
    end

    test "camelCase compound words" do
      assert Plurality.pluralize("resourceAttachment") == "resourceAttachments"
      assert Plurality.singularize("resourceAttachments") == "resourceAttachment"
    end
  end

  describe "fix #17: -se root words singularize correctly" do
    test "singularize common -se words" do
      pairs = [
        {"cases", "case"},
        {"phases", "phase"},
        {"doses", "dose"},
        {"roses", "rose"},
        {"poses", "pose"},
        {"noses", "nose"},
        {"purses", "purse"},
        {"courses", "course"},
        {"horses", "horse"},
        {"nurses", "nurse"},
        {"verses", "verse"},
        {"curses", "curse"},
        {"pulses", "pulse"},
        {"rinses", "rinse"},
        {"pauses", "pause"},
        {"causes", "cause"},
        {"clauses", "clause"},
        {"leases", "lease"},
        {"eases", "ease"},
        {"creases", "crease"},
        {"responses", "response"},
        {"expenses", "expense"},
        {"senses", "sense"},
        {"reverses", "reverse"},
        {"purposes", "purpose"},
        {"releases", "release"},
        {"licenses", "license"},
        {"increases", "increase"},
        {"universes", "universe"}
      ]

      for {plural, singular} <- pairs do
        assert Plurality.singularize(plural) == singular,
               "singularize(#{plural}) should be #{singular}, got #{Plurality.singularize(plural)}"
      end
    end

    test "existing -ses special cases still work" do
      # -sses -> -ss
      assert Plurality.singularize("bosses") == "boss"
      assert Plurality.singularize("classes") == "class"
      assert Plurality.singularize("masses") == "mass"

      # -ouses -> -ouse
      assert Plurality.singularize("houses") == "house"
      assert Plurality.singularize("mouses") == "mouse"

      # -yses -> -ysis
      assert Plurality.singularize("analyses") == "analysis"
      assert Plurality.singularize("paralyses") == "paralysis"

      # -s roots + -es (gas, bus, etc.)
      assert Plurality.singularize("gases") == "gas"
      assert Plurality.singularize("buses") == "bus"
    end

    test "round-trip pluralize -> singularize for -se words" do
      for word <- ~w[case phase dose rose nose purse course horse nurse verse] do
        assert word |> Plurality.pluralize() |> Plurality.singularize() == word,
               "round-trip failed for #{word}"
      end
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
