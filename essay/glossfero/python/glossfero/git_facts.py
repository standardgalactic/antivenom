"""Raw Git facts, collected via subprocess. No language-specific parsing
here beyond what §5 of the design discussion calls "what Git itself gives
you" -- ls-files, log, rev-list, ls-tree.
"""
import subprocess
from pathlib import Path


def _git(repo_dir: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo_dir), *args],
        capture_output=True, text=True, check=True,
    )
    return result.stdout


def head_commit(repo_dir: Path) -> str:
    return _git(repo_dir, "rev-parse", "HEAD").strip()


def default_branch(repo_dir: Path) -> str:
    # HEAD's symbolic ref name, e.g. "main"
    out = _git(repo_dir, "symbolic-ref", "--short", "HEAD").strip()
    return out


def commit_count(repo_dir: Path) -> int:
    return int(_git(repo_dir, "rev-list", "--count", "HEAD").strip())


def tracked_paths(repo_dir: Path) -> list[str]:
    out = _git(repo_dir, "ls-files").strip()
    return out.split("\n") if out else []


def ls_tree_entries(repo_dir: Path) -> list[dict]:
    """Returns [{mode, type, blob_sha, size, path}, ...] for HEAD."""
    out = _git(repo_dir, "ls-tree", "-r", "-l", "HEAD")
    entries = []
    for line in out.strip().split("\n"):
        if not line:
            continue
        meta, path = line.split("\t", 1)
        mode, obj_type, blob_sha, size = meta.split()
        entries.append({
            "mode": mode, "type": obj_type, "blob_sha": blob_sha,
            "size": int(size), "path": path,
        })
    return entries


def all_commits_oldest_first(repo_dir: Path) -> list[str]:
    out = _git(repo_dir, "log", "--format=%H", "--reverse").strip()
    return out.split("\n") if out else []


def changed_paths_in_commit(repo_dir: Path, commit_sha: str) -> list[str]:
    out = _git(repo_dir, "show", "--name-only", "--format=", commit_sha).strip()
    return [p for p in out.split("\n") if p]
