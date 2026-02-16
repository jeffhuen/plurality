# Changelog

The format is based on [Common Changelog](https://common-changelog.org/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3] - 2026-02-16

### Changed

- Rewrite `Plurality.Style` internals to use prefix slicing instead of
  per-character iteration, eliminating intermediate allocations

### Fixed

- Preserve casing on PascalCase and camelCase compound words
  (`pluralize("ResourceAttachment")` now returns `"ResourceAttachments"`
  instead of `"resourceattachments"`)
- Singularize `-se` root words correctly (`singularize("cases")` now returns
  `"case"` instead of `"cas"`, along with 82 other common words like `horse`,
  `nurse`, `purse`, `course`, `verse`, `pulse`, `sense`, `response`)

## [0.2.2] - 2026-02-15

### Changed

- Default 10 words to modern English plurals (cactus, octopus, fungus, etc.);
  classical forms remain available via `classical: true`

### Added

- Add irregulars for compound nouns (attorney general, court-martial,
  mother-in-law, etc.) and missing -oes words (domino, embargo, mango)
- Add uncountables: hovercraft, shorts, briefs, leggings, overalls, tweezers
- Add [Ambiguous Words guide](guides/ambiguous-words.md) documenting known
  ambiguities with `Plurality.Custom` override examples

### Fixed

- Correct irregulars and uncountables for trout, glass, head of state,
  mosquito, veto, axes/axis, court-martial, and others

## [0.2.1] - 2026-02-14

### Changed

- Remove non-noun pronoun mappings from the irregulars corpus. Entries like
  `her`/`their` and `him`/`them` produced nonsensical cross-mappings
  (e.g., `singularize("their")` returned `"her"`)

### Fixed

- Match `Plurality.Custom` overrides case-insensitively, consistent with
  the core engine
- Treat identity irregulars (`cat-o'-nine-tails`, `faux-pas`, `helium`,
  `quartz`, `sleep`) as uncountable
- Register data files as `@external_resource` so edits trigger recompilation
  without `mix clean`

## [0.2.0] - 2026-02-14

### Added

- Add classical mode: `classical: true` option for Latin/Greek plural forms
  (69 overrides, 4 suffix rules, app-wide config support)
- Add `inflect/3` opts passthrough (e.g., `classical: true`)
- Add compound noun handling: multi-word nouns split on last space, last word
  inflected; known multi-word irregulars take priority
- Add compound irregular suffix rules: `-child` → `-children`,
  `-tooth` → `-teeth`, `-foot` → `-feet`, `-mouse` → `-mice`,
  `-person` → `-people`, `-fish` unchanged
- Add app-wide config delegation via `config :plurality, custom_module:`
- Add AGID corpus test suite (32,625 noun pairs verified in both directions)
- Add NIH SPECIALIST Lexicon test suite (47,566 noun pairs verified in both
  directions)
- Add Ash integration (optional, compiles away if Ash is not loaded):
  changes, validations, and calculations for pluralize/singularize

### Fixed

- Fix `-ff` words producing `-fves` plurals (e.g., `bluff` → `bluffs`
  instead of `blufves`)
- Invert `-f` pluralization logic: small allowlist of `-ves` words instead
  of large blocklist

## [0.1.0] - 2025-02-14

### Added

- Add core inflection engine with three-tier resolution: uncountables,
  irregulars, suffix rules
- Add `pluralize/2` with `check: true` for safe pluralization
- Add `singularize/1`, `plural?/1`, `singular?/1`, `inflect/2`
- Add case preservation: ALL CAPS, Title Case, lowercase
- Add `Plurality.Custom` macro for compile-time domain overrides
- Add zero-regex suffix engine using last-byte dispatch
- Merge data from 7 libraries across 5 languages (1,097 irregulars,
  1,022 uncountables, 108 suffix rules)
