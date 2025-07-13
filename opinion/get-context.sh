#!/bin/bash

# Define progress and summary files
progress_file="progress.log"
summary_file="attention-economy.txt"
summary_file_01="attention-economy-01memory.txt"
summary_file_02="attention-economy-02memory.txt"
source_file="source"
main_dir=$(pwd)

# Function to check if a file is already processed
is_processed() {
    grep -Fxq "$1" "$main_dir/$progress_file"
}

# Create progress and summary files if they don't exist
touch "$main_dir/$progress_file"
touch "$main_dir/$summary_file"
touch "$main_dir/$summary_file_01"
touch "$main_dir/$summary_file_02"

# Start logging script progress
echo "Script started at $(date)" >> "$main_dir/$progress_file"
echo "Summaries will be saved to $summary_file, $summary_file_01, and $summary_file_02" >> "$main_dir/$progress_file"

# Function to process text files in a directory
process_files() {
    local dir=$1
    echo "Processing directory: $dir"
    
    # Iterate over each .txt file in the specified directory
    for file in "$dir"/*.txt; do
        # Skip if no .txt files are found
        if [ ! -e "$file" ]; then
            continue
        fi

        # Skip processing the summary files, memory files, and source file
        if [ "$(basename "$file")" == "$summary_file" ] || [ "$(basename "$file")" == "$summary_file_01" ] || [ "$(basename "$file")" == "$summary_file_02" ] || [ "$(basename "$file")" == "01.memory" ] || [ "$(basename "$file")" == "02.memory" ] || [ "$(basename "$file")" == "$source_file" ]; then
            echo "Skipping summary, memory, or source file: $(basename "$file")"
            continue
        fi

        # Process the file if it's a regular file
        if [ -f "$file" ]; then
            local file_name=$(basename "$file")  # Get the file name only
            
            # Process only if not processed before
            if ! is_processed "$file_name"; then
                echo "Processing $file_name"
                echo "Processing $file_name" >> "$main_dir/$progress_file"

                # Create a temporary directory for the file's chunks
                sanitized_name=$(basename "$file" | tr -d '[:space:]')
                temp_dir=$(mktemp -d "$dir/tmp_${sanitized_name}_XXXXXX")
                echo "Temporary directory created: $temp_dir" >> "$main_dir/$progress_file"

                # Split the file into chunks of 100 lines each
                split -l 100 "$file" "$temp_dir/chunk_"
                echo "File split into chunks: $(find "$temp_dir" -type f)" >> "$main_dir/$progress_file"

                # Extract metadata from source file if it exists
                local metadata=""
                if [ -f "$main_dir/$source_file" ]; then
                    metadata="Source File: $file_name\n$(cat "$main_dir/$source_file" | grep -E 'Title:|Interviewer:|Interviewee:')\n\n"
                else
                    metadata="Source File: $file_name\nWarning: Source file not found\n\n"
                    echo "Warning: Source file not found for $file_name" >> "$main_dir/$progress_file"
                fi

                # Summarize each chunk and append to the respective summary files
                for chunk_file in "$temp_dir"/chunk_*; do
                    [ -f "$chunk_file" ] || continue
                    local chunk_name=$(basename "$chunk_file")
                    echo "Summarizing chunk: $chunk_name"
                    
                    # Original summary (with source file and metadata)
                    if [ -f "$main_dir/$source_file" ]; then
                        echo -e "$metadata" | tee -a "$main_dir/$summary_file"
                        cat "$main_dir/$source_file" "$chunk_file" | ollama run granite3.2:8b "Summarize in detail and explain:" | tee -a "$main_dir/$summary_file"
                        echo "" >> "$main_dir/$summary_file"
                    else
                        echo -e "$metadata" | tee -a "$main_dir/$summary_file"
                        ollama run granite3.2:8b "Summarize in detail and explain:" < "$chunk_file" | tee -a "$main_dir/$summary_file"
                        echo "" >> "$main_dir/$summary_file"
                    fi
                    
                    # Summary with 01.memory (no source file, no metadata)
                    if [ -f "$main_dir/01.memory" ]; then
                        cat "$main_dir Infantry/01.memory" "$chunk_file" | ollama run granite3.2:8b "Summarize in detail and explain:" | tee -a "$main_dir/$summary_file_01"
                        echo "" >> "$main_dir/$summary_file_01"
                    else
                        ollama run granite3.2:8b "Summarize in detail and explain:" < "$chunk_file" | tee -a "$main_dir/$summary_file_01"
                        echo "" >> "$main_dir/$summary_file_01"
                        echo "Warning: 01.memory not found, skipping 01.memory inclusion for $chunk_name" >> "$main_dir/$progress_file"
                    fi
                    
                    # Summary with 02.memory (no source file, no metadata)
                    if [ -f "$main_dir/02.memory" ]; then
                        cat "$main_dir/02.memory" "$chunk_file" | ollama run granite3.2:8b "Summarize in detail and explain:" | tee -a "$main_dir/$summary_file_02"
                        echo "" >> "$main_dir/$summary_file_02"
                    else
                        ollama run granite3.2:8b "Summarize in detail and explain:" < "$chunk_file" | tee -a "$main_dir/$summary_file_02"
                        echo "" >> "$main_dir/$summary_file_02"
                        echo "Warning: 02.memory not found, skipping 02.memory inclusion for $chunk_name" >> "$main_dir/$progress_file"
                    fi
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
# process_subdirectories() {
#    local parent_dir=$1
#    
#    # Iterate over all subdirectories
#    for dir in "$parent_dir"/*/; do
#        if [ -d "$dir" ]; then
#            process_files "$dir"  # Process files in the subdirectory
#            process_subdirectories "$dir"  # Recursive call for nested subdirectories
#        fi
#    done
#}

# Main execution
process_files "$main_dir"  # Process files in the main directory
# process_subdirectories "$main_dir"  # Process files in subdirectories

# Mark script completion
echo "Script completed at $(date)" >> "$main_dir/$progress_file"