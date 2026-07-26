# Glossfero Protocol

This document is normative. Where it conflicts with prose in design
discussion or with any single implementation's convenience, this document
wins. Schemas in `spec/schemas/` are the machine-checkable half of this
contract; this file is the human-readable half.

## 1. Pipeline

```
DISCOVER -> MEASURE -> SUMMARIZE -> PROPOSE PARTITION -> GLOBAL COLLISION CHECK
  -> CLASSIFY OBJECT TYPE -> NAME -> VERIFY DEPENDENCIES -> SCORE PROPOSAL
  -> WRITE PLAN + LEDGER -> REPEAT UNTIL STABLE
```

Every stage re-reads the current global registry state before acting. A
proposal accepted at `PROPOSE PARTITION` changes what counts as a collision
at `GLOBAL COLLISION CHECK` for every proposal considered afterward,
including proposals against unrelated repositories, because the registry is
global and shared. Implementations must not cache collision-relevant
registry state across proposals within a single run.

By default the pipeline never creates, deletes, splits, renames, pushes, or
rewrites a real repository. It proposes and records. `glossfero migrate` is
a distinct, explicit, later phase gated on `Proposal.status == "approved"`
(see `invariants.md` INV-8 for the one hard constraint on that phase).

`CLASSIFY OBJECT TYPE` is named in the singular here, but
`spec/protocol/naming.md` §10–§12 has since established that a
Glossfero object is properly modeled as a set of independently-evidenced
predicates, not one type — this stage name, and the single `object_type`
field it feeds, are known to be stale relative to that document. Read
`naming.md` in full before implementing this stage; do not build against
the singular framing implied by the name alone.

## 1a. repo_id derivation

`RepoRecord.repo_id` must be reproducible byte-for-byte across all five
implementations given the same remote URL. The algorithm is fixed:

1. If the remote is in SCP-style shorthand (`user@host:path`), rewrite it to
   `ssh://user@host/path` first.
2. Lowercase the scheme and host components only. Do not lowercase the
   path — repository names may be case-sensitive on the host.
3. Strip a single trailing `.git` suffix, if present.
4. Strip a single trailing `/`, if present.
5. UTF-8 encode the resulting string.
6. `repo_id = "sha256:" + lowercase_hex(sha256(bytes))`

Example: `git@github.com:standardgalactic/yarncrawler.git` normalizes to
`ssh://git@github.com/standardgalactic/yarncrawler` before hashing.

This is the only place remote-URL normalization happens; every later
comparison uses `repo_id`, never the raw remote string.

## 1b. Co-change and cross-boundary measurement (exact-match rules)

To keep `Proposal.cochange_score` and `.cross_boundary_cost` exact-match
conformance fields (see §7), both are defined precisely rather than left to
implementation judgment:

**Co-change graph** is built from all commits except the repository's first
commit (the initial commit necessarily touches every seed file at once and
carries no discriminating co-change signal). Two paths P1, P2 are a
co-change pair for a given commit if both appear in that commit's changed-path
list.

**`cochange_score`** for a candidate with `source_paths` S:

```
internal_pairs = co-change pairs (P1, P2) where both P1 and P2 fall under S
touching_pairs = co-change pairs (P1, P2) where at least one of P1, P2 falls under S
cochange_score = internal_pairs / touching_pairs   (0 if touching_pairs == 0)
```

**Cross-repo/package import graph** is built from top-level intra-repository
import targets only (e.g. Python `from ..core import X` resolves to the
top-level package `core`; a relative import resolving inside the same
candidate is not crossing).

**`cross_boundary_cost`** for a candidate with `source_paths` S:

```
imports = distinct top-level intra-repo packages imported by any file under S
crossing = the subset of imports whose resolved package path is NOT itself under S
cross_boundary_cost = |crossing| / |imports|   (0 if imports is empty)
```

## 1c. Structural and manifest fingerprint algorithms

Both are defined precisely for the same reason as §1b:

**`fingerprints.structural`** — sort all tracked paths (`git ls-files`
output) lexicographically by their exact byte string, join with a single
`\n`, UTF-8 encode, and SHA-256 the result:

```
structural = "sha256:" + sha256("\n".join(sorted(tracked_paths)))
```

This captures tree shape only — not file contents — deliberately, since it
must be cheap enough to be the second-cheapest stage in the fingerprint
cascade (§2).

**`fingerprints.manifest`** — among the tracked paths, select those matching
a recognized manifest filename (`Cargo.toml`, `pyproject.toml`,
`requirements.txt`, `package.json`, `elm.json`, `deps.edn`, `project.clj`,
`pom.xml`, `build.gradle`, `cabal.project`, `*.cabal`, `stack.yaml`,
`go.mod`, `Makefile`, `CMakeLists.txt`). For each match, look up its Git
blob SHA-1 at `head_commit` (`git ls-tree`). Sort matches by path, join each
as `"<path>:<blob_sha>"`, join the list with `\n`, UTF-8 encode, and
SHA-256:

```
manifest = "sha256:" + sha256("\n".join(sorted(f"{path}:{blob_sha}" for path, blob_sha in matches)))
```

If no manifest files are present, `fingerprints.manifest` is
`"sha256:" + sha256("")` (the hash of the empty string), not `null`. `null`
is reserved for fingerprints not yet computed at all (`history`,
`semantic`, `content` prior to their respective stages); an
empty-but-computed manifest fingerprint is a real, meaningful result.

## 1d. Language fraction computation

`RepoRecord.languages` maps a language name to its fraction of total
tracked bytes at `head_commit`. The mapping from file to language is by
extension only for milestone 1 (no shebang or content sniffing):

| Extension(s) | Language |
|---|---|
| `.py` | Python |
| `.rs` | Rust |
| `.hs` | Haskell |
| `.clj`, `.cljc`, `.cljs`, `.edn` | Clojure |
| `.elm` | Elm |
| `.js`, `.mjs` | JavaScript |
| `.ts` | TypeScript |
| `.md`, `.markdown` | Markdown |
| `.toml` | TOML |
| `.json` | JSON |
| `.yaml`, `.yml` | YAML |
| `.sh`, `.bash` | Shell |
| (no extension, or any extension not listed above) | Other |

This table is intentionally minimal for milestone 1 and will grow as
fixtures exercise more languages; treat it as append-only — do not
reclassify an extension already listed above without also regenerating
every golden fixture whose `languages` field depends on it.

For each tracked path, take its blob size in bytes at `head_commit`
(`git ls-tree -r -l HEAD`) and attribute the full size to the single
language its extension maps to (no fractional attribution within a file).
Sum by language, then:

```
languages[L] = bytes(L) / total_bytes
```

as an IEEE 754 double, with no rounding beyond whatever the division
itself produces. Implementations must not round to a fixed number of
decimal places — since all five languages use IEEE 754 doubles for
ordinary division, an unrounded quotient from identical integer inputs is
itself exactly reproducible bit-for-bit, whereas an arbitrary rounding rule
is an extra source of cross-implementation drift, not a fix for one.
Languages contributing zero bytes are omitted from the map entirely (do not
include zero-valued entries).

## 2. Fingerprint cascade

`RepoRecord.fingerprints` holds up to six independent fingerprints. No
single one answers "is this a duplicate of something in the catalogue."
Consult them in this order, cheapest first, and stop as soon as the
question is resolved:

1. `name` — normalized name (punctuation, case, separator, Unicode, known
   affix stripped)
2. metadata (language mix, path/byte/commit counts — not a stored
   fingerprint field, but the cheapest structured comparison after name)
3. `manifest` — derived from build/dependency manifests
4. `structural` — hash of the normalized tree shape
5. `semantic` — derived from Granite summaries, optionally embeddings
6. `content` — sampled or full blob hashes
7. `history` — commit ancestry relation, when available

`CollisionResult.stage_reached` records the last stage actually executed.
Implementations must not run stage *N+1* once stage *N* resolves the
classification; this is a correctness requirement, not a performance
suggestion, because it is what keeps a 22,000-repository catalogue from
requiring 22,000 expensive comparisons per candidate.

## 3. Global collision algorithm

For every candidate, in order:

1. normalize candidate root
2. exact-name lookup
3. typed-name lookup
4. token similarity lookup
5. semantic-root lookup
6. embedding nearest-neighbor lookup
7. manifest similarity
8. source/content overlap
9. Git-history relationship
10. Granite comparison of the top 5–20 plausible matches only
11. classify into one of the nine `CollisionResult.classification` values

Granite must never be shown a description of all 22,000 repositories. It
sees only the bounded candidate set surfaced by steps 1–9, formatted as in
`spec/examples/model_request.example.json`.

Once a candidate reaches `NAME`, the actual naming procedure — the
escalation hierarchy from ordinary name through synonym substitution to
descriptive affix to Popo operator, and the formal grammar governing how
`semantic_root`, discriminators, and operators compose into a
`GlossferoName` — is specified in full in `spec/protocol/naming.md`, not
here. That document also formally redefines `cloak` (previously a
descriptive `object_type` in this schema, now a Popo operator) and
records the resulting proposed schema migration; read it before
implementing `NAME` in any backend.

## 4. Scoring function

```
J(P) = alpha * C_cross
     + beta  * H_cochange
     + gamma * S_imbalance
     + delta * A_ambiguity
     + epsilon * D_duplicate
     - zeta  * C_semantic
```

Lower is better.

| Term          | Meaning                                                          | Source                  |
|---------------|-------------------------------------------------------------------|--------------------------|
| `C_cross`     | dependencies crossing the proposed boundary                       | measured (dependency graph) |
| `H_cochange`  | penalty for separating files that historically change together    | measured (co-change graph) |
| `S_imbalance` | penalty for pathological partitions (e.g. one giant + many tiny)   | measured |
| `A_ambiguity` | penalty for components with unclear responsibility                 | model estimate |
| `D_duplicate` | penalty for resembling an existing catalogue entry                 | measured (collision cascade) |
| `C_semantic`  | reward for internal conceptual cohesion                            | model estimate |

Only `A_ambiguity` and `C_semantic` come from the model. Every other term
must be reproducible from repository facts alone, independent of model
version. This split is what makes `cochange_score` and
`cross_boundary_cost` on `Proposal` exact-match conformance fields while
`semantic_cohesion` is a bounded-range conformance field (see §6).

Coefficients `alpha..zeta` and their current values live in
`spec/protocol/scoring-weights.json` (added when the scoring stage is
implemented; not required for milestone 1, which only requires the
structural terms to be computed and recorded, not yet combined into a
single `score`).

## 5. Recursive summarization

```
file facts -> directory summaries -> subsystem summaries
  -> repository summary -> corpus summary
```

Never ask the model to summarize an entire repository in one call. Every
summary at every layer carries `evidence` linking back to the specific
manifests, imports, and representative files that grounded it (see INV-5).
A summary without evidence is invalid input to any later stage.

## 6. Model provider contract

Implementations must wrap Ollama (or any other provider) behind an
interface that speaks only `ModelRequest` / `ModelResponse`
(`spec/schemas/model_request.schema.json`,
`spec/schemas/model_response.schema.json`). No code outside that provider
boundary may know the word "Ollama" exists. A response failing schema
validation is invalid per INV-6; there is no partial-credit parsing.

## 7. Conformance: exact-match vs. bounded-match fields

Because Granite output is not bit-for-bit reproducible across model
versions, `conformance/` distinguishes two categories of field when diffing
an implementation's output against `golden/<fixture>/`:

**Exact-match fields** — must be byte-identical after canonical
serialization (see §8). These are all fields derived solely from Git facts
or deterministic computation: `RepoRecord.paths`, `.bytes`, `.commits`,
`.languages`, `.fingerprints.structural`, `.fingerprints.manifest`,
`Proposal.source_paths`, `.estimated_files`, `.estimated_bytes`,
`.cochange_score`, `.cross_boundary_cost`, `CollisionResult.classification`
(given a fixed, empty-or-fixture-only registry state),
`CollisionResult.stage_reached`.

**Bounded-match fields** — must satisfy a shape or range predicate, not an
exact value. These are fields that legitimately vary with model version or
sampling: `Proposal.summary`, `.semantic_cohesion` (range only),
`ModelResponse.confidence`, `.reason`, `CollisionResult.reason`,
`GlossferoName.object_type` (must be *plausible*, checked against an
allowed-set for the fixture, not a single required value, unless the
fixture is specifically designed to force one answer — see
`golden/repo-small-001/README.md`).

An implementation that produces the correct exact-match fields but a
differently-worded (non-empty, on-topic) `summary` is conformant. An
implementation that produces a byte-different `cochange_score` is not.

## 8. Canonical serialization

Two distinct serialization rules apply, depending on artifact shape.

**Standalone JSON artifacts** (a single object in its own `.json` file —
`RepoRecord`, `Proposal`, `CollisionResult`, `GlossferoName`,
`ModelRequest`, `ModelResponse`, and any single example or golden file):

- UTF-8, no BOM
- object keys sorted lexicographically at every level
- 2-space indentation
- no trailing whitespace on any line
- exactly one trailing newline at end of file
- floating-point values rendered with the minimal representation that
  round-trips (implementations should use their language's standard
  "shortest round-trip" float formatter; do not hand-roll one), **always
  in plain decimal notation, never scientific/exponential notation** (not
  `3.0167597765363128e-2`, but `0.030167597765363128`). "Shortest
  round-trip" constrains the digit sequence, not the notation, and a
  formatter that switches to exponential notation below some magnitude
  threshold (Haskell's `Double`'s default `Show` instance does this) is
  non-conformant even though the underlying digits are correct — this was
  caught empirically the first time four independent implementations were
  compared, not anticipated in advance, which is exactly why the
  N-version comparison in the first place is worth doing before, not
  after, four implementations diverge on it silently.

**JSON Lines artifacts** (`ledger.jsonl`, `repos.jsonl`, and any other
append-oriented log): each line is one complete JSON object, keys sorted,
**compact** (no inserted whitespace after `:` or `,`), UTF-8, no BOM, and
terminated by a single `\n`. Do not pretty-print inside a JSONL file — one
event per line is the format's entire point, and a multi-line event breaks
every line-oriented tool (including `tail -f`, `wc -l`, and streaming
parsers) that JSONL exists to support.

`payload_hash` on a `LedgerEvent` is always computed over the **pretty**
canonical form of the `payload` object alone (per the standalone-artifact
rule above), regardless of how the enclosing event is serialized on disk.
This keeps the hash stable even if a future implementation changes how it
lays out the surrounding ledger file.

`scripts/canonicalize.*` (one per language, added alongside each
implementation) must produce identical bytes for identical logical content
across all five languages, in both serialization modes. This is itself a
conformance-tested property.

## 9. Rescan and re-summarize keys

- Repository rescan key: `remote + head_commit + scanner_version`. If
  unchanged, skip DISCOVER/MEASURE and reuse the stored `RepoRecord`.
- Semantic summary reuse key: `repo head_commit + prompt_version +
  model_version`. If unchanged, skip the model call and reuse the stored
  summary.

Both keys exist to prevent a single new decomposition proposal from
triggering redundant inference across the whole 22,000-repository corpus.
