defmodule PluralityTest do
  use ExUnit.Case
  doctest Plurality

  describe "pluralize/1" do
    test "regular nouns — append -s" do
      assert Plurality.pluralize("post") == "posts"
      assert Plurality.pluralize("cat") == "cats"
      assert Plurality.pluralize("dog") == "dogs"
      assert Plurality.pluralize("car") == "cars"
      assert Plurality.pluralize("book") == "books"
    end

    test "-ch/-sh — append -es" do
      assert Plurality.pluralize("church") == "churches"
      assert Plurality.pluralize("dish") == "dishes"
      assert Plurality.pluralize("watch") == "watches"
      assert Plurality.pluralize("brush") == "brushes"
      assert Plurality.pluralize("match") == "matches"
    end

    test "-x/-z — append -es" do
      assert Plurality.pluralize("box") == "boxes"
      assert Plurality.pluralize("tax") == "taxes"
      assert Plurality.pluralize("waltz") == "waltzes"
      assert Plurality.pluralize("buzz") == "buzzes"
    end

    test "-s/-ss — append -es" do
      assert Plurality.pluralize("bus") == "buses"
      assert Plurality.pluralize("class") == "classes"
      assert Plurality.pluralize("boss") == "bosses"
      assert Plurality.pluralize("access") == "accesses"
    end

    test "consonant+y → -ies" do
      assert Plurality.pluralize("category") == "categories"
      assert Plurality.pluralize("city") == "cities"
      assert Plurality.pluralize("body") == "bodies"
      assert Plurality.pluralize("story") == "stories"
      assert Plurality.pluralize("baby") == "babies"
    end

    test "vowel+y → -ys" do
      assert Plurality.pluralize("day") == "days"
      assert Plurality.pluralize("key") == "keys"
      assert Plurality.pluralize("toy") == "toys"
      assert Plurality.pluralize("boy") == "boys"
    end

    test "-fe → -ves" do
      assert Plurality.pluralize("knife") == "knives"
      assert Plurality.pluralize("life") == "lives"
      assert Plurality.pluralize("wife") == "wives"
    end

    test "-f → -ves (Old English)" do
      assert Plurality.pluralize("leaf") == "leaves"
      assert Plurality.pluralize("wolf") == "wolves"
      assert Plurality.pluralize("half") == "halves"
      assert Plurality.pluralize("calf") == "calves"
    end

    test "-f → -fs (exceptions)" do
      assert Plurality.pluralize("roof") == "roofs"
      assert Plurality.pluralize("chief") == "chiefs"
      assert Plurality.pluralize("belief") == "beliefs"
      assert Plurality.pluralize("cliff") == "cliffs"
      assert Plurality.pluralize("dwarf") == "dwarfs"
    end

    test "-sis → -ses" do
      assert Plurality.pluralize("analysis") == "analyses"
      assert Plurality.pluralize("thesis") == "theses"
      assert Plurality.pluralize("crisis") == "crises"
      assert Plurality.pluralize("diagnosis") == "diagnoses"
    end

    test "-man → -men (suffix rule)" do
      assert Plurality.pluralize("fireman") == "firemen"
      assert Plurality.pluralize("policeman") == "policemen"
      assert Plurality.pluralize("spokesman") == "spokesmen"
    end

    test "-o — defaults to -os (exceptions in irregulars)" do
      assert Plurality.pluralize("photo") == "photos"
      assert Plurality.pluralize("piano") == "pianos"
      assert Plurality.pluralize("memo") == "memos"
    end
  end

  describe "pluralize/2 with check: true" do
    test "returns already-plural words unchanged" do
      assert Plurality.pluralize("children", check: true) == "children"
      assert Plurality.pluralize("people", check: true) == "people"
      assert Plurality.pluralize("men", check: true) == "men"
      assert Plurality.pluralize("women", check: true) == "women"
      assert Plurality.pluralize("leaves", check: true) == "leaves"
    end

    test "pluralizes singular words normally" do
      assert Plurality.pluralize("child", check: true) == "children"
      assert Plurality.pluralize("leaf", check: true) == "leaves"
      assert Plurality.pluralize("post", check: true) == "posts"
    end

    test "uncountables return unchanged" do
      assert Plurality.pluralize("sheep", check: true) == "sheep"
      assert Plurality.pluralize("software", check: true) == "software"
    end
  end

  describe "irregulars" do
    test "common irregulars" do
      assert Plurality.pluralize("child") == "children"
      assert Plurality.pluralize("person") == "people"
      assert Plurality.pluralize("man") == "men"
      assert Plurality.pluralize("woman") == "women"
      assert Plurality.pluralize("mouse") == "mice"
      assert Plurality.pluralize("goose") == "geese"
      assert Plurality.pluralize("foot") == "feet"
      assert Plurality.pluralize("tooth") == "teeth"
      assert Plurality.pluralize("ox") == "oxen"
    end

    test "cross-ecosystem additions" do
      assert Plurality.pluralize("cargo") == "cargoes"
      assert Plurality.pluralize("virus") == "viruses"
      assert Plurality.pluralize("campus") == "campuses"
      assert Plurality.pluralize("census") == "censuses"
    end

    test "modern English overrides" do
      assert Plurality.pluralize("premium") == "premiums"
      assert Plurality.pluralize("persona") == "personas"
      assert Plurality.pluralize("vertex") == "vertices"
    end
  end

  describe "uncountables" do
    test "common uncountables return unchanged" do
      assert Plurality.pluralize("sheep") == "sheep"
      assert Plurality.pluralize("fish") == "fish"
      assert Plurality.pluralize("deer") == "deer"
      assert Plurality.pluralize("software") == "software"
      assert Plurality.pluralize("news") == "news"
      assert Plurality.pluralize("information") == "information"
    end

    test "cross-ecosystem uncountables" do
      assert Plurality.pluralize("merchandise") == "merchandise"
      assert Plurality.pluralize("middleware") == "middleware"
      assert Plurality.pluralize("freight") == "freight"
      assert Plurality.pluralize("throughput") == "throughput"
    end

    test "countable words not treated as uncountable" do
      assert Plurality.pluralize("access") == "accesses"
      assert Plurality.pluralize("status") == "statuses"
    end
  end

  describe "singularize/1" do
    test "regular -s → strip" do
      assert Plurality.singularize("posts") == "post"
      assert Plurality.singularize("cats") == "cat"
      assert Plurality.singularize("dogs") == "dog"
    end

    test "-ches/-shes → -ch/-sh" do
      assert Plurality.singularize("churches") == "church"
      assert Plurality.singularize("dishes") == "dish"
      assert Plurality.singularize("watches") == "watch"
    end

    test "-xes → -x" do
      assert Plurality.singularize("boxes") == "box"
      assert Plurality.singularize("taxes") == "tax"
    end

    test "-zes → -z or -ze" do
      assert Plurality.singularize("waltzes") == "waltz"
      assert Plurality.singularize("buzzes") == "buzz"
    end

    test "-sses → -ss" do
      assert Plurality.singularize("classes") == "class"
      assert Plurality.singularize("bosses") == "boss"
    end

    test "-ies → -y" do
      assert Plurality.singularize("categories") == "category"
      assert Plurality.singularize("cities") == "city"
      assert Plurality.singularize("stories") == "story"
    end

    test "-ives → -ife" do
      assert Plurality.singularize("knives") == "knife"
      assert Plurality.singularize("lives") == "life"
      assert Plurality.singularize("wives") == "wife"
    end

    test "-ves → -f" do
      assert Plurality.singularize("wolves") == "wolf"
      assert Plurality.singularize("halves") == "half"
      assert Plurality.singularize("calves") == "calf"
    end

    test "-ses → -sis (Latin)" do
      assert Plurality.singularize("analyses") == "analysis"
      assert Plurality.singularize("theses") == "thesis"
      assert Plurality.singularize("crises") == "crisis"
    end

    test "-men → -man" do
      assert Plurality.singularize("women") == "woman"
      assert Plurality.singularize("firemen") == "fireman"
      assert Plurality.singularize("policemen") == "policeman"
    end

    test "-oes → -o" do
      assert Plurality.singularize("heroes") == "hero"
      assert Plurality.singularize("potatoes") == "potato"
    end

    test "irregular reverse lookup" do
      assert Plurality.singularize("children") == "child"
      assert Plurality.singularize("people") == "person"
      assert Plurality.singularize("men") == "man"
      assert Plurality.singularize("mice") == "mouse"
      assert Plurality.singularize("geese") == "goose"
      assert Plurality.singularize("feet") == "foot"
      assert Plurality.singularize("teeth") == "tooth"
    end

    test "uncountables return unchanged" do
      assert Plurality.singularize("sheep") == "sheep"
      assert Plurality.singularize("software") == "software"
    end
  end

  describe "plural?/1" do
    test "identifies plural words" do
      assert Plurality.plural?("posts") == true
      assert Plurality.plural?("children") == true
      assert Plurality.plural?("leaves") == true
      assert Plurality.plural?("categories") == true
    end

    test "rejects singular words" do
      assert Plurality.plural?("post") == false
      assert Plurality.plural?("child") == false
      assert Plurality.plural?("leaf") == false
    end

    test "uncountables are both" do
      assert Plurality.plural?("sheep") == true
      assert Plurality.plural?("software") == true
    end
  end

  describe "singular?/1" do
    test "identifies singular words" do
      assert Plurality.singular?("post") == true
      assert Plurality.singular?("child") == true
      assert Plurality.singular?("leaf") == true
    end

    test "rejects plural words" do
      assert Plurality.singular?("posts") == false
      assert Plurality.singular?("children") == false
      assert Plurality.singular?("leaves") == false
    end

    test "uncountables are both" do
      assert Plurality.singular?("sheep") == true
      assert Plurality.singular?("software") == true
    end
  end

  describe "inflect/2" do
    test "count of 1 returns singular" do
      assert Plurality.inflect("leaf", 1) == "leaf"
      assert Plurality.inflect("child", 1) == "child"
    end

    test "count of 2+ returns plural" do
      assert Plurality.inflect("leaf", 2) == "leaves"
      assert Plurality.inflect("child", 5) == "children"
    end

    test "count of 0 returns plural" do
      assert Plurality.inflect("leaf", 0) == "leaves"
    end
  end

  describe "style preservation" do
    test "ALL CAPS" do
      assert Plurality.pluralize("LEAF") == "LEAVES"
      assert Plurality.pluralize("POST") == "POSTS"
      assert Plurality.pluralize("CHILD") == "CHILDREN"
    end

    test "Title Case" do
      assert Plurality.pluralize("Leaf") == "Leaves"
      assert Plurality.pluralize("Post") == "Posts"
      assert Plurality.pluralize("Child") == "Children"
    end

    test "lowercase passthrough" do
      assert Plurality.pluralize("leaf") == "leaves"
      assert Plurality.pluralize("post") == "posts"
    end
  end

  describe "Plurality.Custom" do
    defmodule TestCustom do
      use Plurality.Custom,
        irregulars: [
          {"regex", "regexen"},
          {"pokemon", "pokemon"}
        ],
        uncountables: [
          "kubernetes",
          "graphql"
        ]
    end

    test "custom irregulars" do
      assert TestCustom.pluralize("regex") == "regexen"
      assert TestCustom.singularize("regexen") == "regex"
    end

    test "custom identity irregulars" do
      assert TestCustom.pluralize("pokemon") == "pokemon"
    end

    test "custom uncountables" do
      assert TestCustom.pluralize("kubernetes") == "kubernetes"
      assert TestCustom.pluralize("graphql") == "graphql"
    end

    test "falls through to defaults" do
      assert TestCustom.pluralize("leaf") == "leaves"
      assert TestCustom.singularize("leaves") == "leaf"
    end

    test "detection with custom words" do
      assert TestCustom.plural?("regexen") == true
      assert TestCustom.singular?("regex") == true
      assert TestCustom.plural?("kubernetes") == true
      assert TestCustom.singular?("kubernetes") == true
    end
  end

  # ── Compound nouns ──────────────────────────────────────────────

  describe "compound nouns — pluralize" do
    test "splits on last space and inflects last word" do
      assert Plurality.pluralize("status code") == "status codes"
      assert Plurality.pluralize("ice cream") == "ice creams"
      assert Plurality.pluralize("fire truck") == "fire trucks"
    end

    test "multi-word compounds split on last space" do
      assert Plurality.pluralize("post office box") == "post office boxes"
      assert Plurality.pluralize("red fire truck") == "red fire trucks"
    end

    test "compound with irregular last word" do
      assert Plurality.pluralize("field mouse") == "field mice"
      assert Plurality.pluralize("back tooth") == "back teeth"
      assert Plurality.pluralize("step child") == "step children"
    end

    test "compound with uncountable last word" do
      assert Plurality.pluralize("network software") == "network software"
      assert Plurality.pluralize("live fish") == "live fish"
    end

    test "known multi-word irregulars take priority over splitting" do
      assert Plurality.pluralize("head of state") == "heads of states"
      assert Plurality.pluralize("son of a bitch") == "sons of bitches"
      assert Plurality.pluralize("coup d'etat") == "coups d'etat"
    end

    test "case preservation in compounds" do
      assert Plurality.pluralize("Status Code") == "Status Codes"
      assert Plurality.pluralize("STATUS CODE") == "STATUS CODES"
      assert Plurality.pluralize("Ice Cream") == "Ice Creams"
    end

    test "check: true with compound nouns" do
      assert Plurality.pluralize("status codes", check: true) == "status codes"
      assert Plurality.pluralize("status code", check: true) == "status codes"
    end
  end

  describe "compound nouns — singularize" do
    test "splits on last space and singularizes last word" do
      assert Plurality.singularize("status codes") == "status code"
      assert Plurality.singularize("ice creams") == "ice cream"
      assert Plurality.singularize("fire trucks") == "fire truck"
    end

    test "multi-word compounds" do
      assert Plurality.singularize("post office boxes") == "post office box"
    end

    test "compound with irregular last word" do
      assert Plurality.singularize("field mice") == "field mouse"
      assert Plurality.singularize("back teeth") == "back tooth"
      assert Plurality.singularize("step children") == "step child"
    end

    test "compound with uncountable last word" do
      assert Plurality.singularize("network software") == "network software"
    end

    test "known multi-word irregulars take priority over splitting" do
      assert Plurality.singularize("ships of the line") == "ship of the line"
      assert Plurality.singularize("coups d'etat") == "coup d'etat"
    end

    test "case preservation in compounds" do
      assert Plurality.singularize("Status Codes") == "Status Code"
      assert Plurality.singularize("STATUS CODES") == "STATUS CODE"
    end
  end

  describe "compound nouns — detection" do
    test "plural? with compounds" do
      assert Plurality.plural?("status codes") == true
      assert Plurality.plural?("field mice") == true
    end

    test "singular? with compounds" do
      assert Plurality.singular?("status code") == true
      assert Plurality.singular?("field mouse") == true
    end

    test "detection with uncountable last word" do
      assert Plurality.plural?("network software") == true
      assert Plurality.singular?("network software") == true
    end
  end

  describe "compound nouns — inflect" do
    test "inflect with count" do
      assert Plurality.inflect("status code", 1) == "status code"
      assert Plurality.inflect("status code", 2) == "status codes"
      assert Plurality.inflect("status code", 0) == "status codes"
    end
  end
end
