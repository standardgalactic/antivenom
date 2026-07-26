# Glossfero — Elm

The human review surface. Per the design discussion and
`spec/invariants/invariants.md`'s core principle, this is where the one
genuinely irreversible decision in the whole pipeline happens: a human,
not Granite, turns a `Proposal` into an assigned `GlossferoName`. This
implementation never shells out to Git and never calls the model provider
directly.

## Layout

- `src/Glossfero/Types.elm` — types mirroring `spec/schemas/`
  (`RepoRecord`, `GlossferoName`, `CollisionResult`, `Proposal`, and their
  enums: `ObjectType`, `CollisionClass`, `ProposalStatus`).
- `src/Glossfero/Decoders.elm` — `Json.Decode` decoders for each,
  including the string ↔ enum mappings (e.g. `"bubble"` ↔ `Bubble`,
  `"NEW"` ↔ `New`) matching the schemas' `enum` values exactly.
- `src/Main.elm` — the review screen itself: `PROPOSED: <name>`, the
  collision classification, the nearest-existing list, and the five
  review actions from the design discussion (`REUSE EXISTING`, `MERGE`,
  `ACCEPT NEW`, `CHANGE TYPE`, `DEFER`). Clicking one only updates local
  state for now — wiring it to actually POST a `HumanReviewAccepted`
  ledger event is later milestone work, not this one.
- `index.html` — a harness that loads illustrative example data (from
  `spec/examples/`, not the golden `repo-small-001` fixture — see the
  comment in `index.html` for why) as Elm flags and mounts the app.

## A real limitation, stated plainly

**I was not able to compile or run this in the sandbox this was built in.**
`elm make` needs network access to `package.elm-lang.org` to resolve and
fetch `elm/core`, `elm/json`, `elm/html`, and `elm/browser`, and that host
returned `403 host_not_allowed` from the sandbox's network policy — unlike
Rust (crates.io), Haskell (apt), and Clojure (apt), which all had a path
around their respective package-fetching problem, Elm's package registry
has no such alternate route available from inside that sandbox. If you're
reading this from a normal machine with ordinary internet access, this is
not a limitation for you — `elm make` will fetch its own dependencies on
first build exactly the way it does for any other new Elm project, and it
should just work. If it doesn't, that's a real bug in this code, not a
restatement of the sandbox issue.

The types and decoders were written and reviewed carefully against
`spec/schemas/` field-by-field (in particular double-checked the record
field counts against each chained `Json.Decode.mapN` call in
`Decoders.elm`, since `elm/json` caps at `map8` and larger records need
that manual `andThen`-chaining pattern, which is easy to get an off-by-one
wrong in without a compiler catching it) — but "carefully reviewed by
hand" is not the same claim as "compiles," and you should treat this
module as unverified until you or CI actually run `elm make` against it.

## Building it yourself

```sh
cd elm
elm make src/Main.elm --output=elm.js
# then open index.html in a browser, or serve it:
python3 -m http.server 8000
```

## What's not done

- No wiring from a `Decide` action to an actual backend POST.
- No harness that loads `golden/repo-small-001/expected.proposal.json`
  and `expected.collision_result.json` directly (the demo in `index.html`
  uses the more illustrative `spec/examples/` data instead — see that
  file's comment). A real conformance-style check for Elm would decode
  every file under `golden/*/expected.*.json` and assert `Ok` for each;
  that harness does not exist yet.
- No `elm-test` unit tests (the `elm-test` tool is itself an npm package,
  which hits the same network limitation described above).
