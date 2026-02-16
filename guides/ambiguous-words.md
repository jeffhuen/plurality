# Ambiguous Words

English has words where the "correct" plural depends on context, dialect,
or domain. Plurality picks one default for each, but the right answer for
your application may differ. This guide documents known ambiguities and
shows how to override them with `Plurality.Custom`.

## penny / pence

`penny` has two valid plurals with different meanings:

- **pennies** — individual coins ("I found three pennies on the ground")
- **pence** — monetary amount ("That costs fifty pence")

Plurality defaults to `pennies` via suffix rules.

```elixir
# Override for British monetary usage
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [{"penny", "pence"}]
end
```

## staff

`staff` is treated as uncountable (collective noun: "the staff are..."),
which is the standard British English usage. If you need the countable
sense (multiple groups of employees, or walking staffs):

```elixir
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [{"staff", "staffs"}]
end
```

## opera / opus

`opera` is its own word (the musical art form), not just the plural of
`opus`. Plurality treats `opera` as a standalone base form. If your domain
treats it as the plural of `opus`:

```elixir
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [{"opus", "opera"}]
end
```

## trachea

Plurality defaults to the modern English plural `tracheas`. The classical
Latin form `tracheae` is used in medical contexts but is too niche for
the built-in default:

```elixir
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [{"trachea", "tracheae"}]
end
```

## kibbutz / kibbutzim

The Hebrew plural `kibbutzim` is standard in discussions of Israeli
settlements, but Plurality defaults to the anglicized form `kibbutzes`:

```elixir
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [{"kibbutz", "kibbutzim"}]
end
```

## Acronyms (API, CPU, URL)

`Plurality.pluralize("API")` returns `"APIS"` because the engine applies
ALL CAPS style preservation. There is no reliable way to distinguish
acronyms from regular words in ALL CAPS without a dictionary lookup, and
any heuristic would break normal ALL CAPS behavior (`LEAF` -> `LEAVES`,
`BOX` -> `BOXES`).

Override specific acronyms as needed:

```elixir
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [
      {"api", "apis"},
      {"cpu", "cpus"},
      {"url", "urls"},
      {"sdk", "sdks"}
    ]
end
```

## axe / axis

Both `axe` and `axis` pluralize to `axes`. Plurality treats `axis` as the
canonical singular because it is more common in technical and business
English. This means `singularize("axes")` returns `"axis"`, making the
`axe -> axes -> axis` path lossy.

If your domain works with axes (the tools):

```elixir
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [{"axe", "axes"}]
end
```

## Rare compound nouns

Common head-noun compounds like `mother-in-law`, `attorney general`, and
`court-martial` are handled in the built-in irregulars. Rarer ones are an
endless list — override as needed:

```elixir
defmodule MyApp.Inflection do
  use Plurality.Custom,
    irregulars: [
      {"lady-in-waiting", "ladies-in-waiting"},
      {"commander-in-chief", "commanders-in-chief"},
      {"man-of-war", "men-of-war"}
    ]
end
```

## App-wide overrides

If you want your overrides to apply everywhere (including third-party
libraries that call `Plurality` directly), set the custom module in your
application config:

```elixir
# config/config.exs
config :plurality, custom_module: MyApp.Inflection
```

See the [Customization guide](customization.md) for full details.
