# sbatch templates

Two starter scripts live in [`generic_template/`](https://github.com/ChenHsieh/sapelo2-boilerplate/tree/main/generic_template) — copy, rename, customize.

## CPU + conda

```bash title="generic_template/conda.sh"
--8<-- "generic_template/conda.sh"
```

**When to use:** any non-GPU work that relies on a conda env. Defaults to `highmem_p` with 480 GB memory — tune down for smaller jobs.

## Single GPU

```bash title="generic_template/gpu.sh"
--8<-- "generic_template/gpu.sh"
```

**When to use:** any GPU workload under 4 hours. Requests V100 from the `batch` partition (allowed for <4h jobs). For longer runs or bigger GPUs, switch to `gpu_p` or `gpu_30d_p` and specify `--gres=gpu:A100:1` / `L4:1` / `H100:1`.

## Conventions used across the repo

- Shebang: `#!/bin/bash` (never `#!/bin/sh` — sbatch scripts often need bash features)
- Log files: `%x.%j.out` / `%x.%j.err` pattern — `%x` is the job name, `%j` the job ID
- Email placeholder: `youremail@uga.edu` — replace with your own before submitting
- `cd "$SLURM_SUBMIT_DIR"` near the top so relative paths in the script behave
- `source activate env` inside sbatch, never `conda activate` ([why](../claude-code/index.md#managing-multiple-conda-environments))

## Right-size resources before submitting

!!! tip "Check before you ask"
    ```bash
    sinfo -p gpu_p -N -o "%N %G %C %e %T"   # per-node GPU/CPU/memory
    sinfo -o "%P %a %D %T %C"               # quick all-partition summary
    ```

Over-requesting wastes queue priority. After a test run, `seff <jobID>` shows actual memory / CPU usage — tune the next submission from real numbers, not round-number guesses.

Full QOS + GPU hardware tables live in the [Claude Code ruleset](../claude-code/rules.md).
