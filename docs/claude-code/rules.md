!!! abstract "This is the live `CLAUDE.md`"
    This page is rendered directly from [`claude-code/CLAUDE.md`](https://github.com/ChenHsieh/sapelo2-boilerplate/blob/main/claude-code/CLAUDE.md) — the file Claude Code loads at startup. Date-stamped sections (QOS table, module versions) are flagged when they were last verified. Re-verify with `module avail` and `sacctmgr show qos` before trusting them for critical decisions.

!!! success "QOS table verified"
    Last queried from Slurm: **2026-04-07**. Module versions: **2026-04**. Re-run the authoritative commands before trusting:

    ```bash
    sacctmgr show qos format=Name,MaxWall,MaxSubmitPU,MaxJobsPU
    module avail Miniforge3
    sinfo -p gpu_p -N -o "%N %G %C %e %T"
    ```

--8<-- "claude-code/CLAUDE.md"
