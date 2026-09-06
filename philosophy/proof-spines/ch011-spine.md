# Spine: ch011 — Causal Graphs and Expanding Neighborhoods

**Volume:** II: Causal Explosion
**Part:** III. The Combinatorics of Context
**Status:** spine

**Foundational chapter** — opens a new Part with no upstream dependency. Prioritize reaching `reviewed` status here before drafting later chapters in this Part in earnest.

## Claim
Causal attribution turns on the backward neighborhood \(B_k(v)\) inside a graph \(G=(V,E)\): as \(k\) expands, responsibility can shift until inquiry reaches a warranted stopping point.

## Depends on
- ch010 — reconstruction from partial traces is an inverse problem, so appearances do not reveal their own generating history or explanatory boundary.

## Load-bearing steps
1. Because an event is embedded in a graph \(G=(V,E)\), the salient node never arrives with its causal boundary already marked; inquiry must decide how much of the backward neighborhood \(B_k(v)\) is relevant.
2. Because \(|B_k(v)|\approx\sum_{j=0}^{k} b^j=(b^{k+1}-1)/(b-1)\), even modest branching factor \(b\) and depth \(k\) create a rapidly expanding candidate context rather than a tidy local story.
3. Because enlarging \(k\) can pull in mediators, background conditions, institutions, and omissions that redirect causal propagation, attribution can shift dramatically before the neighborhood is wide enough.
4. Because inquiry cannot traverse the whole graph, disciplined suspicion seeks the smallest expansion of \(B_k(v)\) after which further enlargement no longer materially changes responsibility under the stakes at issue.

## External cases / technical analogues

| Case | Role | Note |
|---|---|---|
| Industrial accident investigation | Illustrative | Useful for showing how operator error, maintenance schedules, and managerial incentives sit in one causal neighborhood. |
| Corruption scandal with intermediaries | Illustrative | Shows how institutions and brokers mediate a cause that first appears to be a single bad actor. |

## Objections this chapter must survive
- **Objection:** If every cause sits in an ever-larger graph, inquiry never knows where to stop, so the method collapses into paralysis or totalizing suspicion. **Response:** The chapter needs only a warranted neighborhood, not an infinite one; expansion is justified when it changes attribution under the stakes and mechanisms at issue.

## Downstream chapters that depend on this one
-

## Formal result labels
- \(B_k(v)=\{u\in V:d(u,v)\leq k\}\) — Definition
- neighborhood-growth approximation \(|B_k(v)|pprox\sum_{j=0}^{k} b^j=(b^{k+1}-1)/(b-1)\) — Toy model

## Cut candidates
Extended walk-throughs of any one multi-actor case are compressible once the rule for neighborhood expansion is clear.
