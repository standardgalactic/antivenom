"""DISCOVER + MEASURE, per spec/protocol/protocol.md §1.

DISCOVER: identify the repository (repo_id, remote, head_commit).
MEASURE: collect the measurable RepoRecord fields.

This module does not touch SUMMARIZE, PROPOSE PARTITION, or anything
downstream -- those require the model provider boundary and are out of
scope for this milestone.
"""
from pathlib import Path

from . import git_facts
from .repo_id import repo_id as compute_repo_id
from .fingerprints import structural_fingerprint, manifest_fingerprint
from .languages import language_fractions

SCANNER_VERSION = "glossfero-python-scanner/0.1.0"


def discover_and_measure(repo_dir: Path, remote: str, scanned_at: str) -> dict:
    """Returns a dict matching spec/schemas/repo_record.schema.json."""
    repo_dir = Path(repo_dir)

    head = git_facts.head_commit(repo_dir)
    branch = git_facts.default_branch(repo_dir)
    commits = git_facts.commit_count(repo_dir)
    tracked = git_facts.tracked_paths(repo_dir)
    entries = git_facts.ls_tree_entries(repo_dir)

    total_bytes = sum(e["size"] for e in entries)
    languages = language_fractions(entries)

    record = {
        "repo_id": compute_repo_id(remote),
        "name": repo_dir.name,
        "remote": remote,
        "default_branch": branch,
        "head_commit": head,
        "languages": languages,
        "paths": len(tracked),
        "bytes": total_bytes,
        "commits": commits,
        "topics": [],
        "summary_ref": None,
        "fingerprints": {
            "name": repo_dir.name,
            "structural": structural_fingerprint(tracked),
            "manifest": manifest_fingerprint(repo_dir, tracked),
            "history": None,
            "semantic": None,
            "content": None,
        },
        "scanner_version": SCANNER_VERSION,
        "scanned_at": scanned_at,
    }
    return record
