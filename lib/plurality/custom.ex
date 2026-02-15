defmodule Plurality.Custom do
  @moduledoc """
  Compile-time overrides for domain-specific inflection.

  Use this module to create a custom inflection module that adds your own
  irregulars and uncountables on top of Plurality's built-in data. Custom
  entries are checked first and take priority; unknown words fall through
  to the default `Plurality` module.

  ## Usage

      defmodule MyApp.Inflection do
        use Plurality.Custom,
          irregulars: [
            {"regex", "regexen"},
            {"pokemon", "pokemon"},
            {"elasticsearch", "elasticsearch"}
          ],
          uncountables: [
            "kubernetes",
            "graphql",
            "redis"
          ]
      end

  Then call your module directly:

      MyApp.Inflection.pluralize("regex")            #=> "regexen"
      MyApp.Inflection.pluralize("kubernetes")       #=> "kubernetes"
      MyApp.Inflection.pluralize("leaf")             #=> "leaves"
      MyApp.Inflection.singularize("regexen")        #=> "regex"
      MyApp.Inflection.plural?("kubernetes")         #=> true
      MyApp.Inflection.singular?("kubernetes")       #=> true

  ## How it works

  `use Plurality.Custom` generates five functions in your module at compile
  time:

  * `pluralize/2` — checks custom uncountables, then custom irregulars, then
    delegates to `Plurality.pluralize/2`
  * `singularize/1` — checks custom uncountables, then custom reverse
    irregulars, then delegates to `Plurality.singularize/1`
  * `plural?/1` — checks custom data, then delegates to `Plurality.plural?/1`
  * `singular?/1` — checks custom data, then delegates to `Plurality.singular?/1`
  * `inflect/2` — count-based delegation to `singularize/1` or `pluralize/1`

  Custom irregulars and uncountables are stored as module attributes
  (`@custom_irregulars_s2p`, `@custom_irregulars_p2s`, `@custom_uncountables`)
  and compiled into the module's bytecode. There is no runtime overhead
  beyond a `Map`/`MapSet` lookup.

  ## Options

    * `:irregulars` — a list of `{singular, plural}` tuples. Each pair is
      stored in both a forward map (singular → plural) and a reverse map
      (plural → singular). Identity pairs like `{"pokemon", "pokemon"}` work
      correctly — the word is returned unchanged in both directions.

    * `:uncountables` — a list of strings. These words are returned unchanged
      by both `pluralize/2` and `singularize/1`, and return `true` for both
      `plural?/1` and `singular?/1`.

  ## Design rationale

  Custom modules are called directly rather than being registered globally.
  This is intentional:

  * **Explicit** — no hidden app-wide config or implicit delegation
  * **Composable** — different parts of your app can use different custom
    modules
  * **Zero overhead** — no ETS lookups or runtime configuration reads
  * **Compile-time verified** — typos in irregular pairs are caught at
    compile time, not at runtime
  """

  @typedoc """
  A singular/plural pair for custom irregular words.

  The first element is the singular form, the second is the plural form.
  Identity pairs (where both are the same) are valid and indicate that
  the word should be returned unchanged in both directions.
  """
  @type irregular_pair :: {singular :: String.t(), plural :: String.t()}

  @typedoc """
  Options accepted by `use Plurality.Custom`.

    * `:irregulars` — list of `t:irregular_pair/0`
    * `:uncountables` — list of `t:String.t/0`
  """
  @type custom_opts :: [
          irregulars: [irregular_pair()],
          uncountables: [String.t()]
        ]

  @doc false
  defmacro __using__(opts) do
    irregulars = Keyword.get(opts, :irregulars, [])
    uncountables = Keyword.get(opts, :uncountables, [])

    quote do
      @custom_irregulars_s2p Map.new(unquote(irregulars))
      @custom_irregulars_p2s Map.new(unquote(irregulars), fn {s, p} -> {p, s} end)
      @custom_uncountables MapSet.new(unquote(uncountables))

      @doc """
      Converts a word to its plural form, checking custom overrides first.

      Custom uncountables are checked first, then custom irregulars, then
      the word is delegated to `Plurality.pluralize/2`.

      Accepts the same options as `Plurality.pluralize/2`.
      """
      @spec pluralize(String.t(), Plurality.pluralize_opts()) :: String.t()
      def pluralize(word, opts \\ []) do
        downcased = String.downcase(word)

        cond do
          MapSet.member?(@custom_uncountables, downcased) ->
            word

          Map.has_key?(@custom_irregulars_s2p, downcased) ->
            Plurality.Style.match_style(word, @custom_irregulars_s2p[downcased])

          true ->
            Plurality.Engine.pluralize(word, opts)
        end
      end

      @doc """
      Converts a word to its singular form, checking custom overrides first.

      Custom uncountables are checked first, then the reverse irregulars map,
      then the word is delegated to `Plurality.Engine.singularize/1`.
      """
      @spec singularize(String.t()) :: String.t()
      def singularize(word) do
        downcased = String.downcase(word)

        cond do
          MapSet.member?(@custom_uncountables, downcased) ->
            word

          Map.has_key?(@custom_irregulars_p2s, downcased) ->
            Plurality.Style.match_style(word, @custom_irregulars_p2s[downcased])

          true ->
            Plurality.Engine.singularize(word)
        end
      end

      @doc """
      Returns `true` if the word is in plural form, checking custom data first.

      Custom uncountables return `true`. Custom irregular plurals return `true`.
      Custom irregular singulars return `false`. Otherwise delegates to
      `Plurality.Engine.plural?/1`.
      """
      @spec plural?(String.t()) :: boolean()
      def plural?(word) do
        downcased = String.downcase(word)

        cond do
          MapSet.member?(@custom_uncountables, downcased) -> true
          Map.has_key?(@custom_irregulars_p2s, downcased) -> true
          Map.has_key?(@custom_irregulars_s2p, downcased) -> false
          true -> Plurality.Engine.plural?(word)
        end
      end

      @doc """
      Returns `true` if the word is in singular form, checking custom data first.

      Custom uncountables return `true`. Custom irregular singulars return `true`.
      Custom irregular plurals return `false`. Otherwise delegates to
      `Plurality.Engine.singular?/1`.
      """
      @spec singular?(String.t()) :: boolean()
      def singular?(word) do
        downcased = String.downcase(word)

        cond do
          MapSet.member?(@custom_uncountables, downcased) -> true
          Map.has_key?(@custom_irregulars_s2p, downcased) -> true
          Map.has_key?(@custom_irregulars_p2s, downcased) -> false
          true -> Plurality.Engine.singular?(word)
        end
      end

      @doc """
      Inflects a word based on count, using custom overrides.

      Returns singular for count of `1`, plural for all other values.
      Accepts the same options as `pluralize/2`.
      """
      @spec inflect(String.t(), integer(), Plurality.pluralize_opts()) :: String.t()
      def inflect(word, count, opts \\ [])
      def inflect(word, 1, _opts), do: singularize(word)
      def inflect(word, _count, opts), do: pluralize(word, opts)
    end
  end
end
