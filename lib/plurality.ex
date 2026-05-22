defmodule Plurality do
  @moduledoc """
  Fast, zero-regex English noun inflection for Elixir.

  Operates on English nouns only. Other parts of speech (pronouns, adjectives,
  adverbs, etc.) are not supported and will produce undefined results.

  Plurality provides 99%+ accuracy on business and technical English,
  using compile-time binary pattern matching instead of runtime regex.

  ## Quick start

      Plurality.pluralize("leaf")                    #=> "leaves"
      Plurality.singularize("leaves")                #=> "leaf"
      Plurality.plural?("leaves")                    #=> true
      Plurality.singular?("leaf")                    #=> true
      Plurality.inflect("leaf", 2)                   #=> "leaves"
      Plurality.inflect("leaf", 1)                   #=> "leaf"

  ## Safe pluralization

  Pass `check: true` to avoid double-pluralizing words that are already plural.

      Plurality.pluralize("children", check: true)   #=> "children"
      Plurality.pluralize("people", check: true)     #=> "people"
      Plurality.pluralize("leaf", check: true)       #=> "leaves"

  ## Case preservation

  Input casing is detected and applied to the output automatically.
  Three styles are recognized: ALL CAPS, Title Case, and lowercase.

      Plurality.pluralize("LEAF")                    #=> "LEAVES"
      Plurality.pluralize("Leaf")                    #=> "Leaves"
      Plurality.singularize("WOMEN")                 #=> "WOMAN"
      Plurality.singularize("Children")              #=> "Child"

  ## Uncountable words

  Words like "sheep", "software", and "news" are returned unchanged by both
  `pluralize/2` and `singularize/1`. Detection functions `plural?/1` and
  `singular?/1` return `true` for uncountables since they are valid in either
  context.

      Plurality.pluralize("sheep")                   #=> "sheep"
      Plurality.singularize("sheep")                 #=> "sheep"
      Plurality.plural?("sheep")                     #=> true
      Plurality.singular?("sheep")                   #=> true

  ## Compound nouns

  Multi-word nouns are split on the last space and the final word is inflected.
  Known multi-word irregulars in the data (e.g., `"coup d'etat"`) take priority
  over splitting.

      Plurality.pluralize("status code")             #=> "status codes"
      Plurality.pluralize("field mouse")             #=> "field mice"
      Plurality.singularize("ice creams")            #=> "ice cream"

  ## Domain customization

  Use `Plurality.Custom` to define a module with your own irregulars and
  uncountables. Overrides compile into function heads that take priority
  over the built-in data.

      defmodule MyApp.Inflection do
        use Plurality.Custom,
          irregulars: [{"regex", "regexen"}],
          uncountables: ["kubernetes"]
      end

      MyApp.Inflection.pluralize("regex")            #=> "regexen"
      MyApp.Inflection.pluralize("kubernetes")       #=> "kubernetes"
      MyApp.Inflection.pluralize("leaf")             #=> "leaves"

  See `Plurality.Custom` for full documentation.

  ## Classical mode

  Pass `classical: true` to get Latin/Greek plural forms instead of modern
  English forms. Default behavior is unchanged — classical mode is opt-in.

      Plurality.pluralize("aquarium")                  #=> "aquariums"
      Plurality.pluralize("aquarium", classical: true) #=> "aquaria"
      Plurality.pluralize("trauma", classical: true)   #=> "traumata"
      Plurality.pluralize("formula", classical: true)  #=> "formulae"

  Singularization handles both forms automatically, no option needed:

      Plurality.singularize("aquariums")  #=> "aquarium"
      Plurality.singularize("aquaria")    #=> "aquarium"

  ## Explicit configuration

  Plurality does not read application configuration. Pass options at the call
  site and call custom inflection modules directly:

      Plurality.pluralize("aquarium", classical: true) #=> "aquaria"
      MyApp.Inflection.pluralize("regex")              #=> "regexen"

  This keeps library behavior local to each caller and avoids global state.

  ## Ash integration

  If your project uses Ash, Plurality ships optional changes, validations,
  and calculations that compile away to nothing if Ash is not loaded. See:

  * `Plurality.Ash.Changes.Pluralize`
  * `Plurality.Ash.Changes.Singularize`
  * `Plurality.Ash.Validations.PluralForm`
  * `Plurality.Ash.Validations.SingularForm`
  * `Plurality.Ash.Calculations.Pluralize`
  * `Plurality.Ash.Calculations.Singularize`

  ## Architecture

  Plurality uses a three-tier resolution engine (originated by Conway's 1998
  paper, same architecture as Rails and pluralize.js):

  1. **Uncountables** (`MapSet`, O(1)) — word returned unchanged
  2. **Irregulars** (`Map`, O(1)) — direct lookup from merged cross-ecosystem data
  3. **Suffix rules** (last-byte dispatch) — BEAM `select_val` jump table, zero regex

  All data is compiled into module attributes at build time from TSV/TXT files
  in `priv/`. There is zero runtime file I/O and zero regex execution.

  ## Data

  Plurality ships with ~1,110 irregular pairs, ~1,022 uncountable words, and
  108 suffix rules — curated from multiple sources across the Elixir, Ruby,
  JavaScript, Go, C#, and Rust ecosystems, then verified against Oxford and
  Merriam-Webster dictionaries. All data is loaded at compile time from
  `priv/data/`.

  """

  @typedoc """
  Options for `pluralize/2` and `inflect/3`.

  * `:check` — when `true`, tests whether the word is already in plural form
    before transforming it. If the word is already plural, it is returned
    unchanged. This prevents double-pluralization errors like
    `"children"` → `"childrens"`. Defaults to `false`.

  * `:classical` — when `true`, uses classical Latin/Greek plural forms
    instead of modern English forms (e.g., `"aquarium"` → `"aquaria"`
    instead of `"aquariums"`). Defaults to `false`.
  """
  @type pluralize_opts :: [check: boolean(), classical: boolean()]

  @doc """
  Converts an English noun to its plural form.

  Returns the word unchanged if it is uncountable (e.g., `"sheep"`, `"software"`).
  Preserves the casing style of the input (ALL CAPS, Title Case, or lowercase).

  For custom domain rules, define a `Plurality.Custom` module and call it
  directly.

  ## Options

    * `:check` (`boolean()`) - When `true`, checks whether the word is already
      plural and returns it unchanged if so. Prevents double-pluralization
      (e.g., `"children"` staying `"children"` instead of becoming
      `"childrens"`). Defaults to `false`.

    * `:classical` (`boolean()`) - When `true`, uses classical Latin/Greek
      plural forms instead of modern English forms. Defaults to `false`.

  ## Resolution order

  1. Uncountable? → return unchanged
  2. `check: true` and already a known irregular plural? → return unchanged
  3. `classical: true` and word has a known classical form? → return classical plural
  4. Known irregular singular? → return the mapped plural
  5. `check: true` and rule-based detection says plural? → return unchanged
  6. Compound noun? → split on last space, inflect last word
  7. Apply suffix rules (last-byte dispatch, classical-aware)

  ## Examples

      iex> Plurality.pluralize("leaf")
      "leaves"

      iex> Plurality.pluralize("child")
      "children"

      iex> Plurality.pluralize("sheep")
      "sheep"

      iex> Plurality.pluralize("schema")
      "schemas"

      iex> Plurality.pluralize("children", check: true)
      "children"

      iex> Plurality.pluralize("LEAF")
      "LEAVES"

      iex> Plurality.pluralize("Leaf")
      "Leaves"

      iex> Plurality.pluralize("status code")
      "status codes"

      iex> Plurality.pluralize("")
      ""

  ### Classical mode

      iex> Plurality.pluralize("aquarium", classical: true)
      "aquaria"

      iex> Plurality.pluralize("formula", classical: true)
      "formulae"

      iex> Plurality.pluralize("trauma", classical: true)
      "traumata"

      iex> Plurality.pluralize("cactus")
      "cactuses"

      iex> Plurality.pluralize("leaf", classical: true)
      "leaves"
  """
  @spec pluralize(word :: String.t(), opts :: pluralize_opts()) :: String.t()
  def pluralize(word, opts \\ []) do
    Plurality.Engine.pluralize(word, opts)
  end

  @doc """
  Converts an English noun from plural to singular form.

  Returns the word unchanged if it is uncountable. Preserves casing style.

  For custom domain rules, define a `Plurality.Custom` module and call it
  directly.

  For words that appear in both the uncountables set and the irregular plurals
  map (e.g., `"data"`, `"graffiti"`), the irregular reverse lookup takes
  priority so that singularization resolves correctly:

      Plurality.singularize("data")      #=> "datum"
      Plurality.singularize("graffiti")  #=> "graffito"

  Singularization is mode-independent — it handles both modern and classical
  plural forms without needing a `classical:` option:

      Plurality.singularize("aquariums")  #=> "aquarium"
      Plurality.singularize("aquaria")    #=> "aquarium"

  ## Resolution order

  1. Known irregular plural (including classical forms)? → return the mapped singular
  2. Uncountable? → return unchanged
  3. Compound noun? → split on last space, singularize last word
  4. Apply suffix rules (last-byte dispatch)

  ## Examples

      iex> Plurality.singularize("leaves")
      "leaf"

      iex> Plurality.singularize("children")
      "child"

      iex> Plurality.singularize("sheep")
      "sheep"

      iex> Plurality.singularize("taxes")
      "tax"

      iex> Plurality.singularize("statuses")
      "status"

      iex> Plurality.singularize("WOMEN")
      "WOMAN"

      iex> Plurality.singularize("status codes")
      "status code"

      iex> Plurality.singularize("")
      ""

  ### Classical plural forms

      iex> Plurality.singularize("aquaria")
      "aquarium"

      iex> Plurality.singularize("antennae")
      "antenna"

      iex> Plurality.singularize("traumata")
      "trauma"
  """
  @spec singularize(word :: String.t()) :: String.t()
  def singularize(word) do
    Plurality.Engine.singularize(word)
  end

  @doc """
  Returns `true` if the word is in plural form (or is uncountable).

  Uncountable words like `"sheep"` and `"software"` return `true` for both
  `plural?/1` and `singular?/1`, since they are valid in either context.

  For custom domain rules, define a `Plurality.Custom` module and call it
  directly.

  ## Detection strategy

  Detection is derived from transformation (inspired by
  [pluralize.js](https://github.com/plurals/pluralize)):

  1. Uncountable? → `true`
  2. Known irregular plural (in the plural→singular map)? → `true`
  3. Try `singularize/1` — if it produces a different word, and
     `pluralize/1` on that result gives back the original, then `true`

  ## Examples

      iex> Plurality.plural?("leaves")
      true

      iex> Plurality.plural?("children")
      true

      iex> Plurality.plural?("leaf")
      false

      iex> Plurality.plural?("sheep")
      true

      iex> Plurality.plural?("")
      false
  """
  @spec plural?(word :: String.t()) :: boolean()
  def plural?(word) do
    Plurality.Engine.plural?(word)
  end

  @doc """
  Returns `true` if the word is in singular form (or is uncountable).

  Uncountable words return `true` for both `plural?/1` and `singular?/1`.

  For custom domain rules, define a `Plurality.Custom` module and call it
  directly.

  ## Detection strategy

  1. Uncountable? → `true`
  2. Known irregular singular (in the singular→plural map)? → `true`
  3. Known irregular plural (in the plural→singular map)? → `false`
  4. Otherwise, check whether the word appears to already be plural
     via rule-based round-tripping

  ## Examples

      iex> Plurality.singular?("leaf")
      true

      iex> Plurality.singular?("child")
      true

      iex> Plurality.singular?("leaves")
      false

      iex> Plurality.singular?("sheep")
      true

      iex> Plurality.singular?("")
      false
  """
  @spec singular?(word :: String.t()) :: boolean()
  def singular?(word) do
    Plurality.Engine.singular?(word)
  end

  @doc """
  Inflects a word based on a numeric count.

  Returns the singular form when `count` is exactly `1`, and the plural form
  for all other values (including `0`, negative numbers, and numbers greater
  than `1`).

  For custom domain rules, define a `Plurality.Custom` module and call it
  directly.

  This follows standard English convention where zero and plural counts
  use the plural form: "0 items", "2 items", but "1 item".

  ## Options

  Accepts the same options as `pluralize/2` (`:check`, `:classical`).
  Options are passed through to `pluralize/2` when the count is not `1`.

  ## Examples

      iex> Plurality.inflect("leaf", 1)
      "leaf"

      iex> Plurality.inflect("leaf", 2)
      "leaves"

      iex> Plurality.inflect("leaf", 0)
      "leaves"

      iex> Plurality.inflect("child", 1)
      "child"

      iex> Plurality.inflect("child", 3)
      "children"

      iex> Plurality.inflect("sheep", 1)
      "sheep"

      iex> Plurality.inflect("sheep", 100)
      "sheep"

      iex> Plurality.inflect("aquarium", 2, classical: true)
      "aquaria"

      iex> Plurality.inflect("aquarium", 1, classical: true)
      "aquarium"
  """
  @spec inflect(word :: String.t(), count :: integer(), opts :: pluralize_opts()) :: String.t()
  def inflect(word, count, opts \\ []) do
    Plurality.Engine.inflect(word, count, opts)
  end
end
