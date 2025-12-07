#!/bin/bash

# Define progress and summary files
progress_file="progress.log"
summary_file="antivenom-overview.txt"
main_dir=$(pwd)

# Function to check if a file is already processed
is_processed() {
    grep -Fxq "$1" "$main_dir/$progress_file"
}

# Create progress and summary files if they don't exist
touch "$main_dir/$progress_file"
touch "$main_dir/$summary_file"

echo "Script started at $(date)" >> "$main_dir/$progress_file"
echo "Summaries will be saved to $summary_file" >> "$main_dir/$progress_file"



process_files() {
    local dir=$1
    echo "Processing directory: $dir"

    # Iterate over .txt and .md
    for file in "$dir"/*.{txt,md}; do
        
        [ -e "$file" ] || continue

        # Skip the main summary file
        if [ "$(basename "$file")" == "$summary_file" ]; then
            continue
        fi

        if [ -f "$file" ]; then
            local file_name=$(basename "$file")

            if ! is_processed "$file_name"; then
                echo "Processing $file_name"
                echo "Processing $file_name" >> "$main_dir/$progress_file"

                sanitized_name=$(basename "$file" | tr -d '[:space:]')
                temp_dir=$(mktemp -d "$dir/tmp_${sanitized_name}_XXXXXX")

                # Convert Markdown to plain text if needed
                temp_text="$temp_dir/converted.txt"
                if [[ "$file" == *.md ]]; then
                    pandoc "$file" -t plain -o "$temp_text"
                else
                    cp "$file" "$temp_text"
                fi

                # Split converted version
                split -l 1000 "$temp_text" "$temp_dir/chunk_"

                # Summarize each chunk
                for chunk_file in "$temp_dir"/chunk_*; do
                    [ -f "$chunk_file" ] || continue

                    echo "Summarizing chunk: $(basename "$chunk_file")"
                    ollama run granite3.2:8b "Summarize in detail and explain:" < "$chunk_file" \
                        | tee -a "$main_dir/$summary_file"

                    echo "" >> "$main_dir/$summary_file"
                done

                rm -rf "$temp_dir"
                echo "$file_name" >> "$main_dir/$progress_file"
            fi
        fi
    done
}

process_subdirectories() {
    local parent_dir=$1
    for dir in "$parent_dir"/*/; do
        if [ -d "$dir" ]; then
            process_files "$dir"
            process_subdirectories "$dir"
        fi
    done
}

process_files "$main_dir"
process_subdirectories "$main_dir"

echo "Script completed at $(date)" >> "$main_dir/$progress_file"
