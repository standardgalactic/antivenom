"""Canonical JSON serialization, per spec/protocol/protocol.md §8.

Two modes:
  - dumps_pretty: standalone JSON artifacts (sorted keys, 2-space indent,
    UTF-8, single trailing newline, no trailing whitespace per line).
  - dumps_compact: one JSON Lines record (sorted keys, no inserted
    whitespace, UTF-8, single trailing newline).
"""
import json


def dumps_pretty(obj) -> str:
    s = json.dumps(obj, indent=2, sort_keys=True, ensure_ascii=False)
    lines = [line.rstrip() for line in s.split("\n")]
    return "\n".join(lines) + "\n"


def dumps_compact(obj) -> str:
    return json.dumps(obj, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def write_pretty(path, obj) -> None:
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(dumps_pretty(obj))
