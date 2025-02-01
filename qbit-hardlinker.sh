#!/bin/bash

# Get the download path
download_path="$1"

# This is the base path that qbittorent downloads into
base_path="/data/torrents"

# The destination folder 
#
# This is where we want our hardlinks to end up, must be on the same filesystem.
destination="/data/torrents/done"

# Optional logging
enable_logging=true
log_file="/config/qbit-linker.log"

# Optional empty directory cleanup
enable_cleanup=false

# Validate that the required parameter has been passed
if [ -z "$download_path" ]; then
  echo "Error: missing required parameter."
  echo "Usage: $0 <download path>"
  exit 1
fi

# see what the download path looks like
echo -e "\n$(date +%Y-%m-%d\ %H.%M.%S) Starting with download path: $download_path" >> "$log_file"

# Create destination directory if it doesn't exist
mkdir -p "$destination"

# Function to create a hard link
create_hardlink() {
    src_file="$1"
    dest_file="$2"
    ln "$src_file" "$dest_file"
    [ "$enable_logging" = true ] && echo "Created hardlink: $src_file -> $dest_file" >> "$log_file"
}

# Save current IFS
OLD_IFS=$IFS
# Set IFS to newline only
IFS=$'\n'

# Process each dir in the download path
find "$download_path" -type d | while read -r dir; do
    # Extract relative path
    relative_path="${dir#"$base_path"/}"
    dir_path="$destination/$relative_path"
    mkdir -p "$dir_path"
    [ "$enable_logging" = true ] && echo "Created directory structure: $dir_path" >> "$log_file"
done

find "$download_path" -type f | while read -r file; do
    # Extract relative path
    relative_path="${file#"$base_path"/}"

    # check if relative path has any folders in it, and create them if needed
    if [[ $relative_path == *"/"* ]]; then
        dir_path="${relative_path%/*}"
        echo "Dir path: $dir_path"
        mkdir -p "$destination/$dir_path"
        [ "$enable_logging" = true ] && echo "Created directory structure: $destination/$dir_path" >> "$log_file"
    fi

    # Create hard link
    create_hardlink "$file" "$destination/$relative_path"
done

# Clean up empty folders from previous runs
[ "$enable_cleanup" = true ] && find $destination -mindepth 2 -type d -empty -exec rmdir {} \; 2>/dev/null

# Restore original IFS
IFS=$OLD_IFS

echo "qbit-hardlinker task successful"
[ "$enable_logging" = true ] && echo "$(date +%Y-%m-%d\ %H.%M.%S) qbit-hardlinker task completed" >> "$log_file"
