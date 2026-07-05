#!/usr/bin/env python3

from pathlib import Path
import csv
import argparse

SKIP_DIRS = {
    ".git",
    "node_modules",
    "__pycache__",
    ".venv",
    "venv",
    "dist",
    "build",
    "target"
}

TEXT_EXTENSIONS = {
    ".txt",
    ".md",
    ".tex",
    ".py",
    ".ahk",
    ".c",
    ".cpp",
    ".h",
    ".hpp",
    ".js",
    ".ts",
    ".html",
    ".css",
    ".json",
    ".yaml",
    ".yml",
    ".xml",
    ".sh",
    ".rs",
    ".java"
}


def count_lines(path):
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return sum(1 for _ in f)
    except Exception:
        return 0


def scan_project(project_path):
    file_count = 0
    line_count = 0
    total_bytes = 0

    for file_path in project_path.rglob("*"):

        if not file_path.is_file():
            continue

        if any(part in SKIP_DIRS for part in file_path.parts):
            continue

        file_count += 1

        try:
            total_bytes += file_path.stat().st_size
        except Exception:
            pass

        if file_path.suffix.lower() in TEXT_EXTENSIONS:
            line_count += count_lines(file_path)

    return {
        "project": project_path.name,
        "files": file_count,
        "lines": line_count,
        "bytes": total_bytes
    }


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "root",
        help="Folder containing projects"
    )

    parser.add_argument(
        "--output",
        default="project_report.csv"
    )

    args = parser.parse_args()

    root = Path(args.root)

    results = []

    for item in root.iterdir():

        if not item.is_dir():
            continue

        print("Scanning:", item.name)

        results.append(scan_project(item))

    results.sort(
        key=lambda x: x["lines"],
        reverse=True
    )

    with open(args.output, "w", newline="", encoding="utf-8") as f:

        writer = csv.writer(f)

        writer.writerow([
            "Project",
            "Files",
            "Lines",
            "Bytes"
        ])

        for r in results:
            writer.writerow([
                r["project"],
                r["files"],
                r["lines"],
                r["bytes"]
            ])

    print()
    print("Top projects:")
    print()

    for r in results[:20]:
        print(
            f"{r['project']:<40} "
            f"files={r['files']:<8} "
            f"lines={r['lines']:<12}"
        )

    print()
    print("CSV written to:", args.output)


if __name__ == "__main__":
    main()