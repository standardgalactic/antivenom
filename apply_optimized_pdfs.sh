#!/usr/bin/env bash
set -euo pipefail

OUT=".pdf-optimization"
REPORT="$OUT/report.tsv"
MODE="${1:---dry-run}"

if [[ "$MODE" != "--dry-run" && "$MODE" != "--apply" ]]; then
    echo "Usage: $0 [--dry-run|--apply]"
    exit 1
fi

if [[ "$MODE" == "--apply" ]] &&
   [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree is dirty. Commit or stash changes first."
    exit 1
fi

while IFS=$'\t' read -r before after saving status path; do
    [[ "$status" == "CANDIDATE" ]] || continue

    src="${path#./}"
    dest="$OUT/$src"

    [[ -f "$src" && -f "$dest" ]] || continue

    original_pages=$(pdfinfo "$src" | awk '/^Pages:/ {print $2}')
    optimized_pages=$(pdfinfo "$dest" | awk '/^Pages:/ {print $2}')

    if [[ "$original_pages" != "$optimized_pages" ]]; then
        echo "SKIP page mismatch: $src"
        continue
    fi

    if ! diff -q \
        <(pdftotext -layout "$src" -) \
        <(pdftotext -layout "$dest" -) >/dev/null; then
        echo "SKIP text mismatch: $src"
        continue
    fi

    if ! qpdf --check "$dest" >/dev/null 2>&1; then
        echo "SKIP PDF validation failure: $src"
        continue
    fi

    echo "PASS ($saving%): $src"

    if [[ "$MODE" == "--apply" ]]; then
        cp -- "$dest" "$src"
    fi
done < <(tail -n +2 "$REPORT")

if [[ "$MODE" == "--apply" ]]; then
    git add -u -- '*.pdf'
    git commit -m "Optimize embedded PDF images without downsampling"
fi
