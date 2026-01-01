#!/bin/bash
#
# =============================================================================
# NAME
#   get-context.sh
#
# SYNOPSIS
#   ./get-context.sh [OPTIONS]
#
# DESCRIPTION
#   Recursively processes all .txt files in the current directory and
#   subdirectories. Files are split into chunks and sent to an LLM via Ollama.
#   Results are appended to a single summary file.
#
#   Previously processed files are tracked to avoid reprocessing.
#
# OPTIONS
#   -m, --memory
#       Load all *.memory files (recursively) before processing and use their
#       contents as prior context for every model invocation.
#
#   -t, --translate
#       Translate input text to English instead of summarizing.
#
# BEHAVIOR
#   - Without flags: summarizes text files
#   - With --memory: summaries/translations are informed by memory context
#   - With --translate: replaces summarization prompt with translation prompt
#   - Flags may be combined
#
# OUTPUT FILES
#   progress.log  - append-only processing log
#   opinion.txt  - model output (summaries or translations)
#
# REQUIREMENTS
#   - bash
#   - ollama
#   - granite3.2:8b model installed
#
# =============================================================================

# ===============================
# Configuration
# ===============================
progress_file="progress.log"
summary_file="opinion.txt"
main_dir=$(pwd)

# ===============================
# Flags
# ===============================
USE_MEMORY=false
USE_TRANSLATE=false
MEMORY_CONTEXT=""

for arg in "$@"; do
    case "$arg" in
        -m|--memory)
            USE_MEMORY=true
            ;;
        -t|--translate)
            USE_TRANSLATE=true
            ;;
    esac
done

# ===============================
# Setup output files
# ===============================
touch "$main_dir/$progress_file"
touch "$main_dir/$summary_file"

echo "Script started at $(date)" >> "$main_dir/$progress_file"
echo "Summaries/translations saved to $summary_file" >> "$main_dir/$progress_file"

# ===============================
# Load *.memory files if enabled
# ===============================
if $USE_MEMORY; then
    echo "Memory mode enabled" >> "$main_dir/$progress_file"

    while IFS= read -r -d '' memfile; do
        echo "Loading memory file: $memfile" >> "$main_dir/$progress_file"
        MEMORY_CONTEXT+=$'\n\n'"===== MEMORY FILE: $(basename "$memfile") ====="$'\n'
        MEMORY_CONTEXT+="$(cat "$memfile")"
    done < <(find "$main_dir" -type f -name "*.memory" -print0)

    if [ -z "$MEMORY_CONTEXT" ]; then
        echo "Warning: --memory flag set but no *.memory files found" >> "$main_dir/$progress_file"
    fi
fi

# ===============================
# Helper: processed check
# ===============================
is_processed() {
    grep -Fxq "$1" "$main_dir/$progress_file"
}

# ===============================
# Process files in a directory
# ===============================
process_files() {
    local dir=$1
    echo "Processing directory: $dir"

    for file in "$dir"/*.txt; do
        [ -e "$file" ] || continue

        if [ "$(basename "$file")" == "$summary_file" ]; then
            continue
        fi

        if [ -f "$file" ]; then
            local file_name=$(basename "$file")

            if ! is_processed "$file_name"; then
                echo "Processing $file_name" >> "$main_dir/$progress_file"

                sanitized_name=$(basename "$file" | tr -d '[:space:]')
                temp_dir=$(mktemp -d "$dir/tmp_${sanitized_name}_XXXXXX")
                echo "Temp dir: $temp_dir" >> "$main_dir/$progress_file"

                split -l 2000 "$file" "$temp_dir/chunk_"

                for chunk_file in "$temp_dir"/chunk_*; do
                    [ -f "$chunk_file" ] || continue

                    if $USE_TRANSLATE; then
                        PROMPT="Translate the following text to clear, fluent English:"
                    else
                        PROMPT="Summarize in detail and explain the following text:"
                    fi

                    if $USE_MEMORY; then
                        ollama run granite3.2:8b \
"Use the following prior memory as background context. Do not summarize or translate the memory itself unless relevant.

$MEMORY_CONTEXT

$PROMPT" \
                        < "$chunk_file" | tee -a "$main_dir/$summary_file"
                    else
                        ollama run granite3.2:8b \
"$PROMPT" \
                        < "$chunk_file" | tee -a "$main_dir/$summary_file"
                    fi

                    echo "" >> "$main_dir/$summary_file"
                done

                rm -rf "$temp_dir"
                echo "$file_name" >> "$main_dir/$progress_file"
            fi
        fi
    done
}

# ===============================
# Recursive traversal
# ===============================
process_subdirectories() {
    local parent_dir=$1

    for dir in "$parent_dir"/*/; do
        [ -d "$dir" ] || continue
        process_files "$dir"
        process_subdirectories "$dir"
    done
}

# ===============================
# Main execution
# ===============================
process_files "$main_dir"
process_subdirectories "$main_dir"

echo "Script completed at $(date)" >> "$main_dir/$progress_file"
