# Spine: ch071 — The Paranoia Functional

**Volume:** VII: Formal Synthesis
**Part:** XIII. A Mathematics of Disciplined Distrust
**Status:** spine

**Foundational chapter** — opens a new Part with no upstream dependency. Prioritize reaching `reviewed` status here before drafting later chapters in this Part in earnest.

## Claim
Disciplined distrust is formalized by the paranoia functionals $\mathcal P(E)$ and $\mathcal P_H(E)$, which measure how much alternative causal history responsibly remains live under evidence $E$.

## Depends on
- ch070 (Synthetic Evidence and Provenance Failure) — supplies the closing claim that in a provenance-fragile world appearances become evidence only through auditable pathways and institutional humility about underdetermination

## Load-bearing steps
1. Define the institutional paranoia level by $\mathcal P(E)=\sum_{H\in\mathcal H} w(H)\mathbf 1[H\text{ remains admissible under }E]$, so disciplined distrust is measured over candidate histories $\mathcal H$ rather than over isolated appearances.
2. Interpret $w(H)$ and the admissibility indicator as preserving live alternative causal histories when evidence $E$ has not actually ruled them out.
3. Introduce the entropy refinement $\mathcal P_H(E)=-\sum_{H\in\mathcal H} P(H\mid E)\log P(H\mid E)$ to capture posterior multiplicity even when histories are weighted probabilistically rather than admitted categorically.
4. Argue that a high value of $\mathcal P(E)$ or $\mathcal P_H(E)$ can represent evidentiary incompleteness rather than epistemic pathology.
5. Use these functionals as the formal objects on which later chapters impose premature-collapse loss, evidentiary reach, and bounded update rules.

## External cases / technical analogues

| Case | Role | Note |
|---|---|---|
| Provenance verification for synthetic media | Illustrative | Shows why the object of assessment must be a whole evidentiary posture rather than confidence in a single artifact. |

## Objections this chapter must survive
- **Objection:** Turning distrust into a functional falsely suggests that moral and political judgment can be reduced to a single numerical score, smuggling precision into what is really contestable interpretation.
- **Response:** The functional need only impose a comparative structure on belief states; it clarifies what must be balanced without claiming mechanical or perfectly cardinal measurement.

## Downstream chapters that depend on this one
-

## Formal result labels
- `$\mathcal P(E)=\sum_{H\in\mathcal H} w(H)\mathbf 1[H\text{ remains admissible under }E]$` — `\Definition`
- `$\mathcal P_H(E)=-\sum_{H\in\mathcal H} P(H\mid E)\log P(H\mid E)$` — `\Definition`

## Cut candidates
The synthetic-media bridge can compress to a brief reminder from ch070; the indispensable material is the definition of the functional and why its terms belong together.
