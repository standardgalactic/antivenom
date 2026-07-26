# Glossfero Stage Invariants

These invariants are load-bearing. A conforming implementation MUST halt the
pipeline — not degrade, not guess, not proceed with a warning — when one of
these fails. Halting means: no further stage runs for the affected proposal
or repository, and a diagnostic is surfaced to the human reviewer. Halting
does not mean crashing the whole process; other independent proposals may
continue.

Each invariant has a stable ID. Conformance fixtures and test names should
reference these IDs directly (e.g. a fixture testing INV-1 is named
`inv-1-source-commit-changed`).

## INV-1 — Source commit changed during analysis

If `source_commit` on a `Proposal` no longer equals the current `head_commit`
of `source_repo` at the time a later stage consults it, the proposal is
stale. It must be regenerated from DISCOVER, not patched in place.

## INV-2 — Global registry is stale beyond configured tolerance

`GLOBAL COLLISION CHECK` must refuse to run if the local materialized
registry has not been refreshed within the configured tolerance window.
"Stale but close enough" is not an acceptable state for a check whose entire
purpose is comparison against the current global catalogue.

## INV-3 — Candidate has unresolved semantic duplicate

A `Proposal` whose `CollisionResult.classification` is one of
`SEMANTIC_DUPLICATE`, `SEMANTIC_OVERLAP`, `AMBIGUOUS`, or
`REQUIRES_HUMAN_REVIEW` may not proceed to `NAME` until a human review event
(`HumanReviewAccepted`) resolves it.

## INV-4 — Candidate splits a strongly coupled dependency cycle

If the proposed partition would cut a path through the dependency graph that
forms a cycle spanning the proposed boundary, the proposal must halt at
`PROPOSE PARTITION`. Cutting a cycle silently produces two repositories that
cannot build independently; this is a structural defect, not a matter of
taste, and must not be deferred to human judgment as a mere style question.

## INV-5 — Provenance is incomplete

Every `summary` (directory, subsystem, repository, or corpus level) must
carry non-empty `evidence` (manifests, imports, or representative files) as
described in protocol.md's recursive summarization section. A summary
without evidence is not a summary; it is an unattributed guess and must be
rejected before it can ground any downstream classification.

## INV-6 — Model response fails schema

A `ModelResponse` that fails validation against
`model_response.schema.json` is invalid. It is never treated as "close
enough" and never partially accepted. The provider call must be retried or
the candidate escalated to `REQUIRES_HUMAN_REVIEW`; no implementation may
coerce, truncate, or best-effort-parse a malformed response into a valid
one.

## INV-7 — Candidate name is not typed

No `GlossferoName` may reach `status: "assigned"` without a valid
`object_type`. There is no untyped or "type: TBD" resting state for an
assigned name. If the type is genuinely undetermined, the candidate stays at
`status: "candidate"` and blocks at `NAME`.

## INV-8 — Migration would lose history without explicit override

Any migration plan that would produce a target repository whose commit
history does not trace back to the corresponding paths in the source
repository must halt `WRITE PLAN` unless a human has explicitly set an
override flag on that specific `MigrationPlanned` event. History loss is
never a silent default.

---

## The naming resolution rule

This is not a numbered stage invariant because it governs `NAME` directly
rather than gating a transition, but it is equally load-bearing:

> `foo.object != foo.text` — different `object_type` values are always
> different objects.
>
> `foo.object == foo.object` collisions are never resolved by inventing
> `foo2.object`, `foo-new.object`, or `foo-final.object`. Numeric or ordinal
> suffixes are collision noise, not discriminators.
>
> The only legitimate resolution is either (a) determining the candidate is
> the *same* semantic object and reusing the existing name, or (b) finding a
> genuine semantic discriminator (`foo.parser.object`,
> `foo-compat.cloak`) that describes what actually distinguishes the two
> objects.

**This rule, and the object-type vocabulary it references, is now formally
superseded and generalized by `spec/protocol/naming.md`.** In particular:
`cloak` is no longer a descriptive object type meaning "adapter/
compatibility layer" — it has been redefined as a Popo *operator* meaning
"excluded from the current quantified operation," which says nothing
about the object's content. `foo-compat.cloak` above reads correctly
under the new grammar (`compat` is an ordinary discriminator, `.cloak`
is an operator marking exclusion) but would have meant something
different — and something wrong — under this rule's original,
now-superseded reading of `.cloak` as a content-descriptive affix.
Read `spec/protocol/naming.md` in full before implementing NAME; this
section is kept here only because deleting it would break the numbered
invariants' cross-references above.
>
> A human may explicitly authorize a non-semantic disambiguation as a
> last resort, but this must be a recorded, deliberate exception — never a
> default fallback path any implementation reaches for automatically.

### Why the object-type suffixes are full words, not abbreviations

`.bubble`, `.sphere`, `.object`, `.text`, and `.cloak` are deliberately
full words rather than legacy three- or four-character abbreviations
(`.bub`, `.sph`, `.obj`, `.txt`, `.clk`). The three-character convention
comes from DOS/Windows 8.3 filenames, where the extension genuinely had a
separate length limit. On the filesystems this project targets (ext4,
NTFS, and every Git hosting backend built on them), there is no such
limit — an "extension" is simply whatever follows the last `.` in a
filename component, and the filesystem itself imposes no separate bound on
it. `foo.sph`, `foo.sphe`, and `foo.sphere` are three distinct, equally
valid filenames; nothing is gained by artificially compressing the type
name, and a full word is strictly more legible than an abbreviation a
future contributor has to remember the meaning of.

This is also what makes the `semantic_root[.discriminator].object_type`
shape in `spec/schemas/glossfero_name.schema.json` work the way it's
meant to: most software (and Git hosts) treat everything after the
*last* `.` as the extension, so `foo.parser.object` has extension
`.object` with `parser` read as part of the base name. That is exactly
the intended reading — the terminal component states the Glossfero
object class; any preceding dotted component is a semantic discriminator
refining identity within that class, never a second, competing type tag.

The one real constraint worth keeping in mind is the ordinary filesystem
limit on a whole filename component (typically around 255 bytes,
encoding-dependent) — not on the extension specifically, but on
`semantic_root` + `.discriminator` + `.object_type` combined, since a
`GlossferoName`'s `full_name` becomes a real repository or directory name
on an actual Git host. `spec/schemas/glossfero_name.schema.json` does not
currently enforce a `maxLength` on `semantic_root` or `discriminator`;
that's worth adding once real corpus names make it clear what a sane
practical bound is, rather than guessing one now.

## The core design principle

> The model never gets to turn a semantic guess directly into an
> irreversible namespace operation.

Concretely: Granite may produce a `ModelResponse` with `object_type`,
`confidence`, and `candidate_names`. It may never itself write a
`GlossferoName` with `status: "assigned"`, never itself emit
`MigrationExecuted`, and never itself call Git. Every irreversible action in
the system is either a deterministic function of measured facts or requires
a `HumanReviewAccepted` event in the ledger.
