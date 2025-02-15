#!/bin/bash

# Define progress file
progress_file="progress.log"
main_dir=$(pwd)

# Function to check if a file is already processed
is_processed() {
    grep -Fxq "$1" "$main_dir/$progress_file"
}

# Create progress file if it doesn't exist
touch "$main_dir/$progress_file"

# Start logging script progress
{
    echo "Script started at $(date)"
} >> "$main_dir/$progress_file"

# Function to process text files in a directory
process_files() {
    local dir=$1
    echo "Processing directory: $dir"
    
    for file in "$dir"/*.txt; do
        # Skip if no .txt files are found
        [ -e "$file" ] || continue

        # Process the file if it's a regular file
        if [ -f "$file" ]; then
            local file_name=$(basename "$file")
            local summary_file="${file%.txt}-overview.txt"
            
            # Process only if not processed before
            if ! is_processed "$file_name"; then
                echo "Processing $file_name" | tee -a "$main_dir/$progress_file"

                # Create a temporary directory for the file's chunks
                sanitized_name=$(basename "$file" | tr -d '[:space:]')
                temp_dir=$(mktemp -d "$dir/tmp_${sanitized_name}_XXXXXX")
                echo "Temporary directory created: $temp_dir" >> "$main_dir/$progress_file"

                # Split the file into chunks of 88 lines each
                split -l 88 "$file" "$temp_dir/chunk_"
                echo "File split into chunks: $(find "$temp_dir" -type f)" >> "$main_dir/$progress_file"

                # Summarize each chunk and append to the file-specific summary file
                touch "$summary_file"
                for chunk_file in "$temp_dir"/chunk_*; do
                    [ -f "$chunk_file" ] || continue
                    echo "Summarizing chunk: $(basename "$chunk_file")"
                    ollama run vanilj/phi-4 "Summarize:" < "$chunk_file" | tee -a "$summary_file"
                    echo "" >> "$summary_file"
                done

                # Remove the temporary directory
                rm -rf "$temp_dir"
                echo "Temporary directory $temp_dir removed" >> "$main_dir/$progress_file"

                # Mark the file as processed
                echo "$file_name" >> "$main_dir/$progress_file"
            fi
        fi
    done
}

# Recursively process subdirectories
process_subdirectories() {
    local parent_dir=$1
    
    for dir in "$parent_dir"/*/; do
        if [ -d "$dir" ]; then
            process_files "$dir"  # Process files in the subdirectory
            process_subdirectories "$dir"  # Recursive call for nested subdirectories
        fi
    done
}

# Main execution
process_files "$main_dir"  # Process files in the main directory
process_subdirectories "$main_dir"  # Process files in subdirectories

# Mark script completion
echo "Script completed at $(date)" >> "$main_dir/$progress_file"