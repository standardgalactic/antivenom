---
name: spherepop-authority-continuation
description: Resolve authority, provenance, admissibility, continuation, and replay questions for repository agents using Spherepop-style append-only history and explicit dispositions. Load before protected writes, delegation, conflicting instructions, irreversible actions, or audit reconstruction.
---

# Spherepop Authority and Continuation

This skill is an **advisory governance contract**, not a security boundary. Tool permissions, operating-system access controls, branch protections, and runtime validators are the actual enforcement mechanisms. Never claim that a documented refusal prevented an action unless the execution boundary enforced it.

## When to load

Load when an agent needs to determine who may change an artifact, whether an instruction may be delegated, whether evidence supports a proposed action, whether to continue or stop after partial execution, or how to replay and audit a decision.

## Source-of-truth hierarchy

| Artifact | Role | Writer | Interpretation |
| --- | --- | --- | --- |
| `.github/agents/*.agent.md` | Maintainer-approved agent instructions | Maintainer | Subject to higher-priority platform/runtime policy; not self-amendable by agents |
| `.spherepop/policy.yaml` | Repository authority, scope, and transition policy | Maintainer or explicitly authorized policy owner | Governs admissibility within its stated scope |
| `.spherepop/history.jsonl` | Append-only event history | Authorized event recorder | Evidence of events, not independently a source of new authority |
| `.spherepop/decisions.jsonl` | Append-only decisions and supersessions | Authorized decision recorder | Effective decisions obtained by ordered replay under policy |
| `.spherepop/evidence/` | Referenced evidence artifacts | Authorized evidence collectors | Claims must retain provenance and limitations |
| `.spherepop/agents/*.md` | Agent charters | Maintainer or authorized coordinator at creation | Cannot grant privileges exceeding policy |
| `.spherepop/cache/` | Derived views | Runtime | Disposable and never authoritative |

If artifacts conflict, first apply higher-priority platform/runtime constraints, then the repository policy within its jurisdiction, then authorized decisions in replay order. Agent charters and historical narratives cannot enlarge permissions. If conflict cannot be resolved by these rules, return **UNRESOLVED** rather than inventing precedence.

## Transition vocabulary

Use these operations as a minimal conceptual interface, not as a claim that every Spherepop implementation uses identical signatures:

- `POP`: propose a new distinction, action, or state candidate; do not execute merely because it was proposed.
- `MERGE`: combine compatible histories or proposals only when authority, provenance, and consistency requirements hold.
- `COLLAPSE`: commit a permitted resolution or state transition with its supporting evidence.
- `REFUSE`: record why a transition is inadmissible; refusal does not prove that execution was technically blocked.

All accepted transitions receive stable identifiers and references to predecessor events. Corrections and revocations append new records; never silently rewrite historical meaning.

## Decision procedure

For each consequential proposed action, identify the action, actor, target, execution path, claimed authority, jurisdiction, evidence, risk classification, and current policy version. Separate observed facts from assertions, simulations, and unknowns. Verify that delegation preserves scope and expiry, and that the actual tool or execution path is covered by enforcement. Check relevant joint effects with other pending actions.

Return exactly one disposition:

- **ALLOW**: requirements are satisfied for this action and scope.
- **REFUSE**: an applicable prohibition or failed mandatory condition is established.
- **UNRESOLVED**: essential evidence or authority is missing, stale, or contested.
- **INCOMPARABLE**: applicable standards cannot be ordered or reconciled by current policy.

Do not collapse UNRESOLVED or INCOMPARABLE into REFUSE in the audit record, even if operational policy chooses not to execute any of them. The execution decision is a separate field.

## Continuation and closure

Record separately: `disposition`, `execution_authorized`, `execution_observed`, `operational_closure`, `epistemic_closure`, and `remedial_closure`. A refusal may require safe compensating actions after partial execution; do not assume an immediate halt is safer. When a previously supporting fact expires or is contradicted, append a re-evaluation event referencing the original decision.

## Minimum event record

```json
{
  "event_id": "evt-unique-id",
  "previous_event_ids": [],
  "policy_version": "version-or-commit",
  "actor": "agent-or-human-id",
  "action": "proposed-action",
  "target": "artifact-or-resource",
  "authority_basis": [],
  "evidence_refs": [],
  "disposition": "UNRESOLVED",
  "execution_authorized": false,
  "execution_observed": "unknown",
  "operational_closure": "open",
  "epistemic_closure": "open",
  "remedial_closure": "open",
  "reason": "Missing independently verified authority",
  "supersedes": null
}
```

A log entry is a claim about a decision or observation, not proof of enforcement. Preserve enough ordering information for deterministic replay, and explicitly declare when external effects cannot be reconstructed.

## Non-negotiable invariants

No agent may self-grant authority. A delegation cannot increase the delegator's authorized scope. Derived summaries cannot supersede policy. A decision cannot erase its evidentiary dependencies. An append-only correction references the prior event. Replaying the same valid ordered event stream under the same policy version must produce the same derived disposition state. If a validator cannot establish these invariants, it must report the limitation rather than claiming verification.

## Output when invoked

Provide the proposed action, governing rule and policy version, authority chain, evidence status, disposition, separate execution decision, continuation obligations, and event record or a precise explanation of why no record was written. Never claim that an event was recorded without actually writing it.

