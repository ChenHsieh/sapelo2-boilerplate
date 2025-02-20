## I had multiple runs and ended up having duplicated files in separated dir thus this script

import os
import hashlib
import shutil

# Directories
dir1 = "HAP1_out_remaining"
dir2 = "HAP1_out"
merged_dir = "HAP1_omegafold"

def hash_file(filepath):
    """Generate MD5 hash for file content."""
    hasher = hashlib.md5()
    with open(filepath, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hasher.update(chunk)
    return hasher.hexdigest()

def merge_and_remove_redundant_files(dir1, dir2, merged_dir):
    """Merge files, remove redundant ones, and report stats."""
    if not os.path.exists(merged_dir):
        os.makedirs(merged_dir)

    # Collect files and hashes
    file_hashes = {}
    total_files = 0
    redundant_files = 0

    for directory in [dir1, dir2]:
        for root, _, files in os.walk(directory):
            for file in files:
                total_files += 1
                filepath = os.path.join(root, file)
                file_hash = hash_file(filepath)

                if file_hash in file_hashes:
                    redundant_files += 1
                else:
                    file_hashes[file_hash] = file
                    shutil.copy(filepath, os.path.join(merged_dir, file))

    print(f"Total files processed: {total_files}")
    print(f"Redundant files removed: {redundant_files}")
    print(f"Unique files retained: {len(file_hashes)}")


# Merge files and remove redundancies
merge_and_remove_redundant_files(dir1, dir2, merged_dir)

