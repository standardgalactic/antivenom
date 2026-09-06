# Spine: ch044 — Due Process as Constrained Updating

**Volume:** IV: Law as an Epistemic Machine
**Part:** VIII. Legal Friction as Freedom
**Status:** prose-drafted

**AFF-Net case:** Load-bearing — introduces the AFF-Net analogy for constrained institutional updating, informally (formal treatment deferred to ch074). Cross-referenced with ch074 (Update Budgets, full mathematical development), ch086 (Medicine and Scarce Data, original technical context presented before the analogy), and now Appendix A section A.45 (Regularization and constrained updating, prose-drafted, gives the $\Omega(\theta)=\|\theta-\theta_0\|^2$ proximity-regularizer form) and A.46 (Feature drift and institutional drift). This case now spans four locations; the ledger tracks it as one cross-cutting item.

## Claim
Due process functions not by protecting an existing prior (precedent can encode systematic error) but by constraining the *update rule* itself, so that new evidence revises institutional judgment only in proportion to its tested evidentiary reach rather than its vividness.

## Depends on
- ch041 (The Inconvenience Principle) — friction parameter concept this chapter specializes
- ch035–ch040 (Part VII, Evidence Before Action) — the admissibility/proof architecture that constrained updating operates on top of
- ch086 — should ideally be read first for AFF-Net's original technical context, though the chapter is written to stand alone with a citation

## Load-bearing steps
1. Unrestricted fine-tuning of a large pretrained model on a small, scarce dataset produces feature drift: the model reorganizes broadly-acquired representations around the accidental regularities of the small sample. [AFF-Net technical result, detailed in ch086]
2. AFF-Net's empirical result: a constrained adapter-based update (only ~20% of backbone parameters updated) outperforms full fine-tuning specifically under scarce, noisy data — the constraint is not a compromise that costs performance, it is what prevents a worse outcome.
3. This shows the failure mode is not "the prior was wrong and should have been overwritten" but "the update magnitude was unconstrained given how little evidence justified it."
4. Institutional judgment updating on an early recording, witness statement, or accusation is structurally the same problem: a small, possibly unrepresentative sample of evidence, arriving with high salience, that could in principle reorganize the entire interpretive structure if nothing constrains the update.
5. Due process mechanisms (standards of evidence, cross-examination, precedent, disclosure, appeal) are the adapter constraint: they force new evidence to survive contact with a larger body of accumulated structure before it is permitted to revise judgment, without claiming that structure is infallible.
6. Therefore the value of due process's "inconvenience" is not defending the status quo prior — it is enforcing proportionality between the size/vividness of new evidence and the size of the institutional revision it is permitted to cause.

## External cases / technical analogues

| Case | Role | Note |
|---|---|---|
| AFF-Net (adaptive feature fusion, medical image segmentation, adapter-based fine-tuning) | Load-bearing | Supplies the mechanism (constrained update outperforming unrestricted update under scarce data) that step 3 depends on; without it, step 3 is an assertion rather than a demonstrated result. Formal $D(\Theta_{t+1},\Theta_t) \le B(E_t)$ treatment lives in ch074. |

## Objections this chapter must survive
- **Objection:** The precedent-as-prior framing seems to assume the inherited structure is worth protecting; but the whole point of reform movements is that precedent can be systematically wrong for a long time before it's corrected. Doesn't "constrain the update rule" just mean "protect bad priors more slowly"?
- **Response:** No — the claim is explicitly not that the prior is protected, but that *update magnitude* is proportional to *tested reach* of new evidence. A well-tested, high-reach body of new evidence (a pattern established across many cases, not one vivid incident) is precisely what should and does eventually produce large revision — including overturning precedent. What the constraint prevents is a *single, untested, high-salience* sample producing a *large* revision before its representativeness is known. The mechanism is agnostic about which direction the correct revision runs; it only restricts revision size to evidentiary reach, in either direction.
- **STILL TO DRAFT IN PROSE:** this response is logged here but the chapter text currently only flags it as a TODO comment — needs full paragraph treatment before status can move to `reviewed`.

## Downstream chapters that depend on this one
- ch073 (Evidentiary Reach) — formalizes "tested evidentiary reach" used informally here
- ch074 (Update Budgets) — gives this chapter's $D(\Theta_{t+1},\Theta_t) \le B(E_t)$ full treatment
- ch101 (Procedural Regularization) — converts this chapter's adapter analogy into institutional design principles

## Formal result labels
- Unrestricted one-shot updater $\Theta_{t+1} = \arg\min_\Theta L(E_t;\Theta)$ — `[Toy model]`
- Regularized due-process updater $\Theta_{t+1} = \arg\min_\Theta \left[ L(E_t;\Theta) + \lambda D(\Theta,\Theta_t) + \gamma C(\Theta) \right]$ — `[Toy model]`

## Cut candidates
If shortened: the AFF-Net technical mechanism (steps 1–2) could compress to a one-sentence citation of the empirical result rather than walking through feature drift explicitly. The chapter's core claim (steps 3–6) is not itself a cut candidate — it is one of the book's named formulations of the central thesis (see closing line, echoed in the Conclusion).
