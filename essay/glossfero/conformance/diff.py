#!/usr/bin/env python3
"""
Reference conformance differ for Glossfero.

Compares an implementation's output JSON file against the corresponding
golden/<fixture>/expected.*.json file, applying the exact-match vs.
bounded-match field rules from spec/protocol/protocol.md §7.

This is the reference implementation of the diffing logic, not the only
permitted one -- but any other differ (e.g. one embedded in a specific
language's own test harness) must agree with this one on every fixture in
golden/. When in doubt, this script is authoritative.

Usage:
    python3 diff.py <object-kind> <golden.json> <actual.json>

    object-kind is one of: repo_record, proposal, collision_result,
    glossfero_name

Exit code 0 means conformant. Exit code 1 means a mismatch was found and
details are printed to stderr.
"""
import sys
import json


# Fields whose value must be byte-identical (after JSON-level equality --
# not raw byte comparison of the whole file, since key order and whitespace
# in the *actual* file are the implementation's own business as long as the
# file is valid JSON matching the schema).
EXACT_MATCH_FIELDS = {
    "repo_record": {
        "repo_id", "name", "remote", "default_branch", "head_commit",
        "languages", "paths", "bytes", "commits", "topics",
        "fingerprints.name", "fingerprints.structural", "fingerprints.manifest",
    },
    "proposal": {
        "source_repo", "source_commit", "candidate_root", "source_paths",
        "dependencies_in", "dependencies_out", "estimated_files",
        "estimated_bytes", "cochange_score", "cross_boundary_cost",
    },
    "collision_result": {
        "classification", "stage_reached", "nearest_existing",
        "requires_human_review",
    },
    "glossfero_name": {
        "semantic_root", "full_name", "status",
    },
}

# Fields checked for presence/shape/range only, never exact value.
BOUNDED_MATCH_FIELDS = {
    "repo_record": {"summary_ref", "fingerprints.semantic", "fingerprints.content",
                     "fingerprints.history", "scanned_at"},
    "proposal": {"summary", "semantic_cohesion", "score"},
    "collision_result": {"reason", "checked_at"},
    "glossfero_name": {"object_type", "discriminator"},
}

# Fixtures may override object_type to be forced (exact-match) rather than
# bounded, when the fixture's own README declares it a forced-answer case
# (see golden/repo-small-001/README.md). List forced fixture/kind/field
# triples here.
FORCED_OVERRIDES = {
    ("repo-small-001", "glossfero_name", "object_type"),
}


def get_path(obj, dotted):
    cur = obj
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return None, False
        cur = cur[part]
    return cur, True


def check_bounded(kind, field, value):
    """Shape/range checks for known bounded fields. Returns (ok, reason)."""
    if field in ("semantic_cohesion", "score"):
        if value is None:
            return True, None
        if not isinstance(value, (int, float)):
            return False, f"{field} must be numeric or null, got {type(value).__name__}"
        if not (0 <= value <= 1):
            return False, f"{field} must be in [0, 1], got {value}"
        return True, None
    if field == "summary":
        if not isinstance(value, str) or len(value.strip()) < 5:
            return False, "summary must be a non-trivial string"
        return True, None
    if field == "reason":
        if not isinstance(value, str) or len(value.strip()) == 0:
            return False, "reason must be a non-empty string"
        return True, None
    if field == "object_type":
        allowed = {"bubble", "sphere", "object", "text", "cloak"}
        if value not in allowed:
            return False, f"object_type must be one of {allowed}, got {value!r}"
        return True, None
    # default: presence is enough
    return True, None


def diff(kind, golden, actual, fixture_name=None):
    problems = []

    for field in sorted(EXACT_MATCH_FIELDS.get(kind, set())):
        g_val, g_present = get_path(golden, field)
        a_val, a_present = get_path(actual, field)
        if g_present != a_present:
            problems.append(f"[exact] {field}: presence mismatch (golden={g_present}, actual={a_present})")
            continue
        if g_present and g_val != a_val:
            problems.append(f"[exact] {field}: golden={g_val!r} actual={a_val!r}")

    for field in sorted(BOUNDED_MATCH_FIELDS.get(kind, set())):
        forced = fixture_name is not None and (fixture_name, kind, field) in FORCED_OVERRIDES
        a_val, a_present = get_path(actual, field)
        g_val, g_present = get_path(golden, field)
        if forced:
            if g_present and a_present and g_val != a_val:
                problems.append(f"[forced] {field}: golden={g_val!r} actual={a_val!r} "
                                 f"(this fixture requires an exact answer here -- see golden/{fixture_name}/README.md)")
            continue
        if not a_present:
            # bounded fields may legitimately be null/absent depending on stage;
            # only flag if golden has a non-null value and actual is missing entirely
            if g_present and g_val is not None:
                problems.append(f"[bounded] {field}: present in golden but missing in actual")
            continue
        ok, reason = check_bounded(kind, field, a_val)
        if not ok:
            problems.append(f"[bounded] {field}: {reason}")

    return problems


def main():
    if len(sys.argv) != 4:
        print(__doc__, file=sys.stderr)
        sys.exit(2)

    kind, golden_path, actual_path = sys.argv[1], sys.argv[2], sys.argv[3]
    if kind not in EXACT_MATCH_FIELDS:
        print(f"unknown object-kind {kind!r}; expected one of {sorted(EXACT_MATCH_FIELDS)}", file=sys.stderr)
        sys.exit(2)

    with open(golden_path) as f:
        golden = json.load(f)
    with open(actual_path) as f:
        actual = json.load(f)

    fixture_name = None
    for part in golden_path.replace("\\", "/").split("/"):
        if part.startswith("repo-") or part.startswith("fixture-"):
            fixture_name = part

    problems = diff(kind, golden, actual, fixture_name=fixture_name)

    if problems:
        print(f"NON-CONFORMANT: {actual_path} vs {golden_path} ({kind})", file=sys.stderr)
        for p in problems:
            print(f"  {p}", file=sys.stderr)
        sys.exit(1)

    print(f"conformant: {actual_path} vs {golden_path} ({kind})")
    sys.exit(0)


if __name__ == "__main__":
    main()
