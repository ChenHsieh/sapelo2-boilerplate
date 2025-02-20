# the omegaFold use the fasta header as output file name, leading to super long filename in my case when using files from JGI, thus this file to simplify the names for all file in the specified dir

import os

def simplify_filenames(directory):
    # Iterate through all files in the directory
    for filename in os.listdir(directory):
        if filename.endswith('.pdb'):  # Process only .pdb files
            # Split the filename to isolate the relevant part
            parts = filename.split(' ')
            if parts:
                # Extract the first part up to the .p
                base_name = parts[0]
                if base_name.endswith('.p'):
                    # Reconstruct the simplified filename
                    simplified_name = base_name + '.pdb'
                    # Form full paths for renaming
                    old_path = os.path.join(directory, filename)
                    new_path = os.path.join(directory, simplified_name)
                    # Rename the file
                    os.rename(old_path, new_path)
                    print(f"Renamed: {old_path} -> {new_path}")

# Provide the directory containing your files
directory_path = "HAP1_omegafold_backup" 
simplify_filenames(directory_path)

# Provide the directory containing your files
directory_path = "HAP2_omegafold_backup" 
simplify_filenames(directory_path)

