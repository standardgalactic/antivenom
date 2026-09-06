# Spine: ch074 — Update Budgets

**Volume:** VII: Formal Synthesis
**Part:** XIII. A Mathematics of Disciplined Distrust
**Status:** spine

**AFF-Net case:** Load-bearing — gives the AFF-Net analogy its full mathematical development (update budget D <= B(E_t)). Cross-reference the other two AFF-Net chapters (ch044, ch086) in "Depends on" / "Downstream chapters" as appropriate — this case spans three chapters and the ledger tracks it as one cross-cutting item.

## Claim
An institution's permitted belief-state revision on new evidence $E_t$ is bounded by $D(\Theta_{t+1},\Theta_t) \le B(E_t)$, where $B$ increases with provenance, independence, replication, representativeness, contextual integrity, and adversarial survival of $E_t$ — giving ch044's AFF-Net analogy its full mathematical development.

## Depends on
- ch044 (Due Process as Constrained Updating) — informal statement of the update-budget idea this chapter formalizes
- ch073 (Evidentiary Reach) — defines $\mathcal{R}(E)$, used to construct $B(E_t)$
- ch072 (Premature-Collapse Loss) — the loss framework this budget is designed to minimize

## Load-bearing steps
1. Treat institutional belief revision as bounded rather than free: an unconstrained update would let any new evidence $E_t$ drive $\Theta_{t+1}=\arg\min_\Theta L(E_t;\Theta)$, regardless of how narrow or unrepresentative $E_t$ is.
2. Define an update budget $B(E_t)$ that increases with $E_t$'s provenance, independence, replication, representativeness, contextual integrity, and adversarial survival — the same properties ch073's evidentiary-reach set $\mathcal{R}(E)$ already tracks.
3. Impose the constraint $D(\Theta_{t+1},\Theta_t)\le B(E_t)$, so permitted institutional movement is proportional to how far the evidence's tested reach extends, not to its vividness or salience.
4. Show that this budget formalism is the mathematical completion of ch044's informal claim that due process constrains the update rule rather than protecting the prior itself.
5. Argue that a well-tested, high-reach body of evidence can still license large revision — including reversal of precedent — because $B(E_t)$ grows with reach; the budget restricts unearned revision, not revision as such.

## External cases / technical analogues

| Case | Role | Note |
|---|---|---|
| AFF-Net (adapter-based fine-tuning under scarce, noisy medical-imaging data) | Load-bearing | Supplies the empirical pattern — constrained update ($D\le B$) outperforming unconstrained update — that motivates treating $B(E_t)$ as principled rather than as an ad hoc penalty. Presented in its own technical terms in ch086; the institutional analogy is drawn informally in ch044 and formalized here. |

## Objections this chapter must survive
- **Objection:** Defining $B(E_t)$ by provenance, independence, replication, representativeness, and adversarial survival looks like a list assembled to fit the desired conclusion — nothing prevents an institution from setting these weights so as to protect whatever prior it already prefers.
- **Response:** The chapter must therefore specify $B$ independently of any particular $\Theta_t$ or preferred outcome — the budget is a property of the evidence's tested reach (via $\mathcal{R}(E)$, defined without reference to the institution's current belief), not a free parameter tuned per case. Where an institution cannot state $B(E_t)$ in advance of seeing which conclusion it favors, the constraint has collapsed back into unconstrained discretion, and this chapter's claim fails on that instance — an honest limit, not a hidden escape hatch.

## Downstream chapters that depend on this one
- ch101 (Procedural Regularization) — converts this budget formalism into institutional design principles for high- versus low-impact decisions

## Formal result labels
- `$\Theta_{t+1}^{\mathrm{free}}=\arg\min_\Theta L(E_t;\Theta)$` — `\ToyModel`
- `$D(\Theta_{t+1},\Theta_t)\le B(E_t)$` — `\ProposedTheorem`

## Cut candidates
The full derivation connecting $B(E_t)$ to $\mathcal{R}(E)$ term-by-term could compress to a citation of ch073 if the book runs long; the budget inequality $D(\Theta_{t+1},\Theta_t)\le B(E_t)$ itself is not a cut candidate since ch101 depends on it directly.

## Note added after Appendix A drafted
Appendix A section A.45 already supplies the proximity-regularizer form $\Omega(\theta)=\|\theta-\theta_0\|^2$ and the declining-$\lambda$ condition $d\lambda/dQ<0$ that this chapter's $D(\Theta_{t+1},\Theta_t)\le B(E_t)$ formalism should build on or explicitly extend — check for redundancy vs. genuine extension before drafting this chapter's prose. A.57 (Premature-Collapse Loss) and A.65 Proposition A.10 are also directly relevant and should be cited rather than re-derived.
