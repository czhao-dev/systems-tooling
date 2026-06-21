#!/usr/bin/env bash
# memory.sh - memory and swap usage diagnostics
# shellcheck shell=bash

# Prints "total_kb available_kb swaptotal_kb swapfree_kb" or returns 1 if unavailable
get_meminfo_kb() {
    if [[ -r /proc/meminfo ]]; then
        awk '
            /^MemTotal:/     { total = $2 }
            /^MemAvailable:/ { avail = $2 }
            /^SwapTotal:/    { swaptotal = $2 }
            /^SwapFree:/     { swapfree = $2 }
            END { print total, avail, swaptotal, swapfree }
        ' /proc/meminfo
        return 0
    fi

    if has_cmd sysctl && has_cmd vm_stat; then
        local page_size total_bytes total_kb free_pages free_kb avail_kb
        local swap_total_mb swap_used_mb swaptotal_kb swapfree_kb

        page_size="$(sysctl -n hw.pagesize 2>/dev/null || printf '4096')"
        total_bytes="$(sysctl -n hw.memsize 2>/dev/null || printf '0')"
        total_kb=$(( total_bytes / 1024 ))

        free_pages="$(vm_stat 2>/dev/null | awk '/Pages free/ { gsub(/\./, "", $3); print $3 }')"
        free_pages="${free_pages:-0}"
        free_kb=$(( free_pages * page_size / 1024 ))
        avail_kb="$free_kb"

        swap_total_mb="$(sysctl -n vm.swapusage 2>/dev/null | awk -F'[ M]+' '{print $3}')"
        swap_used_mb="$(sysctl -n vm.swapusage 2>/dev/null | awk -F'[ M]+' '{print $6}')"
        swaptotal_kb=$(( ${swap_total_mb%.*} * 1024 ))
        local swap_free_mb
        swap_free_mb=$(awk -v t="${swap_total_mb:-0}" -v u="${swap_used_mb:-0}" 'BEGIN{printf "%.0f", t-u}')
        swapfree_kb=$(( swap_free_mb * 1024 ))

        printf '%s %s %s %s' "$total_kb" "$avail_kb" "$swaptotal_kb" "$swapfree_kb"
        return 0
    fi

    return 1
}

get_top_memory_processes() {
    local count="$1"
    if ! has_cmd ps; then
        printf 'ps command not available\n'
        return
    fi
    {
        printf '%-8s %6s %6s  %s\n' "PID" "%MEM" "%CPU" "COMMAND"
        ps -eo pid,pmem,pcpu,comm 2>/dev/null | tail -n +2 | sort -k2 -rn | take_n "$count" \
            | awk '{printf "%-8s %6.1f %6.1f  %s\n", $1, $2, $3, $4}'
    }
}

run_memory_checks() {
    local status="$STATUS_OK" top_n=5
    [[ "$VERBOSE" == true ]] && top_n=10

    local meminfo total_kb avail_kb swaptotal_kb swapfree_kb
    if ! meminfo="$(get_meminfo_kb)"; then
        register_section "memory" "Memory" "$STATUS_UNKNOWN" "Memory information not available on this system." \
            '{"status":"UNKNOWN"}'
        return
    fi
    read -r total_kb avail_kb swaptotal_kb swapfree_kb <<< "$meminfo"

    local used_kb used_pct swapused_kb swapused_pct
    used_kb=$(( total_kb - avail_kb ))
    used_pct="$(awk -v u="$used_kb" -v t="$total_kb" 'BEGIN { if (t > 0) printf "%.1f", (u / t) * 100; else print "0.0" }')"
    swapused_kb=$(( swaptotal_kb - swapfree_kb ))
    swapused_pct="$(awk -v u="$swapused_kb" -v t="$swaptotal_kb" 'BEGIN { if (t > 0) printf "%.1f", (u / t) * 100; else print "0.0" }')"

    if awk -v p="$used_pct" -v c="$MEMORY_CRITICAL_THRESHOLD" 'BEGIN { exit !(p >= c) }'; then
        status="$STATUS_CRITICAL"
        add_recommendation "Memory usage is critical (${used_pct}% used); investigate top memory consumers."
    elif awk -v p="$used_pct" -v w="$MEMORY_WARNING_THRESHOLD" 'BEGIN { exit !(p >= w) }'; then
        status="$STATUS_WARNING"
        add_recommendation "Memory usage is high (${used_pct}% used); consider freeing memory or scaling resources."
    fi

    local top_procs
    top_procs="$(get_top_memory_processes "$top_n")"

    local text
    text="$(cat <<EOF
Used: $(human_bytes_kb "$used_kb") / $(human_bytes_kb "$total_kb") (${used_pct}%)
Swap: $(human_bytes_kb "$swapused_kb") / $(human_bytes_kb "$swaptotal_kb") (${swapused_pct}%)
Status: $status

Top processes by memory:
$top_procs
EOF
)"

    local json
    json=$(cat <<EOF
{"total_kb":$total_kb,"used_kb":$used_kb,"used_percent":$used_pct,"swap_total_kb":$swaptotal_kb,"swap_used_kb":$swapused_kb,"swap_used_percent":$swapused_pct,"status":$(json_string "$status")}
EOF
)

    register_section "memory" "Memory" "$status" "$text" "$json"
}
