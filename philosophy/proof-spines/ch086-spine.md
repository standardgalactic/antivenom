# Spine: ch086 — Medicine and Scarce Data

**Volume:** VIII: Applications and Case Structures
**Part:** XV. Domains of Difficult Judgment
**Status:** spine

**AFF-Net case:** Illustrative-to-load-bearing bridge — presents AFF-Net in its original medical/technical context before ch044 draws the analogy. Cross-reference the other two AFF-Net chapters (ch044, ch074) in "Depends on" / "Downstream chapters" as appropriate — this case spans three chapters and the ledger tracks it as one cross-cutting item.

## Claim
AFF-Net's original technical result (constrained adapter fine-tuning outperforming full fine-tuning under scarce, noisy medical-imaging data) should be understood on its own terms, in its own domain, before ch044 draws the institutional analogy from it — presenting the mechanism straight first prevents the later analogy from reading as a forced or cherry-picked fit.

## Depends on
(none — this chapter should be readable independently of the rest of the book; it is the source material ch044 and ch074 draw on)

## Load-bearing steps
1. Present AFF-Net's technical setting on its own terms: medical-imaging segmentation with scarce, noisy, heterogeneous cohorts, where a large pretrained backbone must be adapted to a small target dataset.
2. Show that unconstrained full fine-tuning on such data produces feature drift — the model reorganizes its broadly learned representations around the accidental regularities of the small sample, degrading generalization.
3. Report AFF-Net's empirical result: an adapter-based update that revises only a bounded fraction of backbone parameters (roughly 20%) outperforms full fine-tuning specifically under scarce, noisy conditions.
4. Draw the general moral in its own domain, before any institutional analogy: constraining an update is not a compromise that costs performance when the update-justifying evidence is small — it is what prevents a worse outcome.
5. Leave the transfer to institutional judgment (due process, precedent, disclosure) explicitly to ch044, so that this chapter's technical claim stands on medical-imaging evidence alone and cannot be accused of being reverse-engineered from the legal analogy.

## External cases / technical analogues

| Case | Role | Note |
|---|---|---|
| AFF-Net (adaptive feature fusion network, medical image segmentation) | Load-bearing | This chapter's entire claim is about AFF-Net's own domain; it is not illustrative here, since the chapter exists specifically to keep the technical result honest before ch044 and ch074 build on it. |

## Objections this chapter must survive
- **Objection:** A single technical result from one narrow domain (medical-imaging segmentation) is a thin basis for a general claim about constrained updating, let alone for an analogy extended to legal and institutional judgment.
- **Response:** The chapter does not claim AFF-Net proves a universal law of learning; it claims only that this case demonstrates a coherent mechanism — bounded revision outperforming unconstrained revision under scarce, high-variance evidence — that ch044 and ch074 then argue applies, by structural analogy rather than identity, to institutional updating. The scope of the claim is limited accordingly, and the analogy's limits are discussed explicitly in ch044.

## Downstream chapters that depend on this one
- ch044 (Due Process as Constrained Updating) — draws the institutional analogy
- ch074 (Update Budgets) — gives the analogy its full mathematical development

## Cut candidates
If the book runs long, the segmentation-architecture detail of AFF-Net could compress to the single empirical result (constrained update outperforms full fine-tuning under scarce data) without losing what ch044 and ch074 need from it.
