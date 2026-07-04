#!/usr/bin/env bash

#
# Monotonic Artifact Committer
#
# Walks a directory tree, force-adds every file (including ignored files),
# commits one file at a time, pushes after every commit, waits a random
# interval, and logs the entire performance.
#

set -euo pipefail

ROOT="${1:-resources/processing}"

MIN_DELAY=5
MAX_DELAY=15

LOGFILE="artifact-run-$(date +%Y%m%d-%H%M%S).log"

# Tee all output to terminal and logfile
exec > >(tee -a "$LOGFILE")
exec 2>&1

echo
echo "============================================================"
echo "Monotonic Artifact Committer"
echo "Started: $(date)"
echo "Root: $ROOT"
echo "Log: $LOGFILE"
echo "============================================================"
echo

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: Not inside a git repository."
    exit 1
fi

if [ ! -d "$ROOT" ]; then
    echo "ERROR: Directory does not exist: $ROOT"
    exit 1
fi

echo "Artifact inventory:"
echo "------------------------------------------------------------"

find "$ROOT" -type f | sort | nl

echo "------------------------------------------------------------"
echo

TOTAL=$(find "$ROOT" -type f | wc -l)
COUNT=0

find "$ROOT" -type f | sort | while read -r file
do
    COUNT=$((COUNT + 1))

    # Skip if already tracked
    if git ls-files --error-unmatch "$file" >/dev/null 2>&1
    then
        echo
        echo "[SKIP] Already tracked: $file"
        continue
    fi

    name="$(basename "$file")"
    ext="${name##*.}"

    case "$ext" in
        tex)
            msg="Add source artifact: $name"
            ;;
        pdf)
            msg="Add publication artifact: $name"
            ;;
        mp3)
            msg="Add audio artifact: $name"
            ;;
        txt)
            msg="Add transcript artifact: $name"
            ;;
        vtt)
            msg="Add caption artifact: $name"
            ;;
        srt)
            msg="Add subtitle artifact: $name"
            ;;
        json)
            msg="Add metadata artifact: $name"
            ;;
        tsv)
            msg="Add alignment artifact: $name"
            ;;
        aux)
            msg="Add build state artifact: $name"
            ;;
        log)
            msg="Add process trace artifact: $name"
            ;;
        fls)
            msg="Add dependency artifact: $name"
            ;;
        fdb_latexmk)
            msg="Add compilation database artifact: $name"
            ;;
        toc)
            msg="Add table-of-contents artifact: $name"
            ;;
        out)
            msg="Add generated output artifact: $name"
            ;;
        xdv)
            msg="Add XDV artifact: $name"
            ;;
        idx)
            msg="Add index artifact: $name"
            ;;
        *)
            msg="Add artifact: $name"
            ;;
    esac

    echo
    echo "============================================================"
    echo "[$COUNT/$TOTAL]"
    echo "Time: $(date)"
    echo "File: $file"
    echo "Commit: $msg"
    echo "============================================================"

    git add -f "$file"

    if git diff --cached --quiet
    then
        echo "Nothing staged."
        continue
    fi

    git commit -m "$msg"

    echo
    echo "Pushing..."
    git push origin main

    HASH=$(git rev-parse --short HEAD)

    echo
    echo "Commit hash: $HASH"

    DELAY=$(( RANDOM % (MAX_DELAY - MIN_DELAY + 1) + MIN_DELAY ))

    echo "Sleeping ${DELAY}s..."
    sleep "$DELAY"
done

echo
echo "============================================================"
echo "Finished: $(date)"
echo "============================================================"
