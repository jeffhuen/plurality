# Domain Customization

Plurality handles standard English well out of the box, but every domain has
words it can't predict: internal product names, technical jargon, borrowed
terms from other languages. `Plurality.Custom` lets you teach it your domain
without losing any built-in coverage.

## Creating a custom module

```elixir
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
```

This generates a module with the same API as `Plurality`:

```elixir
MyApp.Inflection.pluralize("regex")            #=> "regexen"
MyApp.Inflection.pluralize("kubernetes")       #=> "kubernetes"
MyApp.Inflection.pluralize("leaf")             #=> "leaves"  (falls through to defaults)
MyApp.Inflection.singularize("regexen")        #=> "regex"
MyApp.Inflection.plural?("kubernetes")         #=> true
MyApp.Inflection.singular?("kubernetes")       #=> true
```

## How resolution works

Your custom entries are checked first. If the word isn't found in your
custom data, it falls through to the built-in Plurality engine:

```
1. Custom uncountables (MapSet)  →  return unchanged
2. Custom irregulars (Map)       →  return mapped form
3. Built-in engine               →  full three-tier resolution
```

This means custom entries always take priority over built-in data.

## Options

### `:irregulars`

A list of `{singular, plural}` tuples. Each pair is stored in both a forward
map (singular -> plural) and a reverse map (plural -> singular).

```elixir
irregulars: [
  {"regex", "regexen"},        # regex → regexen, regexen → regex
  {"pokemon", "pokemon"},      # identity pair — unchanged in both directions
  {"octopus", "octopodes"}     # override built-in octopus → octopuses
]
```

Identity pairs (where singular equals plural) work correctly — the word is
returned unchanged in both directions, similar to uncountables but with
explicit `plural?/1` and `singular?/1` handling.

### `:uncountables`

A list of strings. These words are returned unchanged by both `pluralize/2`
and `singularize/1`, and return `true` for both `plural?/1` and `singular?/1`.

```elixir
uncountables: [
  "kubernetes",
  "graphql",
  "redis"
]
```

## Application integration

Call custom modules directly from the code that needs domain-specific rules:

```elixir
MyApp.Inflection.pluralize("regex")       #=> "regexen"
MyApp.Inflection.pluralize("leaf")        #=> "leaves"
```

If your application wants a single entry point, wrap the custom module in your
own application code:

```elixir
defmodule MyApp.Nouns do
  def pluralize(word, opts \\ []), do: MyApp.Inflection.pluralize(word, opts)
  def singularize(word), do: MyApp.Inflection.singularize(word)
end
```

Plurality itself avoids application configuration so different callers can make
different choices without shared global state.

## Classical mode with custom modules

Custom modules support the `classical: true` option. It passes through to
the engine for words that fall through your custom data:

```elixir
MyApp.Inflection.pluralize("aquarium", classical: true)  #=> "aquaria"
```

The `inflect/3` function also accepts options:

```elixir
MyApp.Inflection.inflect("aquarium", 2, classical: true)  #=> "aquaria"
```

## Generated functions

`use Plurality.Custom` generates these functions in your module:

| Function | Description |
|----------|-------------|
| `pluralize/2` | Pluralize with options (`check:`, `classical:`) |
| `singularize/1` | Singularize |
| `plural?/1` | Check if plural |
| `singular?/1` | Check if singular |
| `inflect/3` | Count-based inflection with options |

## Design rationale

Custom modules are called directly rather than being registered in a global
registry. This is intentional:

- **Explicit** — no hidden delegation or library-owned application config
- **Composable** — different parts of your app can use different custom modules
- **Zero overhead** — compiled into module bytecode, no ETS or runtime config reads
- **Compile-time verified** — typos in irregular pairs surface at build time
