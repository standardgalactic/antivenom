# Golden fixture: repo-small-001

## What this fixture is

A real, small Git repository (`fixtures/repo-small-001/`, including its
actual `.git` directory) with five deliberately-authored commits. It is not
a synthetic JSON description of a repository — every implementation must be
able to run real `git` commands against it.

## Why the history looks the way it does

Commit 1 (`Initial scaffold`) creates `core`, `schema`, and `parser` all at
once and is **excluded** from co-change analysis per protocol.md §1b (an
initial commit necessarily touches every seed file together and carries no
discriminating signal).

Commits 2–5 are constructed so that:

- `src/core/registry.py` and `src/schema/__init__.py` change together
  (commit 2)
- `src/parser/__init__.py` and `src/parser/normalize.py` change together
  (commit 3)
- `src/core/__init__.py` and `src/schema/__init__.py` change together again
  (commit 4)
- `src/parser/normalize.py` and `tests/parser/test_tokenize.py` change
  together (commit 5)

So every post-initial commit that touches anything under `src/parser` or
`tests/parser` touches *only* paths under `src/parser` or `tests/parser`.
Applying the formula in protocol.md §1b:

```
internal_pairs = 2   (commit 3 pair, commit 5 pair)
touching_pairs = 2   (same two pairs — no cross-boundary co-change at all)
cochange_score = 2 / 2 = 1.0
```

`src/parser/__init__.py` contains `from ..core import Token`, a single
cross-boundary import target (`core`). `tests/parser/test_tokenize.py`
imports `from src.parser import tokenize`, which resolves inside the
candidate itself. Applying the formula in protocol.md §1b:

```
imports  = {core, parser}   (2 distinct top-level intra-repo targets)
crossing = {core}           (1 of the 2 is outside source_paths)
cross_boundary_cost = 1 / 2 = 0.5
```

Both values in `golden/repo-small-001/expected.proposal.json` were computed
by running this exact procedure against the fixture's real commit history
(see the derivation script referenced in the top-level README), not chosen
by hand.

## The candidate under test

`candidate_root = "parser"`, `source_paths = ["src/parser",
"tests/parser"]`. `estimated_files = 3`, `estimated_bytes = 672` (the sum of
the three files' blob sizes at `HEAD`, exact match against `git ls-tree -r
-l HEAD`).

## Registry state

The registry is empty except for `repo-small-001` itself at collision-check
time. The expected `CollisionResult.classification` is therefore `NEW`,
resolved at the cheapest possible stage (`stage_reached: "name"`), with an
empty `nearest_existing` array.

## Exact-match vs. bounded-match fields for this fixture

Per protocol.md §7:

**Exact-match** (must be byte-identical after canonical serialization):
`RepoRecord.paths` (9), `.bytes` (1790), `.commits` (5), `.languages`
(`{"Python": 0.8072625698324022, "Markdown": 0.16256983240223463,
"TOML": 0.030167597765363128}`, per the extension table and formula in
protocol.md §1d), `.fingerprints.structural`, `.fingerprints.manifest`
(both computed per protocol.md §1c — see
`expected.repo_record.json`), `Proposal.source_paths`, `.estimated_files`
(3), `.estimated_bytes` (672), `.cochange_score` (1.0),
`.cross_boundary_cost` (0.5), `CollisionResult.classification` (`NEW`),
`.stage_reached` (`"name"`), `.nearest_existing` (`[]`).

**Bounded-match** (shape/range only): `Proposal.summary`,
`.semantic_cohesion` (any value in `[0, 1]`; the reference value `0.9` in
the golden file is illustrative, not required), `CollisionResult.reason`.

**Forced-answer field, as an explicit exception to the usual bounded-match
rule for `GlossferoName.object_type`:** this fixture is deliberately
designed to have one clearly correct classification. `parser` is small (3
files), has exactly one outbound dependency and zero inbound dependencies
from anything else in the fixture, and is internally self-contained
(`cochange_score = 1.0`). Per the `object_type` definitions in
`spec/schemas/glossfero_name.schema.json`, this is textbook `bubble`:
"locally closed, small subsystem." A conforming implementation's Granite
classification for this fixture MUST be `bubble`. If an implementation
produces `sphere`, `text`, or `cloak` for this specific fixture, that is a
conformance failure, not model variance — treat it as a bug in either the
prompt, the structural facts passed to the model, or the provider
integration.

## Regenerating or extending this fixture

Do not hand-edit the files under `expected.*` unless you also update the
underlying repository under `fixtures/repo-small-001/` and recompute every
derived value using the exact procedures in protocol.md §1a–§1c and §8. A
golden fixture whose expected output was typed by hand rather than derived
from the algorithm it's meant to test is worse than no fixture at all.
