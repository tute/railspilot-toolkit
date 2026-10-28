#!/bin/bash
set -f

input=$(cat)

if [ -z "$input" ]; then
    printf "Claude"
    exit 0
fi

# ── Colors ──────────────────────────────────────────────
blue='\033[38;2;0;153;255m'
orange='\033[38;2;255;176;85m'
green='\033[38;2;0;175;80m'
cyan='\033[38;2;86;182;194m'
red='\033[38;2;255;85;85m'
yellow='\033[38;2;230;200;0m'
white='\033[38;2;220;220;220m'
magenta='\033[38;2;180;140;255m'
dim='\033[2m'
reset='\033[0m'

sep=" ${dim}·${reset} "

# ── Helpers ─────────────────────────────────────────────
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        awk "BEGIN {printf \"%.1fm\", $num / 1000000}"
    elif [ "$num" -ge 1000 ]; then
        awk "BEGIN {printf \"%.0fk\", $num / 1000}"
    else
        printf "%d" "$num"
    fi
}

color_for_pct() {
    local pct=$1
    if [ "$pct" -ge 90 ]; then printf "$red"
    elif [ "$pct" -ge 70 ]; then printf "$yellow"
    elif [ "$pct" -ge 50 ]; then printf "$orange"
    else printf "$green"
    fi
}

build_bar() {
    local pct=$1
    local width=$2
    [ "$pct" -lt 0 ] 2>/dev/null && pct=0
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100

    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    local bar_color
    bar_color=$(color_for_pct "$pct")

    local filled_str="" empty_str=""
    for ((i=0; i<filled; i++)); do filled_str+="●"; done
    for ((i=0; i<empty; i++)); do empty_str+="○"; done

    printf "${bar_color}${filled_str}${dim}${empty_str}${reset}"
}

iso_to_epoch() {
    local iso_str="$1"

    local epoch
    epoch=$(date -d "${iso_str}" +%s 2>/dev/null)
    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi

    local stripped="${iso_str%%.*}"
    stripped="${stripped%%Z}"
    stripped="${stripped%%+*}"
    stripped="${stripped%%-[0-9][0-9]:[0-9][0-9]}"

    if [[ "$iso_str" == *"Z"* ]] || [[ "$iso_str" == *"+00:00"* ]] || [[ "$iso_str" == *"-00:00"* ]]; then
        epoch=$(env TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
        [ -z "$epoch" ] && epoch=$(env TZ=UTC date -d "${stripped/T/ }" +%s 2>/dev/null)
    else
        epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$stripped" +%s 2>/dev/null)
        [ -z "$epoch" ] && epoch=$(date -d "${stripped/T/ }" +%s 2>/dev/null)
    fi

    if [ -n "$epoch" ]; then
        echo "$epoch"
        return 0
    fi

    return 1
}

format_countdown() {
    local secs=$1
    [ -z "$secs" ] && return
    [ "$secs" -le 0 ] 2>/dev/null && return
    if [ "$secs" -ge 3600 ]; then
        printf "%dh %dm" $(( secs / 3600 )) $(( (secs % 3600) / 60 ))
    elif [ "$secs" -ge 60 ]; then
        printf "%dm" $(( secs / 60 ))
    else
        printf "%ds" "$secs"
    fi
}

# ── Extract JSON data ───────────────────────────────────
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')

size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
[ "$size" -eq 0 ] 2>/dev/null && size=200000

input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
current=$(( input_tokens + cache_create + cache_read ))

used_tokens=$(format_tokens $current)
total_tokens=$(format_tokens $size)

if [ "$size" -gt 0 ]; then
    pct_used=$(( current * 100 / size ))
else
    pct_used=0
fi

effort=$(echo "$input" | jq -r '.effort.level // empty')
# Strip any parenthetical (e.g. "(1M context)") from the model name
model_short=$(echo "$model_name" | sed 's/ *([^)]*)//')

total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0' | awk '{printf "%.2f", $1}')

# ── LINE 1: Model (effort) │ Context % │ Directory (branch) │ Session │ Total ──
pct_color=$(color_for_pct "$pct_used")
cwd=$(echo "$input" | jq -r '.cwd // ""')
[ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd=$(pwd)
dirname=$(basename "$cwd")

git_branch=""
git_dirty=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git_branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$(git --no-optional-locks -C "$cwd" status --porcelain 2>/dev/null)" ]; then
        git_dirty="*"
    fi
fi

session_duration=""
session_start=$(echo "$input" | jq -r '.session.start_time // empty')
if [ -n "$session_start" ] && [ "$session_start" != "null" ]; then
    start_epoch=$(iso_to_epoch "$session_start")
    if [ -n "$start_epoch" ]; then
        now_epoch=$(date +%s)
        elapsed=$(( now_epoch - start_epoch ))
        if [ "$elapsed" -ge 3600 ]; then
            session_duration="$(( elapsed / 3600 ))h$(( (elapsed % 3600) / 60 ))m"
        elif [ "$elapsed" -ge 60 ]; then
            session_duration="$(( elapsed / 60 ))m"
        else
            session_duration="${elapsed}s"
        fi
    fi
fi

line1="${cyan}${dirname}${reset}"
if [ -n "$git_branch" ]; then
    line1+="${sep}${green}${git_branch}${red}${git_dirty}${reset}"
fi
line1+="${sep}"
line1+="${blue}${model_short}${reset}"
if [ -n "$effort" ]; then
    line1+=" ${dim}(${reset}${magenta}${effort}${dim})${reset}"
fi
line1+="${sep}"
line1+="${white}${used_tokens}${reset} ${pct_color}(${pct_used}%)${reset}"
if [ -n "$session_duration" ]; then
    line1+="${sep}${white}${session_duration}${reset}"
fi
line1+="${sep}"
line1+="${white}\$${total_cost}${reset}"

# ── Rate limit lines ────────────────────────────────────
rate_lines=""
bar_width=10

rate_cache="$HOME/.claude/statusline-rate-limits.json"
rate_limits=$(echo "$input" | jq -c '.rate_limits // empty')
if [ -n "$rate_limits" ]; then
    echo "$rate_limits" > "$rate_cache"
elif [ -f "$rate_cache" ]; then
    rate_limits=$(jq -c --argjson now "$(date +%s)" 'with_entries(select(.value.resets_at > $now))' "$rate_cache" 2>/dev/null)
fi

rate_line() {
    local label=$1 window=$2 prefix=$3 style=$4
    local pct reset_epoch reset_str countdown bar pct_color
    pct=$(echo "$rate_limits" | jq -r ".${window}.used_percentage // empty" | awk '{printf "%.0f", $1}')
    [ -z "$pct" ] && return
    reset_epoch=$(echo "$rate_limits" | jq -r ".${window}.resets_at // empty" | awk '{printf "%d", $1}')
    bar=$(build_bar "$pct" "$bar_width")
    pct_color=$(color_for_pct "$pct")
    printf "%s" "${white}${label}${reset} ${bar} ${pct_color}$(printf "%3d" "$pct")%${reset}"
    [ -z "$reset_epoch" ] && return
    if [ "$style" = "time" ]; then
        reset_str=$(date -r "$reset_epoch" +"%l:%M%p" 2>/dev/null || date -d "@$reset_epoch" +"%l:%M%P")
    else
        reset_str=$(date -r "$reset_epoch" +"%b %-d, %l:%M%p" 2>/dev/null || date -d "@$reset_epoch" +"%b %-d, %l:%M%P")
    fi
    reset_str=$(echo "$reset_str" | sed 's/  / /g; s/^ //' | tr '[:upper:]' '[:lower:]')
    printf "%s" " ${dim}${prefix}${reset} ${white}${reset_str}${reset}"
    if [ "$style" = "time" ]; then
        countdown=$(format_countdown $(( reset_epoch - $(date +%s) )))
        [ -n "$countdown" ] && printf "%s" " ${dim}(${countdown})${reset}"
    fi
}

five_hour_line=$(rate_line "current" "five_hour" "Resets at" "time")
seven_day_line=$(rate_line "weekly " "seven_day" "Resets on" "datetime")
[ -n "$five_hour_line" ] && rate_lines+="$five_hour_line"
if [ -n "$seven_day_line" ]; then
    [ -n "$rate_lines" ] && rate_lines+="\n"
    rate_lines+="$seven_day_line"
fi

# ── Output ──────────────────────────────────────────────
printf "%b" "$line1"
[ -n "$rate_lines" ] && printf "\n\n%b" "$rate_lines"

exit 0
