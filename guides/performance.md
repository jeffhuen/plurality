# Performance

Plurality is designed for high-throughput use. All data is compiled into the
BEAM at build time — there is zero runtime file I/O, zero regex, and zero ETS.

## Throughput

Benchmarked on Apple Silicon M1 Pro, Elixir 1.19, OTP 28:

| Operation | Single word | 10-word batch |
|-----------|-------------|---------------|
| `pluralize/1` | ~6M ops/sec | ~430K batches/sec (~4.3M words/sec) |
| `singularize/1` | ~6M ops/sec | ~440K batches/sec (~4.4M words/sec) |

Irregular words (cactus, child) resolve faster than suffix-rule words
(cat, dog) because they exit at tier 2 without entering the rule engine.

## Memory

Total compiled BEAM size across all modules is ~190 KB. This includes:

- ~1,110 irregular pairs (bidirectional lookup maps)
- ~1,022 uncountable words (membership set)
- ~95 classical override triples
- Suffix rule dispatch tables

All data structures are embedded in the BEAM literal pool at compile time.
No runtime memory allocation is required for lookups.

## Architecture

The three-tier resolution pipeline is ordered for fast short-circuiting:

1. **Irregulars** — `Map` key lookup, O(1). Checked first because irregular
   words are the most common special cases.
2. **Uncountables** — `MapSet` membership test, O(1)
3. **Suffix rules** — last-byte dispatch via BEAM `select_val` jump table, O(1)

Most words resolve at tier 3 (suffix rules). Irregular and uncountable lookups
exit early before reaching the rule engine.

### Hot path optimizations

- **Fast downcase**: skipped entirely when the first byte is already lowercase ASCII
- **Fast style**: case-preservation logic is bypassed for all-lowercase input
- **Deferred classical check**: the classical override map is checked before
  evaluating the classical flag — only the 95 words with overrides pay for
  flag resolution
- **Inline space check**: compound noun detection uses a byte-by-byte scan
  that bails on the first byte for single-word inputs, avoiding the overhead
  of `:binary.match` setup
- **Classical config**: cached in `:persistent_term` after first read for near-zero cost
- **Binary dispatch**: suffix rules extract the last byte and dispatch through a
  compiler-generated jump table — no iteration, no regex

## Running benchmarks

```bash
mix run dev/bench_full.exs
```
