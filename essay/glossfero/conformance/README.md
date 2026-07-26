# Conformance

This directory is what makes "five simultaneous implementations" a real
constraint rather than an aspiration. A language implementation is not
"done" with a pipeline stage until it passes conformance against every
fixture that exercises that stage.

## How it works

1. `fixtures/<name>/` holds a real input — for a repository-level fixture,
   an actual Git repository (with its `.git` directory committed).
2. `golden/<name>/expected.*.json` (and `.jsonl` for ledgers) holds the
   correct output for that input, computed once by hand-running the exact
   algorithms in `spec/protocol/protocol.md`, never invented and never
   copied from a model's first guess.
3. `golden/<name>/README.md` documents *why* those particular expected
   values are correct — the derivation, not just the number.
4. Each language implementation exposes a `conformance-entrypoint`
   executable satisfying the contract documented at the top of
   `conformance/run`.
5. `./conformance/run <language>` runs that entrypoint against every
   fixture and diffs the output using `conformance/diff.py`.

## Exact-match vs. bounded-match

`conformance/diff.py` is the reference implementation of the rule in
`spec/protocol/protocol.md` §7: fields derived purely from Git facts or
deterministic computation must match exactly; fields that legitimately vary
with model version (summaries, confidence scores, free-text reasons) are
checked for shape and range only. Read the module docstring in `diff.py`
before adding a new object kind or field — the two field-classification
dictionaries at the top of that file are themselves part of the spec, not
an implementation detail, and should be kept in sync with
`spec/protocol/protocol.md` §7 by hand.

A very small number of fields are *forced* exceptions to the bounded-match
default: a fixture may be deliberately constructed so that only one
classification is defensible (see `golden/repo-small-001/README.md`'s
discussion of why `object_type` must be `bubble` for that specific
fixture). These are declared explicitly in `diff.py`'s `FORCED_OVERRIDES`
set, keyed by `(fixture_name, object_kind, field)` — never assume a field
is forced without that fixture's own README stating and justifying it.

## Running conformance

```sh
# once <lang>/conformance-entrypoint exists:
./conformance/run rust
./conformance/run haskell repo-small-001
./conformance/run python
./conformance/run clojure
```

Elm has no headless entrypoint (see `conformance/run`'s header comment) —
its conformance is exercised differently, by feeding it the same
`RepoRecord` / `Proposal` / `CollisionResult` / `GlossferoName` JSON objects
that the other four implementations produce, and checking that its pure
model-transformation functions handle them per the type definitions in the
design discussion. That harness is not yet built.

## Adding a new fixture

1. Build the real input under `fixtures/<name>/`.
2. Derive every expected value by actually running the protocol's
   algorithms against that input — script it, don't hand-type it (see the
   closing paragraph of `golden/repo-small-001/README.md`).
3. Validate every golden JSON file against its schema in `spec/schemas/`
   before committing it. A golden fixture that doesn't validate against its
   own schema is not a fixture, it's a bug.
4. Write `golden/<name>/README.md` explaining the derivation, exactly as
   `golden/repo-small-001/README.md` does.
5. If the fixture is designed to force a particular model classification
   (rare — most fixtures should leave semantic fields bounded, not forced),
   say so explicitly and add the override to `diff.py`.
