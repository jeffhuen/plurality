# Classical Mode

English borrowed thousands of nouns from Latin and Greek, and for many of
them two plural forms coexist: a modern English form and the original
classical form. Plurality defaults to modern English but gives you a clean
toggle for classical forms.

## Quick start

```elixir
# Modern defaults (no change needed)
Plurality.pluralize("aquarium")                  #=> "aquariums"
Plurality.pluralize("formula")                   #=> "formulas"
Plurality.pluralize("trauma")                    #=> "traumas"

# Classical mode
Plurality.pluralize("aquarium", classical: true)  #=> "aquaria"
Plurality.pluralize("formula", classical: true)   #=> "formulae"
Plurality.pluralize("trauma", classical: true)    #=> "traumata"

# Words already classical by default are unaffected
Plurality.pluralize("cactus")                     #=> "cacti"
Plurality.pluralize("cactus", classical: true)    #=> "cacti"

# Words without classical forms are unaffected
Plurality.pluralize("leaf", classical: true)      #=> "leaves"
```

## What classical mode changes

Classical mode only affects words that have known Latin/Greek plural forms.
Everything else stays the same. There are two levels:

### 1. Overrides table (69 curated words)

Words where the default is modern but a classical alternative exists. These
are stored in `priv/data/classical_overrides.tsv` and curated from the NIH
SPECIALIST Lexicon.

Examples:

| Singular | Modern (default) | Classical |
|----------|-----------------|-----------|
| antenna | antennas | antennae |
| aquarium | aquariums | aquaria |
| formula | formulas | formulae |
| schema | schemas | schemata |
| stadium | stadiums | stadia |
| trauma | traumas | traumata |
| corpus | corpuses | corpora |
| apex | apexes | apices |
| focus | focuses | foci |
| medium | mediums | media |

### 2. Suffix rules (for words not in any table)

When `classical: true` and a word isn't found in the irregulars or overrides
tables, Latin/Greek suffix rules apply:

| Pattern | Example | Declension |
|---------|---------|------------|
| `-us` -> `-i` | fungus -> fungi | Latin 2nd masculine |
| `-um` -> `-a` | symposium -> symposia | Latin 2nd neuter |
| `-ix`/`-ex` -> `-ices` | appendix -> appendices | Latin 3rd |
| `-itis` -> `-itides` | arthritis -> arthritides | Greek medical |

## What classical mode does NOT do

Some Latin/Greek patterns have high false positive rates in English.
These are **never** applied as suffix rules, even with `classical: true`:

| Pattern | Would break | Handled via |
|---------|-------------|-------------|
| `-a` -> `-ae` | sofa, pizza, banana | Overrides table only |
| `-on` -> `-a` | button, person, melon | Overrides table only |

If a word ending in `-a` or `-on` isn't in the overrides table, it gets
normal English pluralization regardless of the classical flag.

## Singularization

Singularization is mode-independent. It handles both modern and classical
plural forms without needing a flag:

```elixir
Plurality.singularize("aquariums")  #=> "aquarium"
Plurality.singularize("aquaria")    #=> "aquarium"
Plurality.singularize("traumas")    #=> "trauma"
Plurality.singularize("traumata")   #=> "trauma"
Plurality.singularize("antennae")   #=> "antenna"
Plurality.singularize("antennas")   #=> "antenna"
```

This works because the reverse lookup map is enriched at compile time with
both modern and classical plural forms pointing to the same singular.

## App-wide config

Enable classical mode globally so all calls use it by default:

```elixir
# config/config.exs
config :plurality, classical: true
```

Per-call options always override the app-wide setting:

```elixir
# With classical: true in config...
Plurality.pluralize("aquarium")                   #=> "aquaria"    (from config)
Plurality.pluralize("aquarium", classical: false)  #=> "aquariums"  (per-call override)
```

## With inflect/3

The `inflect/3` function passes options through to `pluralize/2`:

```elixir
Plurality.inflect("aquarium", 2, classical: true)   #=> "aquaria"
Plurality.inflect("aquarium", 1, classical: true)   #=> "aquarium"
Plurality.inflect("formula", 0, classical: true)    #=> "formulae"
```

## With check mode

Classical plurals are recognized by `check: true`:

```elixir
Plurality.pluralize("aquaria", check: true)    #=> "aquaria"   (recognized as plural)
Plurality.pluralize("formulae", check: true)   #=> "formulae"  (recognized as plural)
```

## Case preservation

Classical mode preserves input casing:

```elixir
Plurality.pluralize("Aquarium", classical: true)  #=> "Aquaria"
Plurality.pluralize("FORMULA", classical: true)   #=> "FORMULAE"
Plurality.singularize("ANTENNAE")                 #=> "ANTENNA"
```

## Which words are classical by default?

Some classical forms are so dominant in English that they're the default
even without `classical: true`:

| Word | Default plural | Why |
|------|---------------|-----|
| cactus | cacti | "Cactuses" is rare |
| datum | data | Universal |
| criterion | criteria | Universal |
| phenomenon | phenomena | Universal |
| alumnus | alumni | Universal |
| thesis | theses | Universal |
| analysis | analyses | Universal |

These are in `irregulars.tsv` with classical plurals as the default. They
are NOT in `classical_overrides.tsv` because no override is needed.

## Further reading

See the [Methodology guide](methodology.md) for detailed documentation of
how modern vs. classical decisions were made, the data sources used, and
why certain suffix rules are restricted.
