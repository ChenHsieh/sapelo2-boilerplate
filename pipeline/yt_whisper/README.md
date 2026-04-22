# yt_whisper

Snakemake pipeline: download audio from a YouTube URL, transcribe with OpenAI Whisper.

## Quick start

```bash
sbatch run.sh
```

Override the URL at submit time:

```bash
snakemake --cores all --config youtube_url="https://www.youtube.com/watch?v=..."
```

## Files

- `snakefile` — pipeline definition
- `config.yaml` — default URL and output paths
- `run.sh` — sbatch wrapper (V100, batch partition, <4h)

## Known limits

- Output filename is static across runs — overwrites previous output. Fix planned: use the video title.
