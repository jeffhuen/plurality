# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-02-14

### Fixed

- `Plurality.Custom` now matches overrides case-insensitively, consistent with
  the core engine. Mixed-case entries like `{"Regex", "Regexen"}` previously
  failed to match at runtime.
- Identity irregulars (`cat-o'-nine-tails`, `faux-pas`, `helium`, `quartz`,
  `sleep`) are now correctly treated as uncountable. Previously,
  `singularize("faux-pas")` returned `"faux-pa"`.
- Data files (`irregulars.tsv`, `uncountables.txt`, `classical_overrides.tsv`)
  are now registered as `@external_resource`, so editing them triggers
  recompilation without requiring `mix clean`.

### Changed

- Removed non-noun pronoun mappings from the irregulars corpus. Entries like
  `her`/`their`, `him`/`them`, and `he`/`them` produced nonsensical
  cross-mappings (e.g., `singularize("their")` returned `"her"`). Plurality
  operates on English nouns; other parts of speech are not in scope.

## [0.2.0] - 2026-02-14

### Added

- Classical mode: `classical: true` option for Latin/Greek plural forms
  - `pluralize("aquarium", classical: true)` => `"aquaria"`
  - `pluralize("formula", classical: true)` => `"formulae"`
  - `pluralize("trauma", classical: true)` => `"traumata"`
  - 69 classical overrides curated from NIH SPECIALIST Lexicon
  - Classical suffix rules: `-us` → `-i`, `-um` → `-a`, `-ix/-ex` → `-ices`, `-itis` → `-itides`
  - Singularization handles both modern and classical forms automatically (no flag needed)
  - App-wide config: `config :plurality, classical: true`
  - Per-call `classical: true/false` overrides app config
- `inflect/3` accepts opts passthrough (e.g., `classical: true`)
- Compound noun handling: multi-word nouns split on last space, last word inflected
  - `pluralize("status code")` => `"status codes"`
  - Known multi-word irregulars in data take priority over splitting
- Compound irregular suffix rules: `-child` → `-children`, `-tooth` → `-teeth`,
  `-foot` → `-feet`, `-mouse` → `-mice`, `-person` → `-people`, `-fish` unchanged
  - `pluralize("grandchild")` => `"grandchildren"`
  - `pluralize("swordfish")` => `"swordfish"`
- App-wide config delegation: `config :plurality, custom_module: MyApp.Inflection`
  makes all `Plurality.*` functions delegate to a custom module automatically
- AGID corpus test suite: 32,625 noun pairs from the Automatically Generated
  Inflection Database verified in both directions
- NIH SPECIALIST Lexicon test suite: 47,566 noun pairs from the National Library
  of Medicine's 2025 release verified in both directions
- Ash integration (optional, compiles away if Ash is not loaded):
  - `Plurality.Ash.Changes.Pluralize` — auto-pluralize an attribute from another
  - `Plurality.Ash.Changes.Singularize` — auto-singularize an attribute from another
  - `Plurality.Ash.Validations.PluralForm` — validate attribute is in plural form
  - `Plurality.Ash.Validations.SingularForm` — validate attribute is in singular form
  - `Plurality.Ash.Calculations.Pluralize` — derived plural calculation
  - `Plurality.Ash.Calculations.Singularize` — derived singular calculation

### Fixed

- Words ending in `-ff` no longer incorrectly produce `-fves` plurals
  (e.g., `bluff` → `bluffs` instead of `blufves`)
- Inverted `-f` pluralization logic: small allowlist of words that take `-ves`
  (leaf, wolf, etc.) instead of large blocklist of words that keep `-s`

## [0.1.0] - 2025-02-14

### Added

- Core inflection engine with three-tier resolution: uncountables, irregulars, suffix rules
- `Plurality.pluralize/2` with `check: true` option for safe pluralization
- `Plurality.singularize/1` for reverse inflection
- `Plurality.plural?/1` and `Plurality.singular?/1` for form detection
- `Plurality.inflect/2` for count-based inflection
- Case preservation: ALL CAPS, Title Case, lowercase
- `Plurality.Custom` macro for compile-time domain overrides
- Zero-regex suffix engine using last-byte dispatch (BEAM `select_val` jump table)
- Merged data from 7 libraries across 5 languages (1,097 irregulars, 1,022 uncountables, 108 suffix rules)
- Modern English defaults: schema/schemas, index/indices, premium/premiums
- Irregular parity: all 1,110 merged exception pairs tested
- Business domain coverage: 8 categories, 124+ terms
