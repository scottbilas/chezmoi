#!/usr/bin/env bash
#
# Reusable library for running a command across all non-bare git worktrees in parallel.
#
# Usage:
#   source "/path/to/lib/parallel-worktrees.sh"
#   pwt_run <worker-cmd> [worker-args...]
#
# The worker command is invoked as:
#   <worker-cmd> [worker-args...] <worktree-path> <output-file>
#
# The worker writes its result to <output-file>. After pwt_run completes,
# results are available via pwt_cat_results or pwt_result_for.
# Caller is responsible for calling pwt_cleanup when done.

# Detect CPU count: macOS perf cores, Linux nproc, Windows env var, or default to 4
pwt_ncpus() {
    sysctl -n hw.perflevel0.logicalcpu 2>/dev/null || nproc 2>/dev/null || echo "${NUMBER_OF_PROCESSORS:-4}"
}

# Globals set by pwt_run
_PWT_OUTDIR=""

# Run worker command across all non-bare worktrees in parallel.
# Arguments: <worker-cmd> [worker-args...]
# The worker will receive: [worker-args...] <worktree-path> <output-file>
pwt_run() {
    local worker_cmd="$1"
    shift
    local worker_args=("$@")

    _PWT_OUTDIR="$(mktemp -d)"
    local ncpus
    ncpus=$(pwt_ncpus)

    # Unset GIT_DIR to avoid confusion in sub-shells (git-sh-setup sets it)
    unset GIT_DIR

    # Enumerate non-bare worktrees, pipe to parallel workers
    git worktree list | awk '{print $1}' | while IFS= read -r path; do
        # skip bare repos (no .git file/dir means bare)
        if [[ -d "$path/.git" || -f "$path/.git" ]]; then
            echo "$path"
        fi
    done | xargs -I {} -P "$ncpus" -n 1 \
        "$worker_cmd" "${worker_args[@]}" {} "$_PWT_OUTDIR"
}

# Output all results, sorted by filename (worktree basename).
# Usage: pwt_cat_results [separator]
pwt_cat_results() {
    local sep="${1:-}"
    local first=true
    for f in "$_PWT_OUTDIR"/*; do
        [[ -f "$f" ]] || continue
        if $first; then
            first=false
        elif [[ -n "$sep" ]]; then
            printf '%s' "$sep"
        fi
        cat "$f"
    done
}

# Read the result for a specific worktree path (by its basename).
pwt_result_for() {
    local wt_path="$1"
    local base
    base=$(basename "$wt_path")
    local f="$_PWT_OUTDIR/$base"
    [[ -f "$f" ]] && cat "$f"
}

# Clean up temp directory.
pwt_cleanup() {
    [[ -n "$_PWT_OUTDIR" && -d "$_PWT_OUTDIR" ]] && rm -rf "$_PWT_OUTDIR"
    _PWT_OUTDIR=""
}
