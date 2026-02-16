defmodule Plurality.ClassicalTest do
  use ExUnit.Case

  # ══════════════════════════════════════════════════════════════════
  # Classical pluralization — override table
  # ══════════════════════════════════════════════════════════════════

  describe "classical pluralization via overrides table" do
    # Latin 1st declension: -a → -ae
    test "Latin feminine -a → -ae" do
      pairs = [
        {"antenna", "antennae"},
        {"aurora", "aurorae"},
        {"fauna", "faunae"},
        {"flora", "florae"},
        {"formula", "formulae"},
        {"hydra", "hydrae"},
        {"hyperbola", "hyperbolae"},
        {"lacuna", "lacunae"},
        {"medusa", "medusae"},
        {"nebula", "nebulae"},
        {"nova", "novae"},
        {"parabola", "parabolae"},
        {"persona", "personae"},
        {"umbra", "umbrae"},
        {"abscissa", "abscissae"}
      ]

      for {singular, classical} <- pairs do
        assert Plurality.pluralize(singular, classical: true) == classical,
               "#{singular} → expected #{classical}, got #{Plurality.pluralize(singular, classical: true)}"
      end
    end

    # Latin 2nd declension: -us → -i
    test "Latin masculine -us → -i" do
      pairs = [
        {"campus", "campi"},
        {"focus", "foci"},
        {"genius", "genii"},
        {"hippopotamus", "hippopotami"},
        {"nucleolus", "nucleoli"},
        {"radius", "radii"},
        {"stylus", "styli"},
        {"torus", "tori"},
        {"uterus", "uteri"}
      ]

      for {singular, classical} <- pairs do
        assert Plurality.pluralize(singular, classical: true) == classical,
               "#{singular} → expected #{classical}, got #{Plurality.pluralize(singular, classical: true)}"
      end
    end

    # Latin 2nd declension neuter: -um → -a
    test "Latin neuter -um → -a" do
      pairs = [
        {"aquarium", "aquaria"},
        {"arboretum", "arboreta"},
        {"compendium", "compendia"},
        {"consortium", "consortia"},
        {"cranium", "crania"},
        {"dictum", "dicta"},
        {"emporium", "emporia"},
        {"encomium", "encomia"},
        {"gymnasium", "gymnasia"},
        {"honorarium", "honoraria"},
        {"interregnum", "interregna"},
        {"lustrum", "lustra"},
        {"maximum", "maxima"},
        {"medium", "media"},
        {"memorandum", "memoranda"},
        {"millennium", "millennia"},
        {"minimum", "minima"},
        {"momentum", "momenta"},
        {"optimum", "optima"},
        {"phylum", "phyla"},
        {"premium", "premia"},
        {"quantum", "quanta"},
        {"rostrum", "rostra"},
        {"spectrum", "spectra"},
        {"speculum", "specula"},
        {"stadium", "stadia"},
        {"trapezium", "trapezia"},
        {"ultimatum", "ultimata"},
        {"vacuum", "vacua"},
        {"velum", "vela"}
      ]

      for {singular, classical} <- pairs do
        assert Plurality.pluralize(singular, classical: true) == classical,
               "#{singular} → expected #{classical}, got #{Plurality.pluralize(singular, classical: true)}"
      end
    end

    # Latin 3rd declension: -ex/-ix → -ices
    test "Latin -ex/-ix → -ices" do
      pairs = [
        {"apex", "apices"},
        {"cortex", "cortices"},
        {"latex", "latices"},
        {"pontifex", "pontifices"},
        {"simplex", "simplices"},
        {"vortex", "vortices"}
      ]

      for {singular, classical} <- pairs do
        assert Plurality.pluralize(singular, classical: true) == classical,
               "#{singular} → expected #{classical}, got #{Plurality.pluralize(singular, classical: true)}"
      end
    end

    # Greek neuter: -a → -ata
    test "Greek neuter -a → -ata" do
      pairs = [
        {"lemma", "lemmata"},
        {"schema", "schemata"},
        {"stigma", "stigmata"},
        {"trauma", "traumata"}
      ]

      for {singular, classical} <- pairs do
        assert Plurality.pluralize(singular, classical: true) == classical,
               "#{singular} → expected #{classical}, got #{Plurality.pluralize(singular, classical: true)}"
      end
    end

    # Greek 3rd declension: -on → -a
    test "Greek -on → -a (via overrides)" do
      pairs = [
        {"ganglion", "ganglia"},
        {"oxymoron", "oxymora"}
      ]

      for {singular, classical} <- pairs do
        assert Plurality.pluralize(singular, classical: true) == classical,
               "#{singular} → expected #{classical}, got #{Plurality.pluralize(singular, classical: true)}"
      end
    end

    # 4th declension (unchanged): nexus → nexus
    test "Latin 4th declension unchanged" do
      assert Plurality.pluralize("nexus", classical: true) == "nexus"
    end

    # Greek irregular: platypus → platypodes
    test "Greek irregular platypus" do
      assert Plurality.pluralize("platypus", classical: true) == "platypodes"
    end

    # Latin 3rd declension neuter: corpus → corpora
    test "Latin 3rd declension corpus" do
      assert Plurality.pluralize("corpus", classical: true) == "corpora"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # Classical pluralization — suffix rules
  # ══════════════════════════════════════════════════════════════════

  describe "classical pluralization via suffix rules" do
    test "-us → -i for unknown Latin words" do
      # Words not in the irregulars or overrides table
      assert Plurality.Rules.apply_plural_rule("fungus", true) == "fungi"
      assert Plurality.Rules.apply_plural_rule("alumnus", true) == "alumni"
    end

    test "-um → -a for unknown Latin words" do
      assert Plurality.Rules.apply_plural_rule("symposium", true) == "symposia"
      assert Plurality.Rules.apply_plural_rule("addendum", true) == "addenda"
    end

    test "-ix/-ex → -ices for unknown Latin words" do
      assert Plurality.Rules.apply_plural_rule("appendix", true) == "appendices"
      assert Plurality.Rules.apply_plural_rule("codex", true) == "codices"
    end

    test "-itis → -itides for unknown Latin words" do
      assert Plurality.Rules.apply_plural_rule("arthritis", true) == "arthritides"
      assert Plurality.Rules.apply_plural_rule("bursitis", true) == "bursitides"
      assert Plurality.Rules.apply_plural_rule("tendinitis", true) == "tendinitides"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # Default behavior unchanged
  # ══════════════════════════════════════════════════════════════════

  describe "default behavior (classical: false) unchanged" do
    test "modern defaults for words in overrides table" do
      assert Plurality.pluralize("aquarium") == "aquariums"
      assert Plurality.pluralize("formula") == "formulas"
      assert Plurality.pluralize("trauma") == "traumas"
      assert Plurality.pluralize("antenna") == "antennas"
      assert Plurality.pluralize("stadium") == "stadiums"
      assert Plurality.pluralize("schema") == "schemas"
      assert Plurality.pluralize("medium") == "mediums"
      assert Plurality.pluralize("focus") == "focuses"
      assert Plurality.pluralize("radius") == "radiuses"
    end

    test "already-classical defaults stay classical" do
      # These words are already in irregulars with classical defaults
      assert Plurality.pluralize("datum") == "data"
      assert Plurality.pluralize("criterion") == "criteria"
      assert Plurality.pluralize("phenomenon") == "phenomena"
      assert Plurality.pluralize("alumnus") == "alumni"
    end

    test "classical: false explicitly disables" do
      assert Plurality.pluralize("aquarium", classical: false) == "aquariums"
      assert Plurality.pluralize("formula", classical: false) == "formulas"
    end

    test "words without classical forms are unaffected" do
      assert Plurality.pluralize("leaf", classical: true) == "leaves"
      assert Plurality.pluralize("child", classical: true) == "children"
      assert Plurality.pluralize("box", classical: true) == "boxes"
      assert Plurality.pluralize("church", classical: true) == "churches"
      assert Plurality.pluralize("sheep", classical: true) == "sheep"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # Singularization — mode-independent
  # ══════════════════════════════════════════════════════════════════

  describe "singularize handles both modern and classical forms" do
    test "modern plurals singularize correctly" do
      assert Plurality.singularize("aquariums") == "aquarium"
      assert Plurality.singularize("formulas") == "formula"
      assert Plurality.singularize("traumas") == "trauma"
      assert Plurality.singularize("antennas") == "antenna"
      assert Plurality.singularize("stadiums") == "stadium"
      assert Plurality.singularize("schemas") == "schema"
    end

    test "classical plurals singularize correctly via reverse map" do
      assert Plurality.singularize("aquaria") == "aquarium"
      assert Plurality.singularize("antennae") == "antenna"
      assert Plurality.singularize("formulae") == "formula"
      assert Plurality.singularize("stadia") == "stadium"
      assert Plurality.singularize("nebulae") == "nebula"
      assert Plurality.singularize("foci") == "focus"
      assert Plurality.singularize("radii") == "radius"
      assert Plurality.singularize("apices") == "apex"
      assert Plurality.singularize("vortices") == "vortex"
      assert Plurality.singularize("corpora") == "corpus"
    end

    test "Greek -ata → -a singularization via suffix rule" do
      assert Plurality.singularize("traumata") == "trauma"
      assert Plurality.singularize("schemata") == "schema"
      assert Plurality.singularize("stigmata") == "stigma"
      assert Plurality.singularize("lemmata") == "lemma"
    end

    test "Latin -ae → -a singularization via suffix rule" do
      # These work via suffix rule even for words not in the map
      assert Plurality.singularize("antennae") == "antenna"
      assert Plurality.singularize("formulae") == "formula"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # False positive protection
  # ══════════════════════════════════════════════════════════════════

  describe "false positive protection" do
    test "-a → -ae NOT applied as suffix rule (sofa, pizza would break)" do
      # These should NOT become sofae, pizzae — -a→-ae is overrides-only
      assert Plurality.pluralize("sofa", classical: true) == "sofas"
      assert Plurality.pluralize("pizza", classical: true) == "pizzas"
      assert Plurality.pluralize("banana", classical: true) == "bananas"
    end

    test "-on → -a NOT applied as suffix rule (button, person would break)" do
      assert Plurality.pluralize("button", classical: true) == "buttons"
      assert Plurality.pluralize("melon", classical: true) == "melons"
    end

    test "-i → -us NOT applied as suffix rule for singularization" do
      # taxi, ski, broccoli should NOT become taxus, skus, broccolus
      assert Plurality.singularize("taxi") == "taxi"
      assert Plurality.singularize("ski") == "ski"
      assert Plurality.singularize("broccoli") == "broccoli"
    end

    test "-a → -um NOT applied as suffix rule for singularization" do
      # sofa, pizza should NOT become sofum, pizzum
      assert Plurality.singularize("sofa") == "sofa"
      assert Plurality.singularize("pizza") == "pizza"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # Case preservation with classical mode
  # ══════════════════════════════════════════════════════════════════

  describe "case preservation in classical mode" do
    test "Title Case" do
      assert Plurality.pluralize("Aquarium", classical: true) == "Aquaria"
      assert Plurality.pluralize("Formula", classical: true) == "Formulae"
      assert Plurality.pluralize("Trauma", classical: true) == "Traumata"
    end

    test "ALL CAPS" do
      assert Plurality.pluralize("AQUARIUM", classical: true) == "AQUARIA"
      assert Plurality.pluralize("FORMULA", classical: true) == "FORMULAE"
    end

    test "lowercase" do
      assert Plurality.pluralize("aquarium", classical: true) == "aquaria"
      assert Plurality.pluralize("formula", classical: true) == "formulae"
    end

    test "singularize classical forms with case preservation" do
      assert Plurality.singularize("Aquaria") == "Aquarium"
      assert Plurality.singularize("ANTENNAE") == "ANTENNA"
      assert Plurality.singularize("Traumata") == "Trauma"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # inflect/3 with classical option
  # ══════════════════════════════════════════════════════════════════

  describe "inflect/3 with classical option" do
    test "count 1 returns singular regardless of classical flag" do
      assert Plurality.inflect("aquarium", 1) == "aquarium"
      assert Plurality.inflect("aquarium", 1, classical: true) == "aquarium"
    end

    test "count != 1 uses classical when specified" do
      assert Plurality.inflect("aquarium", 2, classical: true) == "aquaria"
      assert Plurality.inflect("formula", 0, classical: true) == "formulae"
      assert Plurality.inflect("trauma", 3, classical: true) == "traumata"
    end

    test "count != 1 uses modern by default" do
      assert Plurality.inflect("aquarium", 2) == "aquariums"
      assert Plurality.inflect("formula", 0) == "formulas"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # App-wide classical config
  # ══════════════════════════════════════════════════════════════════

  describe "app-wide classical config" do
    setup do
      on_exit(fn ->
        Application.delete_env(:plurality, :classical)
        Plurality.Engine.reset_classical_cache()
      end)
    end

    test "config :plurality, classical: true changes default" do
      Application.put_env(:plurality, :classical, true)
      Plurality.Engine.reset_classical_cache()
      assert Plurality.pluralize("aquarium") == "aquaria"
      assert Plurality.pluralize("formula") == "formulae"
    end

    test "per-call classical: false overrides app config" do
      Application.put_env(:plurality, :classical, true)
      Plurality.Engine.reset_classical_cache()
      assert Plurality.pluralize("aquarium", classical: false) == "aquariums"
    end

    test "per-call classical: true overrides app config false" do
      Application.put_env(:plurality, :classical, false)
      Plurality.Engine.reset_classical_cache()
      assert Plurality.pluralize("aquarium", classical: true) == "aquaria"
    end
  end

  # ══════════════════════════════════════════════════════════════════
  # check: true with classical mode
  # ══════════════════════════════════════════════════════════════════

  describe "check: true with classical mode" do
    test "does not double-pluralize classical plurals" do
      # Classical plurals are in the enriched reverse map, so they're
      # recognized as known plurals
      assert Plurality.pluralize("aquaria", check: true) == "aquaria"
      assert Plurality.pluralize("formulae", check: true) == "formulae"
      assert Plurality.pluralize("traumata", check: true) == "traumata"
    end

    test "does not double-pluralize modern plurals" do
      assert Plurality.pluralize("aquariums", check: true) == "aquariums"
      assert Plurality.pluralize("formulas", check: true) == "formulas"
    end
  end
end
