# Spine: ch007 — Provenance and the Chain of Transformation

**Volume:** I: The Epistemology of Suspicion
**Part:** II. Events, Records, and Reconstructions
**Status:** spine

## Claim
Provenance is a chain-of-transformation problem best modeled over paths in a custody graph, with confidence tracking the integrity measure \(I(p)=\prod_{j=1}^{k} r(e_j)\) rather than the final artifact alone.

## Depends on
- ch006 — records are mediated traces whose evidential force depends on how they were produced rather than on simple identity with the event.

## Load-bearing steps
1. The chapter models provenance as a directed acyclic graph of transformations and custody relations, so confidence is assigned to a path rather than merely to a source label.
2. For any path \(p=(e_1,\ldots,e_k)\), it introduces the provisional integrity measure \(I(p)=\prod_{j=1}^{k} r(e_j)\) with \(r(e_j)\in[0,1]\) tracking the reliability of each transformation.
3. That formalism explains why observation, storage, transmission, editing, and retrieval must each be evaluated as possible points of evidential degradation or reframing.
4. The chapter then limits naive multiplicative trust by noting correlated failure and common-source dependence, which force provenance analysis beyond simple path multiplication.

## External cases / technical analogues

| Case | Role | Note |
|---|---|---|
| Legal chain-of-custody records for physical evidence | Illustrative | Provides a familiar model of why evidential value depends on documented handling, not mere origin. |
| File metadata and version history for a digital document | Illustrative | Shows how digital provenance can clarify transformations that a static file cannot reveal on its own. |

## Objections this chapter must survive
- Full provenance is rarely available, so making credibility depend on transformation history imposes an unrealistically high evidential standard that most real records cannot meet.
- Response: provenance is a comparative discipline, not an all-or-nothing demand; partial chain visibility can still justify better-calibrated confidence than source trust alone.

## Downstream chapters that depend on this one
-

## Cut candidates
The stage-by-stage catalog can be tightened, and one of the two provenance examples can be dropped without harming the core argument.
