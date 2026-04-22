# Pipelines

Snakemake pipelines designed for Sapelo2 — each submits as a single sbatch job that spawns parallel rules internally. For larger pipelines, migrate to a Snakemake Slurm profile so each rule becomes its own sbatch with per-rule resources.

<div class="grid cards" markdown>

-   :material-video-outline: __yt_whisper__

    ---

    YouTube URL → audio → Whisper transcription. GPU-accelerated (V100, <4h on batch).

    [:octicons-arrow-right-24: yt_whisper](yt-whisper.md)

-   :material-dna: __get_best_hit__

    ---

    Cross-species DIAMOND best-hits for functional annotation of novel transcriptomes.

    [:octicons-arrow-right-24: get_best_hit](get-best-hit.md)

</div>
