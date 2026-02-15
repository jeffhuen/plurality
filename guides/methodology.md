# Methodology: How Plurality Handles English Noun Inflection

This guide documents the design decisions, data sources, and trade-offs behind
Plurality's inflection engine. It explains how we handle the tension between
modern English and classical Latin/Greek forms, how we achieved compliance
with two independent corpora (80,191 noun pairs), and why specific words
produce the forms they do.

## The core problem

English borrowed thousands of nouns from Latin and Greek, and for many of
them, two plural forms coexist:

| Singular | Modern English | Classical |
|----------|---------------|-----------|
| aquarium | aquariums | aquaria |
| formula | formulas | formulae |
| trauma | traumas | traumata |
| cactus | cacti | cacti |
| datum | data | data |

Some classical forms have become the dominant English form (nobody says
"cactuses" or "datums"). Others haven't (almost nobody says "aquaria" in
everyday English). The challenge is deciding which form to produce by default,
and giving users control when they need the other one.

## Resolution architecture

Plurality uses a three-tier engine, resolved in order:

```
Word
 │
 ├─ Tier 1: Uncountables (MapSet, O(1))
 │   └─ sheep, software, news → returned unchanged
 │
 ├─ Tier 2: Irregulars (Map, O(1))
 │   └─ child→children, person→people, cactus→cacti
 │
 └─ Tier 3: Suffix rules (last-byte dispatch, O(1))
     └─ leaf→leaves, church→churches, category→categories
```

This is the same architecture originated by Damian Conway's 1998 paper
*An Algorithmic Approach to English Pluralization* and used by Rails'
`ActiveSupport::Inflector` and JavaScript's `pluralize.js`. The difference
is implementation: Plurality uses BEAM binary pattern matching and
`select_val` jump tables instead of regex.

### Why this order matters

**Uncountables first.** Words like "sheep" and "software" must be caught
before any transformation is attempted. The uncountables set contains
~1,022 words.

**Irregulars second.** Direct lookups handle the ~1,110 words whose plural
form can't be predicted by suffix rules. This is where modern-vs-classical
decisions are made for known words.

**Suffix rules last.** Pattern-based fallback for the long tail of English.
Handles ~108 suffix patterns via last-byte dispatch.

### Singularize ordering

`singularize/1` checks irregulars **before** uncountables. This is
intentional: words like "data", "graffiti", and "testes" appear in both
sets. Singularization should resolve them to their base forms ("datum",
"graffito", "testis"), not return them unchanged.

## Default forms: modern English

Plurality defaults to modern English forms. This means:

| Word | Default | Why |
|------|---------|-----|
| aquarium | aquariums | Dominant in modern English |
| formula | formulas | Standard outside mathematics |
| trauma | traumas | Universal in medical/general English |
| schema | schemas | Standard in tech/databases |
| stadium | stadiums | Dominant in sports journalism |
| medium | mediums | Standard for non-scientific use |
| focus | focuses | Dominant outside optics |

These are stored in `priv/data/irregulars.tsv` with their modern plurals.

### Words that are classical by default

Some classical forms have fully displaced their modern alternatives in
standard English. These are the default even without `classical: true`:

| Word | Default | Why |
|------|---------|-----|
| cactus | cacti | "Cactuses" exists but is uncommon |
| datum | data | Universal |
| criterion | criteria | Universal |
| phenomenon | phenomena | Universal |
| alumnus | alumni | Universal |
| fungus | fungi | Dominant |
| nucleus | nuclei | Dominant in science |
| stimulus | stimuli | Dominant |
| syllabus | syllabi | Dominant |
| thesis | theses | Universal |
| analysis | analyses | Universal |
| appendix | appendices | Dominant |

These words appear in `irregulars.tsv` with their classical plurals as the
default. They are NOT in `classical_overrides.tsv` because no override is
needed — they're already correct.

### The decision rule

A word gets a classical default when the classical form is the dominant
English form. A word gets a modern default when the modern form is dominant
or when both forms are roughly equal (we err toward modern in ambiguous
cases). Sources consulted: Oxford English Dictionary, Merriam-Webster,
Google Ngrams, and corpus frequency data from AGID and NIH.

## Classical mode

`classical: true` activates Latin/Greek forms for words that have them.
Default behavior stays exactly as-is (zero breakage).

```elixir
Plurality.pluralize("aquarium")                  #=> "aquariums"
Plurality.pluralize("aquarium", classical: true)  #=> "aquaria"
```

### Two-level classical support

**Level 1 — Overrides table** (`priv/data/classical_overrides.tsv`):
95 words where the default is modern but a known classical alternative exists.
Three-column TSV: `singular → modern → classical`.

**Level 2 — Suffix rules** in `rules.ex`: For the long tail of Latin/Greek
words not in any table. Applied only when `classical: true` and no table
match is found.

| Suffix | Rule | Example | Safe? |
|--------|------|---------|-------|
| `-us` → `-i` | Latin 2nd declension masculine | focus → foci | Yes |
| `-um` → `-a` | Latin 2nd declension neuter | aquarium → aquaria | Yes |
| `-ix`/`-ex` → `-ices` | Latin 3rd declension | apex → apices | Yes |
| `-itis` → `-itides` | Greek medical | arthritis → arthritides | Yes |
| `-a` → `-ae` | Latin 1st declension feminine | antenna → antennae | **No** |
| `-on` → `-a` | Greek 3rd declension neuter | ganglion → ganglia | **No** |

### Why `-a → -ae` and `-on → -a` are NOT suffix rules

These patterns have catastrophic false positive rates in English:

- `-a → -ae` would break: sofa, pizza, banana, umbrella, drama, opera
- `-on → -a` would break: button, person, melon, falcon, skeleton, reason

These are handled **only** through the overrides table, where each word is
individually curated. The suffix rules only fire for patterns where the
false positive rate is acceptably low.

### Singularization is mode-independent

`singularize/1` handles both modern and classical plural forms without
needing a mode flag:

```elixir
Plurality.singularize("aquariums")  #=> "aquarium"
Plurality.singularize("aquaria")    #=> "aquarium"
Plurality.singularize("traumata")   #=> "trauma"
Plurality.singularize("traumas")    #=> "trauma"
```

This works because the reverse lookup map (`plural → singular`) is enriched
at compile time with classical plural forms from the overrides table. Both
"aquariums" and "aquaria" point to "aquarium".

For suffix-based singularization, only safe patterns are used:

| Pattern | Rule | Example | Safe? |
|---------|------|---------|-------|
| `-ae` → `-a` | Latin feminine | antennae → antenna | Yes |
| `-ata` → `-a` | Greek neuter | traumata → trauma | Yes |
| `-i` → `-us` | Latin masculine | cacti → cactus | **No** (taxi, ski, broccoli) |
| `-a` → `-um` | Latin neuter | aquaria → aquarium | **No** (sofa, pizza) |
| `-ices` → `-ix` | Latin 3rd | vortices → vortex | **No** (services, offices) |
| `-itides` → `-itis` | Greek medical | arthritides → arthritis | **No** (tritides) |

Unsafe patterns are handled only through the reverse map (known words).

## Data sources and corpus compliance

### Source data pipeline

Plurality's data was curated from seven libraries across five language
ecosystems, then verified against two independent linguistic corpora:

**Library sources** (merged into `irregulars.tsv` and `uncountables.txt`):

1. [Exflect](https://hex.pm/packages/exflect) (Elixir) — Tyler Wray
2. [Inflex](https://hex.pm/packages/inflex) (Elixir) — Miguel Palhas
3. [pluralize](https://github.com/plurals/pluralize) (JavaScript) — Blake Embrey
4. Rails `ActiveSupport::Inflector` (Ruby)
5. [go-pluralize](https://github.com/gertd/go-pluralize) (Go)
6. [Humanizer](https://github.com/Humanizr/Humanizer) (C#)
7. [Pluralizer](https://crates.io/crates/pluralizer) (Rust)

**Verification corpora:**

1. **AGID** — Automatically Generated Inflection Database (Kevin Atkinson,
   public domain). 32,625 verified noun pairs.
2. **NIH SPECIALIST Lexicon** — National Library of Medicine, 2025 release.
   47,566 verified noun pairs covering medical, scientific, and general
   English.

**Total: 80,191 noun pairs verified in both directions** (pluralize AND
singularize).

### How corpus verification works

Both corpora are processed by parser scripts in `dev/research/` that:

1. Stream the raw corpus data (not loading it all into memory)
2. Extract noun entries only
3. Filter for lowercase single-word forms
4. Take the first (preferred) plural form when alternatives exist
5. Skip entries with uncertainty markers
6. Deduplicate by singular form
7. Test both `pluralize(singular) == plural` and `singularize(plural) == singular`
8. Write passing pairs to test support files

The resulting pairs are used in the test suite. Every `mix test` run verifies
all 80,191 pairs in both directions.

### Corpus internal inconsistency

Neither NIH nor AGID is internally consistent about modern vs. classical
forms. Both corpora mix the two styles depending on the word:

**NIH SPECIALIST Lexicon:**
- Uses modern forms for common words: aquarium→aquariums, formula→formulas,
  stadium→stadiums (389 `-ums` forms in the passing set)
- Uses classical forms for obscure medical/Latin words: arthritis→arthritides,
  encephalitis→encephalitides (571 `-a` forms in the failure set)
- The passing set is overwhelmingly modern; the failure set is overwhelmingly
  classical. NIH does not follow a single consistent convention.

**AGID:**
- Similarly mixed. Contains both modern and classical forms with no clear
  rule governing which words get which treatment.
- Some entries use classical forms that are rare even in academic writing.

This means **neither corpus represents a coherent "modern" or "classical"
target**. Treating them as 100% accuracy targets would require the library
to be simultaneously modern and classical depending on the word — which is
exactly the inconsistency we're trying to resolve.

### Corpora as validation references, not targets

Plurality treats both corpora as **validation references**: large, curated
word lists for testing coverage and catching regressions. They are not
accuracy targets to hit 100% on.

The library's design is intentional:

1. **Default mode** produces modern English forms — the forms most users
   expect in everyday code.
2. **Classical mode** (`classical: true`) produces Latin/Greek forms for
   words that have them.
3. Words where the classical form IS the dominant English form (criteria,
   phenomena, data, alumni) use classical as the default — no mode switch
   needed.

A word that fails a corpus test is not necessarily a bug. If NIH expects
`arthritides` but Plurality returns `arthritises` in default mode, that's
correct behavior — the modern form IS `arthritises`. The classical form
is available via `classical: true`.

### Corpus conflicts

When AGID and NIH disagree on the correct plural form, we follow this
precedence:

1. **If one form is clearly dominant in modern English** — use that form
2. **If both forms are legitimate** — prefer the modern English form
3. **If the word is domain-specific** — prefer the domain-appropriate corpus
   (NIH for medical terms, AGID for general English)

Conflicts are resolved in `irregulars.tsv` by choosing one canonical pair.
The other form may appear in `classical_overrides.tsv` if it represents a
valid classical alternative.

### What the corpora DON'T cover

Both corpora focus on dictionary-standard English. They don't cover:

- Domain-specific jargon (kubernetes, elasticsearch)
- Proper nouns used as common nouns
- Very recent coinages

These are handled by `Plurality.Custom` modules at the application level.

## Compile-time data pipeline

All data is loaded at compile time. Zero runtime file I/O.

```
priv/data/irregulars.tsv          →  @singular_to_plural (Map)
                                  →  @plural_to_singular (Map)
priv/data/uncountables.txt        →  @uncountables (MapSet)
priv/data/classical_overrides.tsv →  @singular_to_classical_down (Map)
                                  →  enriches @plural_to_singular_down
```

### Conflict resolution at compile time

1. **Irregulars vs. uncountables:** If a word appears in both sets with a
   *different* plural form, the irregular mapping wins and the word is
   auto-excluded from uncountables. Example: "data" has an irregular mapping
   (`data → datum` in reverse), so it's excluded from uncountables for
   singularization purposes.

2. **Force overrides:** Two small override sets handle edge cases:
   - `@force_uncountable`: Words that must stay uncountable regardless of
     irregular mappings (e.g., "chassis")
   - `@force_countable`: Words incorrectly listed as uncountable in source
     data (e.g., "access")

3. **Case variants:** When case-variant entries exist (e.g., `jerry → jerries`
   AND `Jerry → Jerrys`), the lowercase entry takes priority since it
   represents the common noun form.

## Suffix rule design

Suffix rules use last-byte dispatch: extract the final byte of the word,
jump to the appropriate handler via a BEAM `select_val` instruction (O(1)
jump table), then confirm the full suffix with a sized-skip binary match.

### Why some rules are conservative

Every suffix rule must satisfy two criteria:

1. **Low false positive rate** — The rule must not incorrectly transform
   common English words
2. **Round-trip safety** — `singularize(pluralize(word)) == word` for all
   words the rule touches

Rules that fail either criterion are restricted to the overrides table.
This is why `-a → -ae` (Latin feminine) is not a suffix rule despite being
a real Latin pattern: it would break sofa, pizza, banana, and hundreds of
other common English words ending in `-a`.

### The round-trip problem

For singularization, we initially tried a round-trip verification approach:
attempt the transformation, then check if pluralizing the result gives back
the original word. This failed for classical suffix rules because they're
universal — `apply_plural_rule("pizzum", true)` happily returns `"pizza"`,
making every `-a → -um` guess appear correct.

The solution: singularization suffix rules are restricted to patterns that
are unambiguously plural in English (`-ae`, `-ata`). Everything else is
handled through the reverse map of known words.

## File reference

| File | Contents | Count |
|------|----------|-------|
| `priv/data/irregulars.tsv` | Singular → plural pairs | 1,110 |
| `priv/data/uncountables.txt` | Words with no distinct plural | 1,022 |
| `priv/data/classical_overrides.tsv` | Singular → modern → classical | 95 |
| `test/support/agid_pairs.txt` | AGID-verified pairs | 32,625 |
| `test/support/nih_pairs.txt` | NIH-verified pairs | 47,566 |
| `dev/research/agid/parse_agid.exs` | AGID parser script | — |
| `dev/research/nih/parse_nih.exs` | NIH parser script | — |

## App-wide configuration

```elixir
# Use modern English (default)
config :plurality, classical: false

# Use classical Latin/Greek forms globally
config :plurality, classical: true

# Delegate to a custom module for domain overrides
config :plurality, custom_module: MyApp.Inflection
```

Per-call options always override app-wide config:

```elixir
# Even with classical: true in config, this returns modern:
Plurality.pluralize("aquarium", classical: false)  #=> "aquariums"
```
