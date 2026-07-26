# Fixtures

Each subdirectory here is a real input, not a synthetic description of one.
For a repository-level fixture, that means an actual Git repository —
`.git` directory included — that an implementation's DISCOVER/MEASURE
stage can run real `git` commands against.

## The `.glossfero-fixture.json` sidecar

DISCOVER normally learns a repository's `remote` from the corpus registry
entry that led the scanner to it in the first place — you don't
`git ls-remote` your way to a repo_id from nothing. A standalone fixture
has no such registry, so each fixture directory carries an **untracked**
sidecar file, `.glossfero-fixture.json`, supplying what DISCOVER would
otherwise have been told externally:

```json
{
  "remote": "https://example.invalid/fixtures/repo-small-001.git",
  "scanned_at": "2026-01-15T10:05:00Z"
}
```

This file is deliberately **not** committed into the fixture repository
itself (`git status --short` inside `repo-small-001/` shows it as `??`).
Committing it would change `paths`, `bytes`, and the structural/manifest
fingerprints — corrupting the very golden values it exists to help produce.
Every `conformance-entrypoint` must read `remote` and `scanned_at` from
this sidecar rather than inventing them, so that `repo_id` (derived from
`remote` per protocol.md §1a) and `scanned_at` agree with `golden/`
regardless of which language ran the scan.

`example.invalid` is used deliberately (reserved by RFC 2606 for
documentation and testing) so no fixture remote can ever resolve to a real
network location.
