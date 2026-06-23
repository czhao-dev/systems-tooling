#!/usr/bin/env bash
# logs.sh - recent system log scanning and error-pattern detection
# shellcheck shell=bash

ERROR_PATTERN_REGEX='error|failed|critical|panic|timeout|out of memory|permission denied|connection refused'
CRITICAL_PATTERN_REGEX='critical|panic|out of memory'

get_log_source_name() {
    if has_cmd journalctl; then
        printf 'journalctl'
    elif [[ -r /var/log/syslog ]]; then
        printf '/var/log/syslog'
    elif [[ -r /var/log/messages ]]; then
        printf '/var/log/messages'
    else
        printf 'none'
    fi
}

get_log_lines() {
    local source="$1"
    case "$source" in
        journalctl)
            journalctl --since "$LOG_LOOKBACK" --no-pager -q 2>/dev/null
            ;;
        /var/log/syslog|/var/log/messages)
            tail -n 2000 "$source" 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

run_logs_checks() {
    local status="$STATUS_OK" show_n=10
    [[ "$VERBOSE" == true ]] && show_n=25

    local source
    source="$(get_log_source_name)"

    if [[ "$source" == "none" ]]; then
        register_section "logs" "Logs" "$STATUS_UNKNOWN" \
            "No log source available (journalctl, /var/log/syslog, /var/log/messages not found)." \
            '{"status":"UNKNOWN","source":"none"}'
        return
    fi

    local lines
    lines="$(get_log_lines "$source")"

    local matching_lines critical_lines total_count=0 critical_count=0
    matching_lines="$(printf '%s\n' "$lines" | grep -iE "$ERROR_PATTERN_REGEX" || true)"
    critical_lines="$(printf '%s\n' "$lines" | grep -iE "$CRITICAL_PATTERN_REGEX" || true)"

    [[ -n "$matching_lines" ]] && total_count="$(printf '%s\n' "$matching_lines" | grep -c .)"
    [[ -n "$critical_lines" ]] && critical_count="$(printf '%s\n' "$critical_lines" | grep -c .)"

    if (( critical_count > 0 )); then
        status="$STATUS_CRITICAL"
        add_recommendation "Review $critical_count critical log entries from the last $LOG_LOOKBACK."
    elif (( total_count > 0 )); then
        status="$STATUS_WARNING"
        add_recommendation "Review $total_count warning/error log entries from the last $LOG_LOOKBACK."
    fi

    local recent_block
    recent_block="$(printf '%s\n' "$matching_lines" | tail -n "$show_n")"
    [[ -z "$recent_block" || "$recent_block" == $'\n' ]] && recent_block="  (none)"

    local text
    text="$(cat <<EOF
Log source: $source
Lookback: $LOG_LOOKBACK
Matching entries: $total_count
Critical entries: $critical_count
Status: $status

Recent matching entries:
$recent_block
EOF
)"

    local json
    json=$(cat <<EOF
{"source":$(json_string "$source"),"lookback":$(json_string "$LOG_LOOKBACK"),"matching_count":$total_count,"critical_count":$critical_count,"status":$(json_string "$status")}
EOF
)

    register_section "logs" "Logs" "$status" "$text" "$json"
}
