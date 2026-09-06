# Spine: ch060 — Trust Networks and Correlated Capture

**Volume:** VI: Adversaries, Platforms, and Automated Judgment
**Part:** XI. Untrustworthy Actors
**Status:** spine

## Claim
Trust must be modeled on dependency graphs, because reports \(R_1,\ldots,R_n\) that share an ancestor \(S\) exhibit \emph{correlated capture} and carry far less joint evidentiary weight than apparent repetition suggests.

## Depends on
- ch059 — suspicious events must be interpreted through bounded models of adversarial agency, including actors who intervene indirectly and selectively rather than by total control.

## Load-bearing steps
1. Model trust as a dependency graph whose apparent leaves are reports \(R_1,\ldots,R_n\) rather than assuming that the number of reports measures independent confirmation.
2. Mark \(S\) as a shared upstream ancestor whenever multiple reports trace back to one originating source, institution, or gatekeeper.
3. Show that once \(R_1,\ldots,R_n\) share \(S\), their joint evidentiary weight is much smaller than it would be under independence; repetition has been revealed as \emph{correlated capture}.
4. Infer that resilient trust networks require heterogeneous origins and review paths, not merely many downstream repetitions of the same captured source.

## External cases / technical analogues

| Case | Role | Note |
|---|---|---|
| Credit-rating and mortgage-securitization networks before 2008 | Illustrative | shows institutions that looked plural while sharing incentives and informational blind spots |
| Tobacco-funded research and lobbying ecosystem | Illustrative | demonstrates coordinated influence without centralized visible command |

## Objections this chapter must survive
- Correlated behavior often reflects ordinary professional convergence or shared evidence, so calling it "capture" pathologizes consensus and invites cynical distrust of all institutions.
- Response: the chapter targets hidden common dependencies that defeat independent checking, not convergence that survives genuinely separate lines of review.

## Downstream chapters that depend on this one
-

## Formal result labels
- `\(R_1,\ldots,R_n\)` sharing ancestor `\(S\)` — `\ToyModel`

## Cut candidates
The financial and tobacco examples can be reduced to a single generic common-mode-failure example; the essential material is the distinction between plurality and independence.
