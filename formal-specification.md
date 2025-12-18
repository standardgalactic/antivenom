# Formal Specification of the Spherepop Kernel

1.0 Introduction

Contemporary computational systems present a stark architectural dichotomy. Traditional state-based systems, which overwrite past configurations with present ones, suffer from an opacity of provenance; they record what a system is, but not how it came to be. Conversely, modern autoregressive systems generate fluent, view-only continuations of prior outputs without any mechanism for commitment, leading to an unavoidable drift from underlying structural invariants and a failure to sustain long-horizon coherence. Both architectures, despite their successes, lack a stable foundation for reasoning, planning, and refusal because they lack a mechanism to record and enforce the consequences of past actions.

The central thesis of this work is that robust intelligence requires an authoritative internal history: a deterministic, invariant-preserving record of committed events against which all future actions and speculative views are evaluated. Without such a history, a system cannot distinguish between a provisional hypothesis and an irreversible fact, a distinction critical for any agent that acts under constraint. The accumulation of even small deviations from lawful behavior becomes inevitable, leading to the structural brittleness observed in large-scale predictive models.

This whitepaper provides a rigorous technical specification of the Spherepop kernel, a minimal computational substrate designed to instantiate and enforce the principles of event-history preservation and lawful state evolution. The kernel is not an application or a complete cognitive architecture, but rather a foundational layer upon which such systems can be built. It provides a formal answer to the architectural problem of maintaining coherence over time by treating history not as a byproduct of computation, but as its primary, authoritative object.

This document proceeds from foundational principles to formal specification. We will first define the core concepts of event-based ontology, including authoritative state, views, and invariant-gated commitment. We will then present the architectural components of the Spherepop kernel itself. Following this, we will detail the kernel's small-step operational semantics, which constitute its complete behavioral definition. Finally, we will establish the principle of replay equivalence, which formally grounds a system's semantic identity entirely in its construction history. This specification therefore begins with a formal delineation of the conceptual primitives that motivate the kernel's design.

2.0 Foundational Concepts: Event-History and Invariant Preservation

To construct a system capable of long-horizon coherence, we must first shift our computational ontology from one centered on mutable states to one centered on irreversible events. In a state-based model, history is ephemeral and state is primary. In an event-based model, this relationship is inverted: history is the authoritative record, and state is a derived, reconstructible consequence. This section defines the core conceptual primitives upon which the Spherepop kernel is built, establishing a clear separation between speculative representation and authoritative fact.

**Authoritative State, Views, and Commitment**

The distinction between what a system might propose and what it has accepted as true is the cornerstone of this architecture. These concepts are formally separated as follows:

Concept | Formal Notation | Definition  
Authoritative Internal State | Σ | The internal state space of the system. A state σ ∈ Σ summarizes all committed information relevant to prediction, planning, and constraint evaluation.  
View | v | Any speculative, derived, or provisional representation that has not been admitted into the authoritative state. Views may be inconsistent, hypothetical, or transient.  
Commitment | — | An update to the authoritative internal state, recorded as part of a deterministic history. A commitment is admitted if and only if it preserves all system invariants.

**Invariants and Admissibility**

A system's integrity is maintained by enforcing rules that define the boundaries of lawful behavior. These rules are formalized as invariants.

An invariant is a predicate that defines a subset of admissible states, denoted Ω ⊆ Σ. Any state σ is considered legal if and only if σ ∈ Ω. States outside of this admissible set are unreachable by any committed operation.

This principle is enforced through the use of partial transition functions (δ: Σ × E ⇀ Σ), which map a state and an event to a new state. The critical feature of a partial function is that it is undefined for transitions that would produce a state outside the admissible set Ω. Inadmissible transitions are thus rendered structurally impossible, not merely penalized or assigned low probability.

**The Primacy of the Event Log**

The authoritative record of a system is not its current state, but the sequence of events that produced it.

An event log (L) is defined as a finite sequence of atomic events, L = (e₁, e₂, …, eₙ). This log is the exclusive, canonical record from which the authoritative state is derived.

The replay function Replay(L) provides the deterministic, recursive mechanism for reconstructing the authoritative state. Fixing an initial state σ₀ ∈ Ω, the replay function is defined as:

Replay(∅) = σ₀  
Replay(L · e) = δ(Replay(L), e)

**Invariant-Gated Commitment**

The mechanism that protects the integrity of the event log is invariant-gated commitment. A new event e is appended to the log L if and only if the state resulting from its replay is a member of the admissible set Ω.

Formally, an event e is appended to L if and only if Replay(L · e) ∈ Ω.

**Replay-Stabilized Consistency**

This architectural design provides a powerful guarantee about the system's behavior.

Theorem 2 (Replay-stabilized consistency): All reachable authoritative states obtained by the replay of a committed event log satisfy system invariants.

This property holds by construction. Since the initial state is admissible by definition, and since each subsequent event is only committed if it preserves admissibility, it follows by induction that no sequence of committed events can ever lead to an illegal state. Incoherence may arise in speculative views, but it is quarantined and cannot propagate into the authoritative history.

3.0 The Spherepop Kernel: An Architectural Specification

The Spherepop kernel is the concrete architectural realization of an invariant-preserving transition system grounded in event history. It is a minimal, formal substrate whose sole responsibility is to mediate the evolution of event histories according to a strict set of operational rules.

**Kernel Definition**

The Spherepop kernel is an authoritative event log substrate with strict jurisdiction over causality, identity, and admissibility. It is not a user-facing application, a programming environment, or a database. It separates the non-negotiable laws of history management from the contingent logic of utilities that may generate proposals or render views.

**Spherepop Configuration**

A Spherepop configuration is defined as a triple ⟨H, C, M⟩.

Event History (H) is a finite, partially ordered multiset of event tokens encoding causal precedence.  
Constraint Set (C) governs admissibility of future events and cannot rewrite history.  
Metadata (M) contains auxiliary information with no semantic authority.

Semantic identity depends exclusively on H.

**Event Structure**

An event token e ∈ E is an atomic, irreversible transformation. It is not a state. Once committed, it cannot be removed, only superseded or summarized.

4.0 Small-Step Operational Semantics

Event Extension commits a new event if admissible:

⟨H, C, M⟩ → ⟨H ∪ {e}, C, M⟩

Branching duplicates future possibility without copying state:

H ⇒ H₁ ‖ H₂

Merging reconciles branches by preserving events and recording resolutions:

H₁ ⊕ H₂ → H₃

Collapse summarizes a subhistory explicitly:

collapse(H) = H′

Constraints govern future extensions but cannot alter past history.

Proposition 2 (Constraint Monotonicity): Constraints may restrict future event extensions but cannot remove or alter past events.

5.0 Replay and Semantic Equivalence

Replay deterministically reconstructs meaning from event history while respecting causal order.

Theorem 1 (Replay Equivalence): Any two configurations with isomorphic event histories are semantically equivalent, regardless of metadata or presentation.

Meaning resides exclusively in construction history.

6.0 Conclusion

The Spherepop kernel provides an architecture of accountability. It replaces state erasure and view-only drift with irreversible history, first-class branching, and explicit collapse. Systems that act must answer to history.

By formalizing the primacy of the event log and defining its lawful evolution, the Spherepop kernel provides a principled foundation for computationally robust and cognitively honest systems.