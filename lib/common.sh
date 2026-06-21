#!/usr/bin/env bash
# common.sh - shared helpers, config, and result collection for SysDoctor
# shellcheck shell=bash
# Globals defined here are consumed by the other lib/*.sh modules that source this file.
# shellcheck disable=SC2034

# --- Status levels (ordered by severity) ---
# Declared with -g so these stay global even if this file is sourced from
# inside a function (e.g. a test framework's setup() hook).
declare -gr STATUS_OK="OK"
declare -gr STATUS_WARNING="WARNING"
declare -gr STATUS_CRITICAL="CRITICAL"
declare -gr STATUS_UNKNOWN="UNKNOWN"

# --- Colors (disabled when not attached to a tty or NO_COLOR is set) ---
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    declare -gr COLOR_RED=$'\033[31m'
    declare -gr COLOR_GREEN=$'\033[32m'
    declare -gr COLOR_YELLOW=$'\033[33m'
    declare -gr COLOR_BLUE=$'\033[34m'
    declare -gr COLOR_BOLD=$'\033[1m'
    declare -gr COLOR_RESET=$'\033[0m'
else
    declare -gr COLOR_RED=""
    declare -gr COLOR_GREEN=""
    declare -gr COLOR_YELLOW=""
    declare -gr COLOR_BLUE=""
    declare -gr COLOR_BOLD=""
    declare -gr COLOR_RESET=""
fi

# --- Runtime flags (set by sysdoctor.sh) ---
VERBOSE=false
QUIET=false

# --- Default thresholds / config (overridable via --config) ---
DISK_WARNING_THRESHOLD=80
DISK_CRITICAL_THRESHOLD=90
INODE_WARNING_THRESHOLD=80
INODE_CRITICAL_THRESHOLD=90
MEMORY_WARNING_THRESHOLD=90
MEMORY_CRITICAL_THRESHOLD=95
PING_TARGET="8.8.8.8"
DNS_TEST_HOST="google.com"
HTTP_TEST_URL=""
LOG_LOOKBACK="1 hour ago"

# --- Result collection (populated by each diagnostic module) ---
SECTION_ORDER=()
declare -gA SECTION_TITLE=()
declare -gA SECTION_STATUS=()
declare -gA SECTION_TEXT=()
declare -gA SECTION_JSON=()
RECOMMENDATIONS=()

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        printf '%s\n' "$*" >&2
    fi
}

log_error() {
    printf '%s[ERROR]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$*" >&2
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# take_n N - like `head -n N` but always drains stdin, so it never SIGPIPEs
# an upstream producer under `set -o pipefail`.
take_n() {
    awk -v n="$1" 'NR <= n'
}

# worse_status A B -> prints the more severe of two statuses
worse_status() {
    local a="$1" b="$2"
    local rank_a rank_b
    rank_a=$(status_rank "$a")
    rank_b=$(status_rank "$b")
    if (( rank_a >= rank_b )); then
        printf '%s' "$a"
    else
        printf '%s' "$b"
    fi
}

status_rank() {
    case "$1" in
        "$STATUS_CRITICAL") printf '3' ;;
        "$STATUS_WARNING") printf '2' ;;
        "$STATUS_OK") printf '1' ;;
        *) printf '0' ;;
    esac
}

status_color() {
    case "$1" in
        "$STATUS_OK") printf '%s' "$COLOR_GREEN" ;;
        "$STATUS_WARNING") printf '%s' "$COLOR_YELLOW" ;;
        "$STATUS_CRITICAL") printf '%s' "$COLOR_RED" ;;
        *) printf '%s' "$COLOR_BLUE" ;;
    esac
}

add_recommendation() {
    RECOMMENDATIONS+=("$1")
}

# register_section key title status text json
register_section() {
    local key="$1" title="$2" status="$3" text="$4" json="$5"
    SECTION_ORDER+=("$key")
    SECTION_TITLE["$key"]="$title"
    SECTION_STATUS["$key"]="$status"
    SECTION_TEXT["$key"]="$text"
    SECTION_JSON["$key"]="$json"
}

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

json_string() {
    printf '"%s"' "$(json_escape "$1")"
}

trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# Strip ANSI color sequences (used for json/markdown text that should stay plain)
strip_colors() {
    sed -E $'s/\033\\[[0-9;]*m//g'
}

# load_config FILE - safe KEY=VALUE loader, no sourcing of arbitrary code
load_config() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "Config file not found: $file"
        return 1
    fi

    local allowed_keys=(
        DISK_WARNING_THRESHOLD DISK_CRITICAL_THRESHOLD
        INODE_WARNING_THRESHOLD INODE_CRITICAL_THRESHOLD
        MEMORY_WARNING_THRESHOLD MEMORY_CRITICAL_THRESHOLD
        PING_TARGET DNS_TEST_HOST HTTP_TEST_URL LOG_LOOKBACK
    )

    local line key value
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="$(trim "$line")"
        [[ -z "$line" || "$line" == \#* ]] && continue
        [[ "$line" != *=* ]] && continue

        key="${line%%=*}"
        value="${line#*=}"
        key="$(trim "$key")"
        value="$(trim "$value")"
        value="${value%\"}"
        value="${value#\"}"

        local known=false
        local allowed
        for allowed in "${allowed_keys[@]}"; do
            if [[ "$key" == "$allowed" ]]; then
                known=true
                break
            fi
        done

        if [[ "$known" == true ]]; then
            printf -v "$key" '%s' "$value"
            log_verbose "Config: $key=$value"
        else
            log_verbose "Config: ignoring unknown key '$key'"
        fi
    done < "$file"
}

# human_bytes KB -> human readable string from a value in kibibytes
human_bytes_kb() {
    local kb="$1"
    awk -v kb="$kb" 'BEGIN {
        split("KiB MiB GiB TiB", units, " ")
        val = kb
        unit_idx = 1
        while (val >= 1024 && unit_idx < 4) {
            val = val / 1024
            unit_idx++
        }
        printf "%.1f %s", val, units[unit_idx]
    }'
}
