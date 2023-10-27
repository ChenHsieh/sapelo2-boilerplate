import pandas as pd
import argparse

def extract_best_hit(diamond_result):
    df = pd.read_csv(diamond_result, sep='\t', header=None)
    # Assuming the first column is query ID and second column is subject ID
    best_hits = df.groupby(0).first()[1].to_dict()
    return best_hits

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Extract best hits from DIAMOND BLAST results.')
    parser.add_argument('--arabidopsis', required=True)
    parser.add_argument('--oryza', required=True)
    parser.add_argument('--glycine', required=True)
    parser.add_argument('--medicago', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    # Extract best hits
    arabidopsis_best = extract_best_hit(args.arabidopsis)
    oryza_best = extract_best_hit(args.oryza)
    glycine_best = extract_best_hit(args.glycine)
    medicago_best = extract_best_hit(args.medicago)
    
    # Combine and write to CSV
    combined_dict = {'query_Peptide_ID': list(arabidopsis_best.keys()),
                     'Arabidopsis_best_hit': list(arabidopsis_best.values()),
                     'Oryza_best_hit': [oryza_best.get(k, 'NA') for k in arabidopsis_best.keys()],
                     'Glycine_best_hit': [glycine_best.get(k, 'NA') for k in arabidopsis_best.keys()],
                     'Medicago_best_hit': [medicago_best.get(k, 'NA') for k in arabidopsis_best.keys()]}
    combined_df = pd.DataFrame.from_dict(combined_dict)
    combined_df.to_csv(args.output, index=False)
