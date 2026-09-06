# Design Principles — The Power of Paranoia

This document is a standing editorial reference, not a one-time note. Every
chapter, spine, and appendix should be checkable against it. If a chapter
violates one of these principles, that is a defect to fix, not a stylistic
preference to ignore.

Status: adopted (user-authored synthesis, pasted 2026-09-06). Supersedes
loose framing in earlier drafts wherever they conflict.

## 0. The governing thesis

The book does not argue that paranoia is generally good. It argues:

> Institutions need a controlled capacity to preserve suspicion without
> allowing suspicion to authorize coercion.

Central sentence, to remain visible throughout the project:

> The freedom created by law is the interval it preserves between an
> observation, an interpretation, and an authorized act.

## 1. Keep the argument narrower than the subject matter

Every chapter must advance at least one stage of the principal sequence:

\[
\text{Event} \to \text{Trace} \to \text{Record} \to \text{Evidence} \to
\text{Finding} \to \text{Authorization} \to \text{Consequence}.
\]

The book's subject is what can go wrong at these transitions and why
maintaining boundaries between them creates freedom. Material that does
not modify, test, or illustrate this sequence probably belongs elsewhere.

Test case: AFF-Net passes (clarifies constrained updating under scarce
evidence); Logic Gate Networks does not (connection is a structure–content
analogy only). Use this as the standard for admitting technical material.

## 2. Define paranoia with unusual precision

Distinguish at least three states, early (introduction):

\[
\begin{aligned}
\text{naivety} &: \text{the presented account is presumed sufficient},\\
\text{disciplined paranoia} &: \text{unrepresented causes remain possible},\\
\text{pathological paranoia} &: \text{every observation confirms hostile agency}.
\end{aligned}
\]

Disciplined paranoia requires three formal constraints:
1. It specifies what evidence would weaken its suspicions.
2. It assigns unequal plausibility to alternatives (not a flat prior over
   all conceivable hostile explanations).
3. It forbids converting mere possibility into punitive action.

The book's real subject is the institutional domestication of suspicion,
not a defense of generalized suspicion.

## 3. Preserve the privacy–publicity symmetry

Both privacy and publicity have protective and pathological forms. Do not
treat publicity as truth and privacy as mere concealment. Resist searching
for one optimal scalar "balance" — the two values act at different layers
(e.g., public procedure + private witness identity; public aggregate +
restricted raw record; confidential-until-adversarial-testing).

Preferred asymmetric principle over generic "balance":

\[
\text{publicity should increase with exercised power,}
\]
\[
\text{privacy should remain presumptively attached to persons.}
\]

## 4. Distinguish four kinds of delay

- **Procedural delay** — allows evidence to mature. The only kind
  inherently connected to epistemic restraint.
- **Capacity delay** — institutions lack investigators/expertise.
- **Strategic delay** — imposed by powerful actors hoping attention,
  witnesses, or resources disappear.
- **Pathological delay** — institutional indifference or dysfunction.

Whenever the book credits delay with protecting judgment, ask: what
evidentiary work occurs during the interval, who bears its costs, and is
there a specified route to completion? Otherwise the argument collapses
into a defense of bureaucratic inertia.

## 5. Treat mathematics as an instrument of discrimination, not decoration

A useful equation reveals a genuine distinction, threshold, dependency,
impossibility, or trade-off — e.g.

\[
P(H\mid E,M) \neq P(H\mid E)
\]

(dependence of posterior on model), or

\[
\operatorname{Recorded}(x) \centernot\Rightarrow \operatorname{Retrievable}(x)
\centernot\Rightarrow \operatorname{Recognized}(x)
\]

(preservation vs. institutional knowledge). Assigning symbols to "privacy,"
"freedom," "trust" and dropping them into an optimization formula is NOT
yet mathematics unless the quantities can be measured, ordered, or
operationally compared — otherwise label it structural notation, not a
calculational model.

**Every formal result must carry one of four labels:**
- `[Definition]` — fixes vocabulary.
- `[Toy model]` — illustrates a mechanism, not measured.
- `[Empirical model]` — describes/fits measured data.
- `[Proposed theorem]` — a claim requiring proof.

This labeling requirement applies retroactively — existing chapters/spines
should be audited and tagged, not just new material.

## 6. Use impossibility claims carefully

Maintain the conceptual hierarchy (not literally nested in every technical
sense, but ordered in strength):

\[
\text{unknown} \subsetneq \text{computationally expensive} \subsetneq
\text{practically intractable} \subsetneq \text{formally undecidable}
\]

Causal reconstruction difficulty may come from combinatorial search space,
missing records, strategic sources, or unknown models — none of these
alone proves undecidability. The book's political conclusion does not
need the strongest mathematical claim: law needs procedural restraint even
when truth is merely expensive and slow to obtain. Do not overclaim
undecidability/impossibility where "expensive" or "intractable" suffices.

## 7. Build the book around recurring cases

Prefer a small number of cases that recur under different mathematical
lenses over a large number of one-off examples. Suggested recurring case
types:
- An event recorded from thousands of angles but poorly reconstructed.
- An individual subjected to an automated classification.
- A historical event whose decisive evidence becomes salient decades later.

Each recurrence should add a distinct lens: probability (how beliefs
change), information theory (why the relevant feature was hard to locate),
causal inference (which histories remain compatible with the records),
queueing theory (delay), law (which conclusions authorize action),
continuation geometry (how provisional classifications become durable
consequences).

Prefer invented/composite cases in early theoretical chapters (readers
bring settled political commitments to famous controversies); introduce
historical/contemporary cases later, once vocabulary is established.

(AFF-Net is the book's existing running case, spanning ch044/074/086 and
Appendix A §§A.45-A.46 — this satisfies the recurring-case principle
already; it should be treated as the template for further recurring
cases, not replaced by them.)

## 8. Give the opposing argument its strongest form, throughout

The strongest objection: procedural caution often protects existing power.
Evidentiary requirements can make structural harms nearly impossible to
prove; privacy can shelter corporations, families, governments, closed
organizations; demands for context can become techniques for refusing to
recognize what is already evident.

This must NOT be confined to a single late "objections" chapter. Every
protective mechanism should be examined for its reversal, throughout:

\[
\text{presumption}\longleftrightarrow\text{immunity}
\]
\[
\text{privacy}\longleftrightarrow\text{concealment}
\]
\[
\text{delay}\longleftrightarrow\text{attrition}
\]
\[
\text{evidentiary rigor}\longleftrightarrow\text{unmeetable burden}
\]
\[
\text{finality}\longleftrightarrow\text{irreversible error}
\]

The book's achievement should be explaining when the same structure
changes political sign — not asserting the mechanism is always benign.

## 9. Separate belief repair from consequence repair

A false classification may already have altered employment, relationships,
search results, institutional records, future risk assessments, and the
interpretation of later behavior. Correcting the narrative does not
automatically repair these.

\[
\text{epistemic correction} \neq \text{institutional correction} \neq
\text{material repair}
\]

Retraction changes a proposition; repair must also traverse the dependency
graph created by the proposition. This is where continuation/reknotting
material (Volume on Dynamics/Geometry/Holonomy) makes its distinctive
contribution beyond ordinary misinformation discourse.

## 10. Do not make precedent equivalent to a good prior

A broad prior may encode accumulated knowledge, but precedent may also
encode accumulated exclusion. Due process = constrained updating, not
deference to inherited belief. Two-timescale model:

\[
\theta_{t+1} = \theta_t + \alpha\, g(E_t,\Phi_t),
\]
\[
\Phi_{t+1} = \Phi_t + \beta\, h(E_{1:t}), \qquad \beta \ll \alpha.
\]

Fast beliefs (\(\theta\)) respond to cases; slow structure (\(\Phi\))
responds to demonstrated patterns. If \(\Phi\) never changes, regularization
becomes dogmatism; if it changes with every event, the institution loses
continuity. (This already matches ch044/ch074's update-budget framing —
use it as the canonical statement of that model going forward.)

## 11. Keep chapters locally readable

A reader should not need to remember 600 pages of notation to understand
Chapter 73. Each chapter should:
- reopen with the concrete problem,
- introduce only the formalism needed there,
- conclude by stating exactly what has and has not been established.

Support multiple reading paths (legal reader skipping derivations,
mathematical reader following appendices/formal synthesis, a reader
following the admissibility/refusal/continuation/holonomy sequence).

**Requires a stable, book-wide notation ledger.** The same symbol must not
mean "evidence" in one part and "expectation" in another. Terms —
"record," "proof," "verification," "recognition," "admissibility,"
"authorization" — must not be used casually after their formal definition.
(No such notation ledger currently exists in this repo — see open items.)

## 12. Culminate in design principles, not just caution

The final movement must produce institutional consequences: preserve
provenance, disclose dependency among sources, type provisional findings,
distinguish flags from verdicts, record uncertainty, permit challenges to
the operative model, require stronger evidence for more irreversible
action, review continuing consequences, maintain routes for reopening
decisions when delayed evidence appears.

Closing synthesis sentence to anchor the book's ending:

> Privacy protects the person from compulsory total description. Publicity
> protects the public from concealed exercises of power. Due process
> protects the interval in which descriptions can be contested.
> Admissibility governs what may cross that interval, and continuation
> governs how long its consequences may remain in force.

---

## Open items raised by this document (not yet actioned)

- [ ] No book-wide **notation ledger** exists yet (Principle 11). Should be
  created (e.g. `notation-ledger.md`) and cross-checked against all 110
  chapters + appendices for symbol collisions.
- [ ] No chapter/spine currently tags formal results with
  `[Definition]/[Toy model]/[Empirical model]/[Proposed theorem]`
  (Principle 5). Would require an audit pass over all 110 chapters.
- [ ] The "reversal" pairs in Principle 8 (presumption↔immunity, etc.) are
  not yet systematically threaded through chapters outside their most
  obvious homes — currently concentrated in the objections sections of
  individual spines rather than recurring throughout.
- [ ] Delay taxonomy (Principle 4: procedural/capacity/strategic/
  pathological) is not yet explicit terminology in the delay-related
  chapters (Part IV, "Time, Delay, and the Maturation of Evidence") —
  worth auditing ch017-ch022 against it specifically.
- [ ] Three-state paranoia definition (Principle 2) should be checked
  against ch001-ch005 (Part I) framing to confirm the introduction
  actually states it this precisely.
