# The Popo Naming Grammar

This document formalizes what earlier drafts of this project treated too
narrowly as "the five Glossfero object types." That framing was wrong, or
at least incomplete: `.bubble`, `.sphere`, `.object`, `.text`, and
`.cloak` are not an exhaustive ontology of file/repository kinds. They are
members of a small, open-ended vocabulary belonging to a naming and
control language — "Popo" — whose actual purpose is to keep ordinary
names ordinary for as long as possible, and to introduce marked forms
only when ordinary naming stops being sufficient. Popo is fundamentally
an **anti-collision and exception language**, not a type system.

## 1. The escalation hierarchy

Naming a new object, or renaming one to resolve a collision, proceeds
through an ordered sequence of increasingly marked forms. Each tier is
tried before the next; skipping ahead is a failure of the naming
procedure, not a stylistic choice:

```
ordinary name ≺ ordinary disambiguation ≺ semantic synonym ≺ descriptive affix ≺ Popo operator
```

**Ordinary name.** A single, unmarked dictionary word or short phrase:
`garden`. This is always the first attempt.

**Ordinary disambiguation.** If the name is already taken by something
*different* (not a duplicate, a genuinely distinct object), and a
compositional qualifier accurately describes the distinction, use it:
`constraint-closure-note`, `constraint-closure-slides`. These qualifiers
are ordinary words in a dash-composed chain — they are part of the
object's identity, not a marker of collision-handling machinery. See §3
for why this matters grammatically.

**Semantic synonym.** If no compositional qualifier is available or
appropriate — the new object is not a variant of the existing one, it's
simply a different thing that happens to want the same word — try another
ordinary word that still accurately describes it: if `garden` is taken,
try `grove`, `orchard`, or `nursery`, whichever actually fits. This is
still an ordinary name; it just isn't the first one tried.

**Descriptive affix.** Only once ordinary semantic discrimination
(disambiguation and synonymy) is genuinely exhausted, append one of a
small closed vocabulary of terminal type markers that describe *what
kind of thing* the object is at a structural level:
`constraint-closure.bubble`, `constraint-closure.object`. As of this
document, that closed vocabulary is:

| Affix | Meaning |
|---|---|
| `bubble` | locally closed, small subsystem |
| `sphere` | larger coherent system containing related components |
| `object` | executable or computational artifact |
| `text` | documentary, textual, scholarly, or corpus artifact |

(`cloak` has been removed from this table — see §4.)

**Popo operator.** A terminal marker that says nothing whatsoever about
the object's content or kind, and everything about how the object should
currently participate in some operation. This is the tier `.cloak` and
extreme escape markers like `.pleasecallmenow` belong to. See §3–§5.

The ordering is a safety property, not a preference: a system that reaches
for a descriptive affix or a Popo operator before exhausting ordinary
naming has given up too early, and a system that reaches for a numeric
suffix (`garden-2`, `document (1)`) has not resolved the collision at
all — see §6.

## 2. Formal grammar

```
N ::= w | N "-" w                      (ordinary semantic names)
F ::= N ( "." D )* ( "." A )? ( "." O )*   (full names)
```

where:

- `w` is an ordinary word or short token (lowercase, per the existing
  `semantic_root` pattern in `spec/schemas/glossfero_name.schema.json`,
  which already permits the dash-composition `N` requires — no schema
  change needed for `N` itself).
- `D` (discriminator) is zero or more ordinary-word segments in a chain,
  each further narrowing identity: `foo.parser.compat` has two
  discriminator segments, `parser` and `compat`. Discriminators are
  open vocabulary — any word that genuinely distinguishes the object is
  admissible; there is no fixed list.
- `A` (descriptive affix) is **at most one** terminal marker from the
  closed table in §1.
- `O` (Popo operator) is zero or more terminal markers from an open but
  curated vocabulary (§4), applied *after* any descriptive affix.

`N` and `D` and `A` all contribute to what the object **is**. `O`
contributes nothing to identity and everything to how the object
currently **participates** in some operation. This is the grammatical
distinction formalized in §3.

Ordinary, non-Glossfero file-format extensions (`.txt`, `.py`, `.md`)
compose into this grammar the same way any other segment would —
`chapter-seven.txt` is `N = chapter-seven` with `.txt` best read as part
of the base name for Glossfero's purposes, since `.txt` is a filesystem
convention Glossfero doesn't own and shouldn't reinterpret. `.cloak`
appended after it (`chapter-seven.txt.cloak`) is `O`, appended to
whatever came before regardless of whether that was a bare name, a
descriptive affix, or an ordinary extension.

## 3. Two grammatical positions, not one

Everything in `N` and `D` is a **noun modifier**: it contributes to the
object's ordinary identity, the way `-note` and `-slides` do. Everything
in `O` is an **operator**: a predicate applied to the object that governs
its participation in some currently-relevant operation, and asserts
nothing about its content.

This distinction is why `.cloak` cannot mean both "this is a compatibility
layer" (a noun-modifier claim about identity) and "exclude this from the
current scan" (an operator claim about participation) at the same time.
Those are different grammatical positions even though they can occupy the
same textual slot. §4 resolves the conflict in favor of the operator
reading.

## 4. Resolving the `cloak` conflict

An earlier draft of `spec/schemas/glossfero_name.schema.json` defined
`cloak` as a descriptive `object_type`: "overlay, adapter, projection,
compatibility, or interface layer." That definition is superseded by this
document. `cloak` is a **Popo operator**, not a descriptive affix, defined
precisely as:

```
cloak(x)  ⇒  x ∉ Q
```

for whatever quantified operation domain `Q` is presently in force — "all
recognized text documents this script processes," "all repositories in
this scan," etc. Marking an object `.cloak` asserts nothing about what
`x` is; it asserts only that `x` is presently excluded from `Q`. The
canonical example: temporarily renaming `chapter-seven.txt` to
`chapter-seven.txt.cloak` to exclude it from a batch text-processing
operation, then removing the suffix afterward to restore it.

If a system genuinely needs to describe an object as an
adapter/compatibility/interface layer, that is ordinary descriptive
work belonging to `N` or `D` (`foo-compat`, `foo.compat`) — not a
reserved terminal affix. Nothing about the escalation hierarchy in §1
required a dedicated closed-vocabulary word for "compatibility layer" in
the first place; `compat` as an ordinary discriminator does the same job
without colliding with an operator.

**This is a breaking change to `spec/schemas/glossfero_name.schema.json`
as currently written**, not just a documentation fix, and it is being
recorded here rather than silently patched into the schema in the same
pass that introduces it. See §7 for exactly what changes and what it
costs.

## 5. Operator vocabulary

Popo operators are open-ended by design — new ones get added as real
needs arise, the way `.pleasecallmenow` and `.thisisanemergency` arose
directly from the worked examples in this discussion, not from advance
planning. Two operator sub-kinds have appeared so far:

**Domain-exclusion operators** remove `x` from a quantified operation
domain without asserting anything about content. `cloak` is the first and
so far only member of this sub-kind.

```
cloak(x)  ⇒  x ∉ Q
```

**Escalation operators** mark `x` for immediate human attention,
independent of any quantified operation. `pleasecallmenow` and
`thisisanemergency` are of this kind:

```
escalate(x, urgency)  ⇒  requires_immediate_human_attention(x)
```

Modern filesystems impose no meaningful length limit on an extension (see
`spec/invariants/invariants.md`'s note on this), so an escalation operator
being a long, plain-English phrase is a feature, not friction — the
filename itself is legible to a human without needing to consult a
lookup table of operator abbreviations.

This document does not attempt to enumerate every operator that will ever
exist. It fixes the *shape* (a terminal, content-agnostic predicate) and
the two sub-kinds observed so far; new operators are added by stating
their formal predicate here, the same way `cloak` and `escalate` were
just stated, not by ad hoc convention.

## 6. Collision resolution vs. collision postponement

A duplicate name can be handled in one of two fundamentally different
ways, and only one of them actually resolves anything:

**Collision postponement** records that a collision happened without
understanding it: `document (1)`, `document (2)`, `paper-copy`,
`paper-copy-2`, `final-final`. The Android-style `document (1)` pattern is
the canonical pathology — the numeral carries no information about what
distinguishes the two objects, only that a naming system once failed to
figure it out.

**Collision resolution** replaces postponement with an answer, using the
escalation hierarchy in §1: `paper-slides` resolves what `paper (1)`
merely postponed, because the distinction (this one is the slides) has
become legible in the name itself.

### The number-pop maintenance procedure

This distinction gives Popo its first concrete maintenance operation,
informally named the **number-pop pass**:

1. **Discover** postponement debris: names matching numeric-collision
   patterns (` (1)`, ` (2)`, `-copy`, ` copy 2`, `-final`,
   `-final-final`, and similar).
2. **Classify** each: is the duplicate actually redundant (byte-identical
   or near-identical content, checked via the fingerprint cascade in
   `spec/protocol/protocol.md` §2), or does it represent a genuine
   distinction that was never named?
3. **If redundant:** merge or delete per the ordinary duplicate-handling
   rules elsewhere in this project (see `CollisionResult` classifications
   in `spec/schemas/collision_result.schema.json` — this is exactly what
   `SEMANTIC_DUPLICATE` and `MERGE_CANDIDATE` are for).
4. **If genuinely distinct:** discover the real distinction and rename
   through the escalation hierarchy — ordinary disambiguation first,
   synonym substitution second, descriptive affix only if neither
   applies. Never reintroduce a numeric suffix as the resolution.

A number-pop pass is a reasonable candidate for an early, high-value
Glossfero maintenance command (`glossfero number-pop <path>` or similar)
precisely because it requires no semantic understanding of the *content*
of the objects involved to detect the debris — only the naming pattern —
even though resolving what it finds does require the fuller pipeline.

## 7. The formal safety property

The reason any of this matters beyond taxonomy: Popo operators exist to
make broad, universally-quantified operations expressible and safe under
local exception, without needing per-operation special-case logic baked
into every script that walks a repository:

```
∀x ∈ R,  ¬cloak(x)  ⇒  process(x)
```

Instead of abandoning a broad operation because one exceptional object
would break it, or writing bespoke exclusion logic into every script that
needs it, the exception is marked locally on the object itself, once, and
every operation that respects the `cloak` convention is automatically
safe. This is the actual design point of the whole naming layer — it is
not a taxonomy problem being solved by clever suffixes, it is a
uniform-quantification-under-exception problem being solved by a
lightweight, filesystem-native marking convention.

## 8. Four signals, not one

The `.cloak` mechanism in §4 and a mechanism running in the opposite
direction — appending `.txt` to `notebook.ipynb` so a phone with no
`.ipynb` handler will expose it through generic text affordances — turn
out to be the same underlying phenomenon read in two directions. Neither
changes what the file *is*. Both change how some environment currently
*treats* it. Once that's visible, it's clear this document had been
running together several genuinely independent signals a filename can
carry:

```
content identity  ≠  dispatch hint  ≠  operational treatment  ≠  preservation status
```

**Content identity** is what the object actually is — LaTeX source, a
Jupyter notebook, a JSON document. Nothing in a filename changes this;
renaming `chapter.tex` to `chapter.tex.cloak` does not turn LaTeX into
something else.

**Dispatch hint** is a claim about which handler or affordance to route
the object through *in a particular environment*, independent of content
identity. `notebook.ipynb.txt` is dispatch widening: expose an IPYNB
document through the generic text affordances of a platform that has no
registered `.ipynb` handler at all. The terminal `.txt` here does not
assert "this is plain text" — it asserts "treat this as text," which is a
different speech act.

**Operational treatment** is `.cloak`'s actual job: whether the object
currently participates in some quantified operation (§7). This is
dispatch narrowing in the opposite direction from the `.txt` case — not
"let more things recognize this," but "let this specific operation
ignore it."

**Preservation status** constrains permissible *transitions* on the
object rather than saying anything about interpretation at all — see
§11.

Windows' file-association model and, more starkly, mobile platforms that
refuse to recognize any extension outside a fixed registry, both build on
a convention that a file has exactly one name, and that name determines
exactly one owning application. That convention answers "what application
owns this kind of filename?" Popo needs to answer a different question:
"what affordance do I want for this object, in this operation, right
now?" A single `.tex` file can simultaneously be LuaLaTeX source, ordinary
UTF-8 text to a plain editor, input to a summarizer, something Git
versions, and something one specific batch job must presently skip. No
one of those exhausts what the file is, and Popo should not force a
choice among them.

## 9. The evidence ladder

Filename evidence is cheap and defeasible, not authoritative. Unix's
hashbang line is the precedent worth generalizing from: the kernel
doesn't trust an executable's name at all, it inspects the first line for
a stronger, corroborating (or contradicting) signal — and even that
doesn't constitute full understanding of the program. This generalizes to
a layered evidence ladder, each layer a progressively more expensive and
more reliable hypothesis about an object, never a replacement for what
came before:

| Layer | Evidence |
|---|---|
| `E0` | name |
| `E1` | extension chain |
| `E2` | metadata |
| `E3` | magic bytes / hashbang / header |
| `E4` | structural parse |
| `E5` | documentation |
| `E6` | whole-object interpretation |

`foo.py` (`E1`) is evidence that something should be treated as Python. A
Python hashbang (`E3`) corroborates it independently. Actually parsing the
file (`E4`) is much stronger evidence still. Understanding what the
program *does* (`E6`) requires going further yet, and nothing below `E6`
is entitled to claim it. The point of naming this ladder explicitly is
that Glossfero's own pipeline already climbs it without having said so:
`RepoRecord.fingerprints` moves from `name` (`E0`/`E1`) through
`manifest`/`structural` (`E2`) to `semantic` (`E4`–`E6`) exactly on this
principle, per the fingerprint cascade in `protocol.md` §2 — cheapest
layer first, later layers consulted only when an earlier one leaves the
question open.

## 10. Objects as predicate sets, not single types

Given §8 and §9, a Glossfero object should not be modeled as having one
type. It should be modeled as a set of independently-established
predicates, each traceable to the evidence layer that established it.
Conflicting-looking extensions are not actually conflicts once this is
taken seriously. `experiment.json.txt` inspects as:

```
physical name:       experiment.json.txt
terminal dispatch:    text
embedded format:      JSON
content validation:   valid JSON
requested treatment:  generic text
```

`.json` describes a representation; terminal `.txt` supplies an
affordance for an environment that would otherwise fail to expose the
file at all. Neither claim needs to yield to the other. Likewise
`paper.tex.cloak`:

```
content:              LaTeX
ordinary identity:     paper
operation modifier:    cloak
current treatment:     excluded
```

The general form is a predicate set, each member tagged with the evidence
layer that grounds it:

```
x : { Text, LaTeX, Editable, Versioned, Summarizable, Cloaked_Q }
```

**This means "the last extension tells you what the file is" is
explicitly rejected as a universal rule.** The terminal component of a
name retains precedence only for *cheap dispatch* — it is what a
lightweight tool consults first, per `E0`/`E1` — and stronger inspection
at `E2` and beyond can refine or outright contradict it without that
being an error condition. Polymorphism is not an edge case Popo has to
tolerate; under this model it is the ordinary case, and a system that
insists an object have exactly one type is the one making an unjustified
assumption.

## 11. Read-only and the transition relation

A preservation marker such as a read-only flag is a different kind of
claim from everything above: it says nothing about what `x` is or how it
should be dispatched, and instead constrains which transitions are
admissible:

```
readonly(x)  ⇒  x_t ↛ x_{t+1}
```

for unauthorized content mutation. This is genuinely independent of the
predicate-set membership in §10 — an object can be `{ Text, LaTeX,
Cloaked_Q }` and separately `readonly`, and neither fact is derivable
from the other. It also composes usefully with everything else in this
document: a repository-wide operation can claim not merely "I have
classified this object as outside the mutation domain" (a Popo-level,
filename-driven claim) but "...and the filesystem independently enforces
that," which is a materially stronger guarantee than either constraint
offers alone — trusting one representation of intent less than two
independent constraints that happen to agree is the same discipline this
project's constraint-first orientation applies elsewhere.

## 12. Consequences for `CLASSIFY OBJECT TYPE`

`spec/protocol/protocol.md`'s pipeline currently names a stage `CLASSIFY
OBJECT TYPE`, singular, feeding a single `object_type` field. §10 means
that stage name is now aspirational at best and actively misleading at
worst: what the stage should produce is closer to a predicate set with
per-predicate evidence provenance than a single classification. This
document does not rename the pipeline stage or redesign
`CollisionResult`/`Proposal` around a predicate-set model — that is
strictly more invasive than the schema migration §13 already scopes, and
deserves its own deliberate pass with its own explicit confirmation, not
one folded into a naming-grammar document. It is recorded here so the
gap is visible rather than silently inherited by whichever backend
implements `CLASSIFY OBJECT TYPE` first.

## 13. What this changes, concretely

This document supersedes the following, which have not yet been updated
to match it (deliberately — see the note in this project's README about
sequencing spec changes before implementation changes):

- **`spec/schemas/glossfero_name.schema.json`** needs, at minimum:
  - `cloak` removed from the `object_type` enum (now 4 values, not 5).
  - `discriminator` (currently a single nullable string) generalized to
    a `discriminators` array, to support the `D*` chaining this document
    formalizes (`foo.parser.compat`, two discriminator segments).
  - A new `operators` array field (open vocabulary, no enum constraint
    beyond a naming pattern), to hold `O*`.
  - `full_name`'s construction rule updated to
    `semantic_root ("." discriminator)* ("." object_type)? ("." operator)*`.
  - **Possibly more than that**, per §10–§12: if `GlossferoName` is meant
    to actually reflect the predicate-set model rather than just gain
    `discriminators`/`operators` arrays alongside a still-singular
    `object_type`, that's a materially larger schema redesign
    (`object_type` becoming a set of evidence-tagged predicates rather
    than one enum value) that this document deliberately does not force
    a decision on yet — see §12.
- **`elm/src/Glossfero/Types.elm`** carries the same stale `cloak`
  description as the schema (`"cloak: overlay, adapter, ..."`) and needs
  the corresponding structural updates once the schema changes.
- **`rust/`, `haskell/`, `python/`, `clojure/`** don't yet have
  `GlossferoName` types implemented at all (none of the four have reached
  NAME in the pipeline), so there is no existing code to migrate there —
  but whichever backend implements NAME first should build directly
  against the *revised* schema, not the one this document just
  superseded.
- **The golden `repo-small-001` fixture's `expected.glossfero_name.json`
  and `expected.proposal.json`** remain valid in *content* under the new
  grammar (`parser.bubble` is simply the trivial case: no discriminators,
  no operators) but would need their literal JSON shape updated
  (`discriminator: null` → `discriminators: []`, plus a new `operators:
  []` field) to match the revised schema, which in turn changes the
  canonical bytes and therefore the ledger's `payload_hash` values for
  every event that embeds a `GlossferoName`.

None of the above has been executed yet. This document is the proposal;
the schema/fixture migration is deliberately a separate, explicitly
confirmed step, consistent with the naming resolution rule's own
principle in `spec/invariants/invariants.md` that a non-default
resolution "must be a recorded, deliberate exception" — the same
discipline applies to changing the naming system itself.
