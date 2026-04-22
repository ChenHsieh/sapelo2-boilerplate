#!/usr/bin/env bash
# Claude Code status line for Sapelo2 HPC
# Reads JSON from stdin, uses Python to parse (jq not available on Sapelo2)

input=$(cat)

eval "$(echo "$input" | python3 -c "
import sys, json, os, time

d = json.load(sys.stdin)

def g(*keys):
    v = d
    for k in keys:
        if isinstance(v, dict):
            v = v.get(k)
        else:
            return ''
    return '' if v is None else str(v)

cwd = g('workspace','current_dir') or g('cwd')
model = g('model','display_name')
ctx_used = g('context_window','used_percentage')
ctx_size = g('context_window','context_window_size')
five_pct = g('rate_limits','five_hour','used_percentage')
five_resets = g('rate_limits','five_hour','resets_at')
seven_pct = g('rate_limits','seven_day','used_percentage')
seven_resets = g('rate_limits','seven_day','resets_at')

# Cost & stats
total_cost = g('cost','total_cost_usd')
total_duration_ms = g('cost','total_duration_ms')
lines_added = g('cost','total_lines_added')
lines_removed = g('cost','total_lines_removed')
input_tokens = g('context_window','total_input_tokens')
output_tokens = g('context_window','total_output_tokens')

# shell-safe quoting
def sq(s):
    return \"'\" + s.replace(\"'\", \"'\\\\''\") + \"'\"

print(f'cwd={sq(cwd)}')
print(f'model={sq(model)}')
print(f'ctx_used={sq(ctx_used)}')
print(f'ctx_size={sq(ctx_size)}')
print(f'five_pct={sq(five_pct)}')
print(f'five_resets={sq(five_resets)}')
print(f'seven_pct={sq(seven_pct)}')
print(f'seven_resets={sq(seven_resets)}')
print(f'total_cost={sq(total_cost)}')
print(f'total_duration_ms={sq(total_duration_ms)}')
print(f'lines_added={sq(lines_added)}')
print(f'lines_removed={sq(lines_removed)}')
print(f'input_tokens={sq(input_tokens)}')
print(f'output_tokens={sq(output_tokens)}')
")"

# ---------------------------------------------------------------------------
# Helper: is a value a valid positive number (not empty / null / 0)?
# ---------------------------------------------------------------------------
is_valid_pct() {
    local v="$1"
    [[ -n "$v" && "$v" != "null" && "$v" != "0" && "$v" != "0.0" ]]
}

# ---------------------------------------------------------------------------
# Shorten well-known path prefixes
# ---------------------------------------------------------------------------
cwd_display="$cwd"
cwd_display="${cwd_display/#\/home\/$USER/~}"
cwd_display="${cwd_display/#\/scratch\/$USER/scratch:}"
cwd_display="${cwd_display/#\/work\/YOURLAB/work:}"

# Conda env (inherited from the shell that launched claude)
conda_env="${CONDA_DEFAULT_ENV:-}"

# ---------------------------------------------------------------------------
# ANSI color codes
# ---------------------------------------------------------------------------
RST="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
MAGENTA="\033[35m"
BLUE="\033[34m"
WHITE="\033[37m"
GRAY="\033[90m"

# ---------------------------------------------------------------------------
# Pick bar color based on percentage: green < 50, yellow < 80, red >= 80
# ---------------------------------------------------------------------------
pct_color() {
    local pct_int=$(printf "%.0f" "$1")
    if [ "$pct_int" -ge 80 ]; then
        printf "%s" "$RED"
    elif [ "$pct_int" -ge 50 ]; then
        printf "%s" "$YELLOW"
    else
        printf "%s" "$GREEN"
    fi
}

# ---------------------------------------------------------------------------
# Build a colorized progress bar: make_bar <percent_float> <width>
# ---------------------------------------------------------------------------
make_bar() {
    local pct="$1"
    local width="${2:-10}"
    local filled=$(printf "%.0f" "$(echo "$pct $width" | awk '{printf "%.6f", $1/100*$2}')")
    local empty=$(( width - filled ))
    local color
    color=$(pct_color "$pct")
    local bar="" i
    for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
    local tail=""
    for (( i=0; i<empty;  i++ )); do tail="${tail}░"; done
    printf "%b%s%b%s%b" "$color" "$bar" "$GRAY" "$tail" "$RST"
}

# ---------------------------------------------------------------------------
# Format unix epoch as wall clock reset time: fmt_reset <epoch_seconds>
# ---------------------------------------------------------------------------
fmt_reset() {
    local target="$1"
    local now; now=$(date +%s)
    [ "$target" -le "$now" ] && { echo "now"; return; }
    date -d "@${target}" +"%I:%M %p" 2>/dev/null || date -r "$target" +"%I:%M %p" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Format context window size as short string: fmt_ctx_size <tokens>
# ---------------------------------------------------------------------------
fmt_ctx_size() {
    local n="$1"
    [[ -z "$n" || "$n" == "null" ]] && return
    if [ "$n" -ge 1000000 ]; then
        printf "%.1fM" "$(echo "$n" | awk '{printf "%.1f", $1/1000000}')"
    elif [ "$n" -ge 1000 ]; then
        printf "%dK" $(( n / 1000 ))
    else
        printf "%d" "$n"
    fi
}

# ---------------------------------------------------------------------------
# Format duration from ms: fmt_duration <milliseconds>
# ---------------------------------------------------------------------------
fmt_duration() {
    local ms="$1"
    [[ -z "$ms" || "$ms" == "null" ]] && return
    local total_sec=$(( ${ms%.*} / 1000 ))
    local h=$(( total_sec / 3600 ))
    local m=$(( (total_sec % 3600) / 60 ))
    local s=$(( total_sec % 60 ))
    if [ "$h" -gt 0 ]; then
        printf "%dh %02dm" "$h" "$m"
    elif [ "$m" -gt 0 ]; then
        printf "%dm %02ds" "$m" "$s"
    else
        printf "%ds" "$s"
    fi
}

# ---------------------------------------------------------------------------
# Format cost: fmt_cost <usd_float>
# ---------------------------------------------------------------------------
fmt_cost() {
    local c="$1"
    [[ -z "$c" || "$c" == "null" ]] && return
    # Show 2 decimal places, or 4 if very small
    local cents
    cents=$(echo "$c" | awk '{printf "%.2f", $1}')
    if [ "$cents" = "0.00" ]; then
        printf "\$%s" "$(echo "$c" | awk '{printf "%.4f", $1}')"
    else
        printf "\$%s" "$cents"
    fi
}

# ---------------------------------------------------------------------------
# LINE 1: path | conda env | model | elapsed time
# ---------------------------------------------------------------------------
line1=""
if [ -n "$cwd_display" ]; then
    line1=$(printf "%b%s%b" "${BOLD}${BLUE}" "$cwd_display" "$RST")
fi
if [ -n "$conda_env" ] && [ "$conda_env" != "base" ]; then
    [ -n "$line1" ] && line1="${line1}$(printf " %b│%b " "$GRAY" "$RST")"
    line1="${line1}$(printf "%b🐍 %s%b" "${GREEN}" "$conda_env" "$RST")"
fi
if [ -n "$model" ]; then
    [ -n "$line1" ] && line1="${line1}$(printf " %b│%b " "$GRAY" "$RST")"
    line1="${line1}$(printf "%b%s%b" "${MAGENTA}" "$model" "$RST")"
fi
if [ -n "$total_duration_ms" ] && [ "$total_duration_ms" != "null" ]; then
    [ -n "$line1" ] && line1="${line1}$(printf " %b│%b " "$GRAY" "$RST")"
    line1="${line1}$(printf "%b⏱ %s%b" "${CYAN}" "$(fmt_duration "$total_duration_ms")" "$RST")"
fi

# ---------------------------------------------------------------------------
# LINE 2: context window progress bar
# ---------------------------------------------------------------------------
line2=""
if [ -n "$ctx_used" ] && [ "$ctx_used" != "null" ]; then
    ctx_int=$(printf "%.0f" "$ctx_used")
    bar=$(make_bar "$ctx_used" 20)
    size_str=""
    if [ -n "$ctx_size" ] && [ "$ctx_size" != "null" ]; then
        size_str=$(printf " %b/%b %b%s%b" "$GRAY" "$RST" "$CYAN" "$(fmt_ctx_size "$ctx_size")" "$RST")
    fi
    color=$(pct_color "$ctx_used")
    line2=$(printf "%b ctx %b %s %b%s%%%b%b" "$WHITE" "$RST" "$bar" "$color" "$ctx_int" "$RST" "$size_str")
fi

# ---------------------------------------------------------------------------
# LINE 3: rate limits
# ---------------------------------------------------------------------------
line3=""

if is_valid_pct "$five_pct"; then
    five_int=$(printf "%.0f" "$five_pct")
    bar=$(make_bar "$five_pct" 10)
    color=$(pct_color "$five_pct")
    reset_str=""
    if [ -n "$five_resets" ] && [ "$five_resets" != "null" ]; then
        reset_str=$(printf " %b~%s%b" "$GRAY" "$(fmt_reset "$five_resets")" "$RST")
    fi
    line3=$(printf "%b 5h  %b %s %b%s%%%b%b" "$WHITE" "$RST" "$bar" "$color" "$five_int" "$RST" "$reset_str")
fi

if is_valid_pct "$seven_pct"; then
    seven_int=$(printf "%.0f" "$seven_pct")
    bar=$(make_bar "$seven_pct" 10)
    color=$(pct_color "$seven_pct")
    reset_str=""
    if [ -n "$seven_resets" ] && [ "$seven_resets" != "null" ]; then
        reset_str=$(printf " %b~%s%b" "$GRAY" "$(fmt_reset "$seven_resets")" "$RST")
    fi
    local_7d=$(printf "%b 7d  %b %s %b%s%%%b%b" "$WHITE" "$RST" "$bar" "$color" "$seven_int" "$RST" "$reset_str")
    if [ -n "$line3" ]; then
        line3="${line3}$(printf " %b│%b " "$GRAY" "$RST")${local_7d}"
    else
        line3="$local_7d"
    fi
fi

# ---------------------------------------------------------------------------
# LINE 4: cost | tokens | lines edited
# ---------------------------------------------------------------------------
line4_parts=()

if [ -n "$total_cost" ] && [ "$total_cost" != "null" ] && [ "$total_cost" != "0" ]; then
    line4_parts+=("$(printf "%b💰 %s%b" "${YELLOW}" "$(fmt_cost "$total_cost")" "$RST")")
fi

if [ -n "$input_tokens" ] && [ "$input_tokens" != "null" ]; then
    tok_str=""
    if [ -n "$output_tokens" ] && [ "$output_tokens" != "null" ]; then
        tok_str=$(printf "%b⬇ %b%s %b⬆ %b%s" "${GREEN}" "$RST" "$(fmt_ctx_size "$input_tokens")" "${RED}" "$RST" "$(fmt_ctx_size "$output_tokens")")
    else
        tok_str=$(printf "%s tok" "$(fmt_ctx_size "$input_tokens")")
    fi
    line4_parts+=("$tok_str")
fi

if [ -n "$lines_added" ] && [ "$lines_added" != "null" ]; then
    edit_str=$(printf "%b+%s%b" "${GREEN}" "$lines_added" "$RST")
    if [ -n "$lines_removed" ] && [ "$lines_removed" != "null" ] && [ "$lines_removed" != "0" ]; then
        edit_str="${edit_str}$(printf " %b-%s%b" "${RED}" "$lines_removed" "$RST")"
    fi
    edit_str=$(printf "%b✎ %b%s" "${WHITE}" "$RST" "$edit_str")
    line4_parts+=("$edit_str")
fi

line4=""
if [ "${#line4_parts[@]}" -gt 0 ]; then
    sep=$(printf " %b│%b " "$GRAY" "$RST")
    first=true
    for part in "${line4_parts[@]}"; do
        if $first; then
            line4=" $part"
            first=false
        else
            line4="${line4}${sep}${part}"
        fi
    done
fi

# ---------------------------------------------------------------------------
# Emit all non-empty lines
# ---------------------------------------------------------------------------
[ -n "$line1" ] && printf "%b\n" "$line1"
[ -n "$line2" ] && printf "%b\n" "$line2"
[ -n "$line3" ] && printf "%b\n" "$line3"
[ -n "$line4" ] && printf "%b\n" "$line4"
