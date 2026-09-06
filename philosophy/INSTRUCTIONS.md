# How this project is built

## Order of operations, per chapter
1. **Outline entry.** Title, part, one-line description goes in the
   ledger's Full chapter table. Status: `outline`.
2. **Proof spine.** Copy `proof-spines/_template.md` to
   `proof-spines/ch###-spine.md`. Fill in Claim, Depends on,
   Load-bearing steps, External cases, Objections. Do not write prose
   yet. Status: `spine`.
3. **Cross-check dependencies.** Every "Depends on" entry in the new
   spine should produce a matching "Downstream chapters" entry added
   to the upstream chapter's spine. Update the ledger's chapter table
   with the dependency.
4. **Prose.** Copy `chapters/_template.tex` to `chapters/ch###.tex`.
   Write directly against the spine's numbered steps, one step per
   paragraph or subsection as a default (deviate when the material
   genuinely calls for it, but a spine step that never surfaces in
   the prose at all is a sign either the spine or the chapter drifted
   — reconcile them, don't let them diverge silently).
5. **Add the \input line** to `power-of-paranoia.tex` under the
   correct `\part`. Status: `prose`.
6. **Review.** Apply the same review-and-integrate pattern already
   used on the essay's shorter companion pieces: get substantive
   correction on claims, citations, and overclaiming, then fold
   accepted corrections directly into the chapter text (not into a
   separate errata section). Status: `reviewed`.
7. **Freeze** once no further correction rounds are planned for that
   chapter. Status: `frozen`.

## Why the spine exists as a separate artifact from the prose
The spine is the actual argument. The prose is that argument made
readable. Keeping them separate means:
- A chapter can be evaluated for soundness (does the Claim follow
  from the steps? are the objections really answered?) without
  wading through paragraphs of exposition.
- If the book is later shortened, cutting works from the spines'
  "Cut candidates" and "load-bearing vs. illustrative" markings
  rather than re-reading and re-judging finished prose under time
  pressure.
- Dependencies between chapters are explicit and auditable instead
  of implicit in cross-references buried in prose.

## Load-bearing vs. illustrative, applied consistently
A technical case (AFF-Net, or whatever else gets pulled in later) is
**load-bearing** only if the chapter's Claim would need a different
argument without it — not merely a different example. If the same
point could be made with a different case, or with no case at all and
slightly more abstract argument, it's **illustrative**, and it's the
first thing that goes if the chapter runs long or the book needs
shortening. Mark this honestly in the spine's External cases table;
optimistic marking here is what makes a later shortening pass
slow and contentious instead of mechanical.

## Foundational chapters get extra scrutiny
A chapter with no "Depends on" entries is foundational — everything
downstream inherits its claim without re-arguing it. Foundational
chapters should reach `reviewed` status before the ledger considers
the surrounding part's other chapters safe to draft in earnest,
since a correction to a foundational claim can force respines
several chapters downstream.

## Batch intake of the outline
Since the full 110-chapter outline will likely arrive in pieces
rather than all at once: as each batch comes in, populate the
ledger's Full chapter table and the `\part` structure in the main
`.tex` file first (titles and ordering), before drafting any spines.
This keeps the book's overall shape visible and lets dependencies
across parts get flagged early, rather than discovered chapter by
chapter.
