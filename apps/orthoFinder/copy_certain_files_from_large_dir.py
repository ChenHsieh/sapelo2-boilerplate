# copy analysis files of orphan genes 
# so that I can download them batchly

import shutil
import pandas as pd
import os
unassigned_file_path = '/scratch/ch29576/comparativeGenomic/common-scripts/testing_data/Orthogroups_UnassignedGenes.tsv'
unassigned_df = pd.read_csv(unassigned_file_path, delimiter="\t")
species_list = unassigned_df.columns[1:]
species_csv = pd.read_csv('/scratch/ch29576/comparativeGenomic/common-scripts/testing_data/comp_geno_species.csv')
species_csv = species_csv.set_index('species_long')
number_list = []
tmhmm_path = '/scratch/ch29576/comparativeGenomic/TMHMM'
deepcoil_path = '/scratch/ch29576/comparativeGenomic/deepcoil_result/'
for species in species_list:
    species_p_name = species_csv.loc[species].species_p
    tmhmm_folder_name = os.path.join(tmhmm_path, species_p_name) 
    deepcoil_folder_name = os.path.join(deepcoil_path, species_p_name) 
    unassigned_genes = unassigned_df[species].dropna()
    cp_target = f'/scratch/ch29576/comparativeGenomic/0202orphan_info/{species_p_name}'
    os.mkdir(cp_target)
    for unassigned_gene in unassigned_genes:
        gnuplot_file_name = f'{unassigned_gene}.gnuplot'
        gif_file_name = f'{unassigned_gene}.gif'
        plp_file_name = f'{unassigned_gene}.plp'
        for file_name in [gnuplot_file_name, gif_file_name, plp_file_name]:
            original = os.path.join(tmhmm_folder_name, file_name)
            target = os.path.join(cp_target, file_name)
            try:
                shutil.copyfile(original, target)
            except:
                print(original)
        png_file_name = f'{unassigned_gene}.png'
        out_file_name = f'{unassigned_gene}.out'
        
        for file_name in [png_file_name, out_file_name]:
            original = os.path.join(deepcoil_folder_name, file_name)
            target = os.path.join(cp_target, file_name)
            try:
                shutil.copyfile(original, target)
            except:
                print(original)
        
        
        