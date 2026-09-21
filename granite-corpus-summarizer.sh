#!/usr/bin/env bash
set -Eeuo pipefail

# ---------------------------------------------------------------------------
# Granite Corpus Summarizer
#
# Reads an explicit manifest of text files, creates:
#   1. one summary per document
#   2. one synthesis per directory
#   3. hierarchical corpus syntheses
#   4. one final Markdown report
#
# Individual summaries are cached, so interrupted runs can resume.
# ---------------------------------------------------------------------------

MODEL="${MODEL:-granite4.1:3b}"
MANIFEST="${MANIFEST:-antivenom-corpus-files.txt}"
OUTPUT="${OUTPUT:-antivenom-granite-summary.md}"
CACHE="${CACHE:-.granite-antivenom-cache}"

# Maximum bytes sent in one source-text chunk.
CHUNK_BYTES="${CHUNK_BYTES:-24000}"

# Maximum bytes grouped together during synthesis.
SYNTH_BYTES="${SYNTH_BYTES:-45000}"

command -v ollama >/dev/null 2>&1 || {
    echo "ERROR: ollama is not installed or not in PATH." >&2
    exit 1
}

[[ -f "$MANIFEST" ]] || {
    echo "ERROR: Manifest not found: $MANIFEST" >&2
    exit 1
}

mkdir -p \
    "$CACHE/documents" \
    "$CACHE/chunks" \
    "$CACHE/directories" \
    "$CACHE/corpus"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

hash_string() {
    printf '%s' "$1" | sha256sum | cut -d' ' -f1
}

safe_id() {
    local path="$1"
    local hash
    hash="$(hash_string "$path")"
    printf '%s' "$hash"
}

run_granite() {
    ollama run "$MODEL" |
    python3 -c '
import re
import sys

data = sys.stdin.buffer.read()

# Strip ANSI/VT100 CSI sequences.
data = re.sub(
    rb"\x1b\[[0-?]*[ -/]*[@-~]",
    b"",
    data
)

# Strip OSC sequences.
data = re.sub(
    rb"\x1b\][^\x07]*(?:\x07|\x1b\\\\)",
    b"",
    data
)

sys.stdout.buffer.write(data)
'
}

file_count="$(grep -cv '^[[:space:]]*$' "$MANIFEST")"

echo "============================================================"
echo "GRANITE CORPUS SUMMARIZER"
echo "============================================================"
echo
echo "Model:     $MODEL"
echo "Manifest:  $MANIFEST"
echo "Files:     $file_count"
echo "Cache:     $CACHE"
echo "Output:    $OUTPUT"
echo

# ---------------------------------------------------------------------------
# Validate manifest
# ---------------------------------------------------------------------------

missing=0

while IFS= read -r file || [[ -n "$file" ]]; do
    [[ -z "$file" ]] && continue

    if [[ ! -f "$file" ]]; then
        echo "MISSING: $file" >&2
        ((++missing))
    fi
done < "$MANIFEST"

if (( missing > 0 )); then
    echo
    echo "ERROR: $missing manifest files are missing." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Document summarization
# ---------------------------------------------------------------------------

summarize_document() {
    local file="$1"
    local id summary_dir chunk_dir
    local size total part

    id="$(safe_id "$file")"
    summary_dir="$CACHE/documents/$id"
    chunk_dir="$CACHE/chunks/$id"

    mkdir -p "$summary_dir" "$chunk_dir"

    local final="$summary_dir/summary.md"

    # Resume support.
    if [[ -s "$final" ]]; then
        printf '%s\n' "$final"
        return
    fi

    size="$(wc -c < "$file")"

    if [[ ! -s "$file" ]]; then
        {
            echo "# $file"
            echo
            echo "_Empty file._"
        } > "$final"

        printf '%s\n' "$final"
        return
    fi

    rm -f "$chunk_dir"/chunk-* "$chunk_dir"/summary-*

    split \
        -b "$CHUNK_BYTES" \
        -d \
        -a 4 \
        "$file" \
        "$chunk_dir/chunk-"

    mapfile -t chunks < <(
        find "$chunk_dir" -maxdepth 1 -type f -name 'chunk-*' | sort
    )

    total="${#chunks[@]}"
    part=0

    for chunk in "${chunks[@]}"; do
        ((++part))

        chunk_summary="$chunk_dir/summary-$(printf '%04d' "$part").md"

        if [[ -s "$chunk_summary" ]]; then
            continue
        fi

        {
            cat <<EOF
You are analyzing one document from a larger intellectual corpus.

SOURCE FILE:
$file

CHUNK:
$part of $total

Write a dense but readable analytical summary of this chunk.

Preserve:
- central claims
- arguments and reasoning
- named concepts and terminology
- definitions
- mathematical or formal structures
- mechanisms and causal claims
- examples that materially support the argument
- conclusions
- unusual, distinctive, or speculative ideas
- explicit relationships to other theories or frameworks

Distinguish clearly between:
- claims made by the text
- proposals or speculation
- evidence described by the text

Do not:
- add outside facts
- correct the author
- invent missing arguments
- praise or criticize the writing
- discuss your role as summarizer

Prefer conceptual information over rhetorical filler.

TEXT BEGINS
----------------
EOF
            cat "$chunk"
            printf '\n----------------\nTEXT ENDS\n'
        } | run_granite > "$chunk_summary"

    done

    # ---------------------------------------------------------------
    # One chunk: its summary is already the document summary.
    # ---------------------------------------------------------------

    if (( total == 1 )); then
        {
            echo "# $file"
            echo
            echo "**Source size:** $size bytes"
            echo
            cat "$chunk_dir/summary-0001.md"
        } > "$final"

        printf '%s\n' "$final"
        return
    fi

    # ---------------------------------------------------------------
    # Multiple chunks: synthesize into one document representation.
    # ---------------------------------------------------------------

    {
        cat <<EOF
You are reconstructing a complete document from summaries of consecutive
chunks of that document.

SOURCE FILE:
$file

Produce a unified analytical summary.

Recover:
1. the document's central thesis or purpose;
2. its major concepts and definitions;
3. its argumentative or explanatory structure;
4. important formal or mathematical ideas;
5. mechanisms and examples;
6. conclusions;
7. unresolved questions or tensions explicitly present in the document;
8. distinctive concepts that may be useful when comparing this document
   with other documents in the corpus.

Merge repetition introduced by chunking.

Do not introduce outside knowledge.
Do not infer claims unsupported by the chunk summaries.

CHUNK SUMMARIES
================
EOF

        for s in "$chunk_dir"/summary-*.md; do
            echo
            echo "-----"
            cat "$s"
        done

    } | run_granite > "$summary_dir/body.md"

    {
        echo "# $file"
        echo
        echo "**Source size:** $size bytes"
        echo
        cat "$summary_dir/body.md"
    } > "$final"

    printf '%s\n' "$final"
}

# ---------------------------------------------------------------------------
# PASS 1: Documents
# ---------------------------------------------------------------------------

echo "PASS 1: DOCUMENT SUMMARIES"
echo

declare -a summary_files=()
declare -a source_files=()

n=0

while IFS= read -r file || [[ -n "$file" ]]; do
    [[ -z "$file" ]] && continue

    ((++n))

    id="$(safe_id "$file")"
    expected="$CACHE/documents/$id/summary.md"

    if [[ -s "$expected" ]]; then
        echo "[$n/$file_count] cached  $file"
    else
        echo "[$n/$file_count] summarize $file"
    fi

    result="$(summarize_document "$file")"

    source_files+=("$file")
    summary_files+=("$result")

done < "$MANIFEST"

echo
echo "Document pass complete."
echo

# ---------------------------------------------------------------------------
# PASS 2: Directory syntheses
# ---------------------------------------------------------------------------

echo "PASS 2: DIRECTORY SYNTHESES"
echo

declare -A dirs=()

for file in "${source_files[@]}"; do
    dir="$(dirname "$file")"

    if [[ "$dir" == "." ]]; then
        dir="[top-level]"
    fi

    dirs["$dir"]=1
done

mapfile -t directory_names < <(
    printf '%s\n' "${!dirs[@]}" | sort
)

declare -a directory_summaries=()

for dir in "${directory_names[@]}"; do

    dir_id="$(safe_id "$dir")"
    dir_output="$CACHE/directories/$dir_id.md"

    if [[ -s "$dir_output" ]]; then
        echo "cached     $dir"
        directory_summaries+=("$dir_output")
        continue
    fi

    echo "synthesize $dir"

    temp="$CACHE/directories/$dir_id.input"
    : > "$temp"

    for i in "${!source_files[@]}"; do
        file="${source_files[$i]}"
        actual_dir="$(dirname "$file")"

        [[ "$actual_dir" == "." ]] && actual_dir="[top-level]"

        if [[ "$actual_dir" == "$dir" ]]; then
            {
                echo
                echo "============================================================"
                echo "DOCUMENT: $file"
                echo "============================================================"
                cat "${summary_files[$i]}"
            } >> "$temp"
        fi
    done

    {
        cat <<EOF
You are analyzing a collection of related documents from one directory
inside a larger intellectual archive.

DIRECTORY:
$dir

Construct a directory-level synthesis.

Identify:
- recurring concepts and vocabulary
- major arguments
- distinct theories or frameworks
- relationships among documents
- concepts that evolve across documents
- duplicated or near-duplicated ideas
- disagreements, tensions, or incompatible assumptions
- unusually isolated ideas
- recurring mathematical or structural motifs
- connections that are not obvious from filenames alone

Do not merely enumerate the documents.
Do not introduce outside knowledge.
Base the synthesis only on the supplied document summaries.

DOCUMENT SUMMARIES
==================
EOF
        cat "$temp"
    } | run_granite > "$dir_output"

    directory_summaries+=("$dir_output")

done

echo
echo "Directory pass complete."
echo

# ---------------------------------------------------------------------------
# PASS 3: Hierarchical corpus reduction
#
# Directory summaries may collectively exceed model context.
# Group them into bounded batches and synthesize each batch.
# ---------------------------------------------------------------------------

echo "PASS 3: CORPUS REDUCTION"
echo

rm -f "$CACHE/corpus/group-input-"*.txt 2>/dev/null || true

group=1
group_file="$CACHE/corpus/group-input-$(printf '%03d' "$group").txt"
: > "$group_file"

current_size=0

for summary in "${directory_summaries[@]}"; do

    size="$(wc -c < "$summary")"

    if (( current_size > 0 && current_size + size > SYNTH_BYTES )); then
        ((++group))
        group_file="$CACHE/corpus/group-input-$(printf '%03d' "$group").txt"
        : > "$group_file"
        current_size=0
    fi

    {
        echo
        echo "============================================================"
        cat "$summary"
    } >> "$group_file"

    ((current_size += size))

done

mapfile -t group_inputs < <(
    find "$CACHE/corpus" \
        -maxdepth 1 \
        -type f \
        -name 'group-input-*.txt' |
    sort
)

declare -a group_summaries=()

g=0
gtotal="${#group_inputs[@]}"

for input in "${group_inputs[@]}"; do

    ((++g))

    output="$CACHE/corpus/group-summary-$(printf '%03d' "$g").md"

    if [[ -s "$output" ]]; then
        echo "[$g/$gtotal] cached synthesis group"
        group_summaries+=("$output")
        continue
    fi

    echo "[$g/$gtotal] synthesize corpus group"

    {
        cat <<EOF
These are directory-level analyses from a larger intellectual corpus.

Produce an intermediate synthesis.

Look specifically for:
- concepts shared across otherwise separate domains
- recurring structural patterns
- theories that appear to be variants of one another
- conceptual migrations from one subject to another
- recurring distinctions, operators, geometries, or causal structures
- unresolved contradictions
- changes in terminology for apparently related ideas
- genuinely surprising relationships supported by the material

Do not flatten meaningful differences between theories.
Do not introduce outside information.

DIRECTORY ANALYSES
==================
EOF
        cat "$input"

    } | run_granite > "$output"

    group_summaries+=("$output")

done

echo

# ---------------------------------------------------------------------------
# PASS 4: Final corpus synthesis
# ---------------------------------------------------------------------------

echo "PASS 4: FINAL CORPUS SYNTHESIS"
echo

final_synthesis="$CACHE/corpus/final-synthesis.md"

{
    cat <<EOF
You are performing a final synthesis of an intellectual archive.

The supplied material consists of intermediate analyses produced from
document-level and directory-level summaries.

Reconstruct the architecture of the corpus rather than merely summarizing
topics.

Produce the following sections:

## Central Intellectual Problem

What recurring problem or family of problems appears to organize the corpus?

## Major Frameworks

Identify the major distinct frameworks or theoretical programs. Explain
what each is trying to do and how it differs from the others.

## Recurring Concepts and Operations

Identify concepts, distinctions, operations, mathematical motifs, or
explanatory structures that recur across domains.

## Conceptual Genealogy

Where supported by the material, identify ideas that appear in primitive,
intermediate, and more developed forms.

## Convergences

Identify theories or documents that approach similar structures from
different starting points.

## Tensions and Contradictions

Identify assumptions or conclusions that do not sit comfortably together.
Do not artificially reconcile them.

## Renamed or Rediscovered Ideas

Identify cases where apparently related ideas recur under different names
or vocabulary. State uncertainty where identity is unclear.

## Isolated Branches

Identify substantial ideas that do not appear well integrated with the
rest of the corpus.

## Surprising Connections

Identify non-obvious relationships supported by the summaries. Explain
why each connection is structurally interesting.

## Overall Architecture

Describe the corpus as a system: its major regions, bridges, repeated
operators, and unresolved boundaries.

Constraints:

- Use only the supplied analyses.
- Do not add external scholarship.
- Do not assume similarly worded concepts are identical.
- Distinguish strong connections from tentative ones.
- Preserve unusual terminology where useful.
- Prefer structural analysis over praise, criticism, or biography.

INTERMEDIATE CORPUS ANALYSES
============================
EOF

    for summary in "${group_summaries[@]}"; do
        echo
        echo "============================================================"
        cat "$summary"
    done

} | run_granite > "$final_synthesis"

echo "Final synthesis complete."
echo

# ---------------------------------------------------------------------------
# PASS 5: Assemble human-readable report
# ---------------------------------------------------------------------------

echo "PASS 5: ASSEMBLING REPORT"
echo

{
    echo "# Antivenom Corpus Analysis"
    echo
    echo "**Model:** \`$MODEL\`  "
    echo "**Manifest:** \`$MANIFEST\`  "
    echo "**Documents:** $file_count"
    echo
    echo "---"
    echo
    echo "# Corpus Synthesis"
    echo
    cat "$final_synthesis"

    echo
    echo "---"
    echo
    echo "# Directory Syntheses"
    echo

    for i in "${!directory_names[@]}"; do
        echo
        echo "## ${directory_names[$i]}"
        echo
        cat "${directory_summaries[$i]}"
        echo
    done

    echo
    echo "---"
    echo
    echo "# Document Summaries"
    echo

    for i in "${!source_files[@]}"; do
        echo
        echo "## ${source_files[$i]}"
        echo
        cat "${summary_files[$i]}"
        echo
    done

} > "$OUTPUT"

echo "============================================================"
echo "COMPLETE"
echo "============================================================"
echo
echo "Documents: $file_count"
echo "Model:     $MODEL"
echo
echo "Report:"
echo "  $OUTPUT"
echo
echo "Cache:"
echo "  $CACHE"
echo
echo "Rerunning the script will reuse cached document and directory summaries."
