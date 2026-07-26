"""CLI entrypoint satisfying the contract documented at the top of
conformance/run: given a fixture directory and an output directory, run
DISCOVER + MEASURE and write repo_record.json, canonically serialized.
"""
import json
import sys
from pathlib import Path

from .measure import discover_and_measure
from .canonical import write_pretty


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: cli.py <fixture-dir> <output-dir>", file=sys.stderr)
        return 2

    fixture_dir = Path(argv[1])
    output_dir = Path(argv[2])
    output_dir.mkdir(parents=True, exist_ok=True)

    sidecar_path = fixture_dir / ".glossfero-fixture.json"
    if not sidecar_path.exists():
        print(f"missing sidecar: {sidecar_path}", file=sys.stderr)
        return 1
    sidecar = json.loads(sidecar_path.read_text())

    record = discover_and_measure(
        repo_dir=fixture_dir,
        remote=sidecar["remote"],
        scanned_at=sidecar["scanned_at"],
    )

    write_pretty(output_dir / "repo_record.json", record)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
