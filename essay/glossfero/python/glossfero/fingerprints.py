"""Structural and manifest fingerprints, per spec/protocol/protocol.md §1c."""
import hashlib
from pathlib import Path

from . import git_facts

RECOGNIZED_MANIFESTS = {
    "Cargo.toml", "pyproject.toml", "requirements.txt", "package.json",
    "elm.json", "deps.edn", "project.clj", "pom.xml", "build.gradle",
    "cabal.project", "stack.yaml", "go.mod", "Makefile", "CMakeLists.txt",
}


def _is_manifest(path: str) -> bool:
    name = path.rsplit("/", 1)[-1]
    if name in RECOGNIZED_MANIFESTS:
        return True
    return name.endswith(".cabal")


def structural_fingerprint(tracked_paths: list[str]) -> str:
    joined = "\n".join(sorted(tracked_paths))
    return "sha256:" + hashlib.sha256(joined.encode("utf-8")).hexdigest()


def manifest_fingerprint(repo_dir: Path, tracked_paths: list[str]) -> str:
    entries = git_facts.ls_tree_entries(repo_dir)
    blob_sha_by_path = {e["path"]: e["blob_sha"] for e in entries}

    matches = sorted(p for p in tracked_paths if _is_manifest(p))
    joined = "\n".join(f"{p}:{blob_sha_by_path[p]}" for p in matches)
    return "sha256:" + hashlib.sha256(joined.encode("utf-8")).hexdigest()
