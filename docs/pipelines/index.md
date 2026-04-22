# Pipelines

Snakemake pipelines live in [`pipeline/`](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/pipeline) in the repo.

| Pipeline | What | Source |
|---|---|---|
| yt_whisper | YouTube URL → audio → Whisper transcription. V100, <4 h on `batch`. | [pipeline/yt_whisper](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/pipeline/yt_whisper) |
| get_best_hit | Cross-species DIAMOND best-hits for transcriptome annotation. | [pipeline/get_best_hit](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/pipeline/get_best_hit) |

For larger pipelines, consider a Snakemake Slurm profile so each rule becomes its own sbatch with per-rule resources — see the `--profile` flag in the [Snakemake docs](https://snakemake.readthedocs.io/en/stable/executing/cluster.html).
