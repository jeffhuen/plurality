# Plurality

Fast, zero-regex English noun inflection for Elixir. Pluralize, singularize, and detect noun forms with compile-time data and last-byte dispatch. Operates on nouns only; other parts of speech are not supported.

## Installation

Add `plurality` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:plurality, "~> 0.2.2"}
  ]
end
```

## Usage

```elixir
Plurality.pluralize("leaf")                    # => "leaves"
Plurality.singularize("leaves")                # => "leaf"
Plurality.plural?("leaves")                    # => true
Plurality.singular?("leaf")                    # => true
Plurality.inflect("leaf", 2)                   # => "leaves"
Plurality.inflect("leaf", 1)                   # => "leaf"
```

### Safe pluralization

```elixir
Plurality.pluralize("children", check: true)   # => "children" (not "childrens")
```

### Case preservation

```elixir
Plurality.pluralize("LEAF")                    # => "LEAVES"
Plurality.pluralize("Leaf")                    # => "Leaves"
Plurality.singularize("WOMEN")                 # => "WOMAN"
```

### Compound nouns

```elixir
Plurality.pluralize("status code")             # => "status codes"
Plurality.pluralize("field mouse")             # => "field mice"
Plurality.singularize("ice creams")            # => "ice cream"
```

### Classical mode

Pass `classical: true` to get Latin/Greek plural forms instead of modern English:

```elixir
Plurality.pluralize("aquarium")                  # => "aquariums"  (modern default)
Plurality.pluralize("aquarium", classical: true)  # => "aquaria"    (classical)
Plurality.pluralize("formula", classical: true)   # => "formulae"
Plurality.pluralize("trauma", classical: true)    # => "traumata"
```

Singularization handles both forms automatically, no flag needed:

```elixir
Plurality.singularize("aquariums")  # => "aquarium"
Plurality.singularize("aquaria")    # => "aquarium"
```

See the [Classical Mode guide](guides/classical-mode.md) for full details on
which forms are affected, app-wide config, and how default decisions were made.

### Domain customization

Override built-in data with your own irregulars and uncountables:

```elixir
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [{"regex", "regexen"}],
    uncountables: ["kubernetes"]
end

MyApp.Inflection.pluralize("regex")       # => "regexen"
MyApp.Inflection.pluralize("kubernetes")  # => "kubernetes"
MyApp.Inflection.pluralize("leaf")        # => "leaves"  (falls through)
```

Or delegate globally so all `Plurality.*` calls use your overrides:

```elixir
config :plurality, custom_module: MyApp.Inflection
```

See the [Customization guide](guides/customization.md) for full documentation.

### Ash integration

Optional changes, validations, and calculations for Ash applications.
Compiles away to nothing if Ash isn't loaded.

```elixir
change {Plurality.Ash.Changes.Pluralize, attribute: :table_name, from: :name}
validate {Plurality.Ash.Validations.PluralForm, attribute: :table_name}
calculate :name_plural, :string, {Plurality.Ash.Calculations.Pluralize, attribute: :name}
```

See the [Ash Integration guide](guides/ash-integration.md) for full documentation.

## Why Plurality?

Every inflection library gets the easy words right. The difference shows on the
long tail — medical terms, Latin borrowings, irregular compounds, and
uncountable nouns that hand-rolled inflection or simpler libraries silently
mangle.

Plurality exists to close that gap. It is verified against two independent
linguistic corpora — **80,191 noun pairs** tested in both directions — so
words like "fulfilment", "chassis", "criteria", "schema", and "merchandise"
just work. No fallback hacks, no silent failures.

- **100% accuracy** on AGID (32,625 pairs) and NIH SPECIALIST Lexicon (47,566 pairs)
- **~6M ops/sec** single word, ~4.3M words/sec batch — zero regex, all compile-time data
- **Two modes** — modern English by default, `classical: true` for Latin/Greek forms
- **2,400+ tests** (including doctests) covering corpus validation, classical mode, business domain, compounds, and edge cases

See [Methodology](guides/methodology.md) for data sources, design decisions,
and corpus compliance. See [Performance](guides/performance.md) for benchmarks.

## API

| Function | Description |
|----------|-------------|
| `pluralize/2` | Plural form, options: `check:`, `classical:` |
| `singularize/1` | Singular form |
| `plural?/1` | Check if plural |
| `singular?/1` | Check if singular |
| `inflect/3` | Count-based inflection with options |

## Guides

- [Classical Mode](guides/classical-mode.md) -- Latin/Greek plural forms
- [Customization](guides/customization.md) -- domain-specific overrides
- [Ash Integration](guides/ash-integration.md) -- changes, validations, calculations
- [Ambiguous Words](guides/ambiguous-words.md) -- known ambiguities and how to override them
- [Methodology](guides/methodology.md) -- data sources, design decisions, corpus compliance

## Acknowledgements

- [Exflect](https://hex.pm/packages/exflect) by Tyler Wray
- [Inflex](https://hex.pm/packages/inflex) by Miguel Palhas
- [pluralize](https://github.com/plurals/pluralize) by Blake Embrey
- [Rails ActiveSupport::Inflector](https://api.rubyonrails.org/classes/ActiveSupport/Inflector.html)
- Damian Conway's 1998 paper [*An Algorithmic Approach to English Pluralization*](https://users.monash.edu/~damian/papers/extabs/Plurals.html)

## License

MIT -- see `LICENSE` file.
