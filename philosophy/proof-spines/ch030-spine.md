# Spine: ch030 — The Mosaic Problem

**Volume:** III: Attention and Publicity
**Part:** VI. Privacy as Boundary and Capacity
**Status:** spine

## Claim
The mosaic problem is the nonadditivity of privacy risk, formalized by \(R(D_{1:n})=\sum_i R(D_i)+\sum_{i<j} I_{ij}+\sum_{i<j<k} I_{ijk}+\cdots\), where synergistic inference terms make composition invasive.

## Depends on
- ch029 — privacy concerns the maintenance of boundaries that protect agency and role-differentiated life, not just the concealment of secrets.

## Load-bearing steps
1. The chapter denies that aggregate exposure is additive by showing that generally \(R(D_1\cup\cdots\cup D_n) \neq \sum_i R(D_i)\).
2. It expands combined risk as \(R(D_{1:n})=\sum_i R(D_i)+\sum_{i<j} I_{ij}+\sum_{i<j<k} I_{ijk}+\cdots\), where each \(I\)-term captures synergistic inference unavailable from isolated records.
3. Those interaction terms explain why no single datum need be sensitive for the assembled dossier to reveal intimate routines, relationships, or vulnerabilities.
4. Privacy harm therefore arises at the level of linkage, accumulation, and recombination, which turns mundane fragments into new causal and behavioral inferences.
5. Any adequate privacy doctrine must regulate inference over \(D_{1:n}\), not merely the release of each \(D_i\) taken one by one.

## External cases / technical analogues

| Case | Role | Note |
|---|---|---|
| Aggregated location data revealing home, work, worship, or medical routines | Illustrative | Shows how mundane traces become intimate when composed. |
| Surveillance-law “mosaic theory” | Illustrative | Supplies a ready analogue for composition producing a qualitatively new invasion. |

## Objections this chapter must survive
- Objection: if each datum was voluntarily shared or publicly observable, the resulting inference is fair game and creates no new privacy claim.
- Response: voluntariness attaches to local disclosures under particular expectations; the downstream mosaic creates a new access relation and a new power over the person that was never separately consented to.

## Downstream chapters that depend on this one
-

## Formal result labels
- aggregate privacy-risk expansion \(R(D_{1:n})=\sum_i R(D_i)+\sum_{i<j} I_{ij}+\sum_{i<j<k} I_{ijk}+\cdots\) — Toy model

## Cut candidates
Specific data-combination examples are reducible; the essential claim is that privacy harms emerge at the level of aggregation rather than single facts.
