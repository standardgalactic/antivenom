# Glossfero

A system that scans a Git repository or corpus, proposes decompositions
into smaller repositories, checks every proposal against a global catalogue
of roughly 22,000 existing repositories, assigns a typed namespace, and
produces an auditable migration plan. By default it never creates, deletes,
splits, renames, pushes, or rewrites a real repository — it proposes and
records. Mutation is a distinct, later, explicitly-authorized phase.

Five independent implementations (Rust, Haskell, Python, Clojure, Elm) are
built as an N-version system against one shared contract, not as five ports
that immediately drift apart. This is the whole point of the layout below:
`spec/` is sovereign, and no single implementation is allowed to become the
de facto specification by accident.

## Layout

```
glossfero/
    spec/
        schemas/      JSON Schema for every object the system passes around
        invariants/   the stage invariants that halt the pipeline
        protocol/     the pipeline, algorithms, and canonical-serialization rules
        examples/     one valid example instance per schema
    fixtures/          real inputs (e.g. real small Git repositories)
    golden/            expected output for each fixture, plus its derivation
    conformance/       the differ and runner that check an implementation's
                        output against golden/, per spec/protocol §7
    rust/ haskell/ python/ clojure/ elm/
                       the five implementations (not yet started)
    scripts/           cross-cutting dev scripts (canonicalizers, etc.)
```

## Where things actually stand

- **`spec/`** — the language-neutral contract, tightened twice by real
  cross-implementation friction (see below), not just written once and
  left alone.
- **`fixtures/repo-small-001/`** and **`golden/repo-small-001/`** — one
  golden fixture, with a `.glossfero-fixture.json` sidecar (untracked, so
  it doesn't corrupt the fixture's own history/byte counts) supplying the
  `remote` a real DISCOVER stage would otherwise learn from a corpus
  registry.
- **`conformance/`** — a working differ and a stage-aware runner
  (`--stage=discover-measure`, the current default, vs. `--stage=full`).
- **`rust/ haskell/ python/ clojure/`** — DISCOVER + MEASURE, each written
  independently against `spec/protocol/protocol.md` alone, with a working
  `conformance-entrypoint`. All four pass `./conformance/run <lang>
  repo-small-001`, and — the actual point of building four in parallel —
  **all four produce byte-identical `RepoRecord` output**, differing only
  in `scanner_version`, which is implementation identity rather than a
  spec-mandated field.
- **`elm/`** — the review-UI types, decoders, and screen are written
  (`src/Glossfero/Types.elm`, `Decoders.elm`, `Main.elm`), but **not
  compile-verified**: `elm make` needs `package.elm-lang.org`, which this
  environment's network policy blocks with no workaround (unlike the
  other four, which each had *some* path around their package-fetching
  problem — apt, crates.io, or a GitHub release binary). Treat it as
  unverified until you run `elm make` against it yourself. See
  `elm/README.md` for the honest version of this caveat.

### What the four-way comparison actually caught

Building four implementations in parallel against the same spec, then
diffing their output, is only worth doing if it can catch something. It
did, once: Haskell's default `Show Double` instance rendered a small
language fraction in scientific notation
(`3.0167597765363128e-2`) while Python and Rust both used plain decimal
(`0.030167597765363128`) for the identical value.
`conformance/diff.py` didn't catch it — it does semantic JSON-value
equality, not byte comparison — so this would have shipped as a "passing"
implementation while silently producing different bytes and different
ledger `payload_hash` values downstream. `spec/protocol/protocol.md` §8
was genuinely ambiguous on this point ("shortest round-trip" constrains
the digit sequence, not the notation); it's now explicit that canonical
serialization is always plain decimal, never scientific notation, and
Haskell's formatter (and Clojure's, written after and informed by this)
were both hand-written to comply rather than trusting a language default.

Two more real bugs surfaced and were fixed along the way, both mine: the
golden `RepoRecord.languages` field had been hand-set to `{"Python": 1.0}`
without actually computing it from file bytes (the fixture also has a
README and a `pyproject.toml`) — `protocol.md` §1d now specifies a real
extension-based algorithm and the golden value was recomputed from it. And
two accidental edits of my own briefly deleted the "Fingerprint cascade"
section heading from `protocol.md` while inserting new subsections next to
it — caught by rereading the document, not by any tooling.

## Milestone 1

Per the design discussion, the first complete vertical slice is:

```
scan 22k repo names + metadata -> build local registry
  -> inspect one medium repository -> generate structural summary
  -> propose 3-10 candidate components -> globally compare those candidates
  -> assign typed names -> write an immutable proposal ledger
  -> show it in Elm
```

No repository creation yet. Done when all five implementations can consume
`fixtures/repo-small-001/` and pass `./conformance/run <lang>`.

## Next steps

1. **Decide on the naming-grammar schema migration.** `spec/protocol/naming.md`
   reframes the five "Glossfero object types" as an open-ended naming and
   exception language (Popo), not a fixed ontology, and in the process
   surfaces a real conflict: `cloak` was defined two incompatible ways
   across this project's own history (a descriptive "adapter/compatibility
   layer" type vs. a Popo operator meaning "excluded from the current
   operation"). `naming.md` resolves this in favor of the operator
   reading and proposes a concrete, breaking schema migration (`cloak`
   removed from `object_type`'s enum, `discriminator` generalized from a
   single field to a `discriminators` array, a new open-vocabulary
   `operators` array added). That migration has **not** been executed —
   only the two stale prose descriptions of the old `cloak` meaning have
   been fixed. Executing it touches the schema, the golden fixture, and
   the ledger's `payload_hash` values; do that as its own deliberate pass
   before any backend implements `NAME`, not folded into unrelated work.
2. **Verify Elm compiles.** Run `cd elm && elm make src/Main.elm
   --output=elm.js` somewhere with normal internet access and fix whatever
   it finds — see `elm/README.md`.
3. **SUMMARIZE + the model provider boundary.** Each backend needs a
   provider implementation speaking only `ModelRequest`/`ModelResponse`
   (`spec/schemas/`) before any Ollama-specific code, per
   `spec/protocol/protocol.md` §6. This is the point where the four
   backends stop being able to avoid the one genuinely non-deterministic
   part of the pipeline, and where `conformance/diff.py`'s bounded-match
   fields (rather than exact-match) start actually mattering.
4. **PROPOSE PARTITION.** Requires the co-change/dependency graph
   construction described in the design discussion — `spec/protocol.md`
   §1b already pins down the co-change and cross-boundary-cost formulas
   the graph output feeds into, but the graph construction itself (and the
   candidate-cluster generation from directory/package/manifest/size
   boundaries) isn't yet specified as precisely as §1a–§1d were, and
   probably needs the same treatment before four more implementations
   diverge on it.
5. **`--stage=full` conformance.** Once a backend reaches NAME, extend its
   `conformance-entrypoint` to also emit `proposal.json`,
   `collision_result.json`, and `glossfero_name.json`, and switch
   `./conformance/run <lang>` to `--stage=full`.
