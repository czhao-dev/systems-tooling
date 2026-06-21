#!/usr/bin/env bash
# cpu.sh - CPU load and top-process diagnostics
# shellcheck shell=bash

get_cpu_count() {
    if has_cmd nproc; then
        nproc
        return
    fi
    if has_cmd sysctl; then
        sysctl -n hw.ncpu 2>/dev/null && return
    fi
    if has_cmd getconf; then
        getconf _NPROCESSORS_ONLN 2>/dev/null && return
    fi
    printf '1'
}

# Prints "load1 load5 load15"
get_load_avg() {
    if [[ -r /proc/loadavg ]]; then
        awk '{print $1, $2, $3}' /proc/loadavg
        return
    fi
    if has_cmd sysctl; then
        sysctl -n vm.loadavg 2>/dev/null | tr -d '{}' | awk '{print $1, $2, $3}'
        return
    fi
    printf 'unknown unknown unknown'
}

get_top_cpu_processes() {
    local count="$1"
    if ! has_cmd ps; then
        printf 'ps command not available\n'
        return
    fi
    {
        printf '%-8s %6s %6s  %s\n' "PID" "%CPU" "%MEM" "COMMAND"
        ps -eo pid,pcpu,pmem,comm 2>/dev/null | tail -n +2 | sort -k2 -rn | take_n "$count" \
            | awk '{printf "%-8s %6.1f %6.1f  %s\n", $1, $2, $3, $4}'
    }
}

run_cpu_checks() {
    local cores load1 load5 load15 status="$STATUS_OK" top_n=5
    [[ "$VERBOSE" == true ]] && top_n=10

    cores="$(get_cpu_count)"
    read -r load1 load5 load15 <<< "$(get_load_avg)"

    local load_per_core="unknown"
    if [[ "$load1" != "unknown" && "$cores" =~ ^[0-9]+$ ]]; then
        load_per_core="$(awk -v l="$load1" -v c="$cores" 'BEGIN { printf "%.2f", l / c }')"
        if awk -v l="$load1" -v c="$cores" 'BEGIN { exit !(l > c) }'; then
            status="$STATUS_WARNING"
            add_recommendation "CPU load average ($load1) exceeds core count ($cores); investigate top CPU consumers."
        fi
    else
        status="$STATUS_UNKNOWN"
    fi

    local top_procs
    top_procs="$(get_top_cpu_processes "$top_n")"

    local text
    text="$(cat <<EOF
Load average: $load1 $load5 $load15
CPU cores: $cores
Load per core: $load_per_core
Status: $status

Top processes by CPU:
$top_procs
EOF
)"

    local json
    json=$(cat <<EOF
{"load1":$(json_string "$load1"),"load5":$(json_string "$load5"),"load15":$(json_string "$load15"),"cores":$(json_string "$cores"),"load_per_core":$(json_string "$load_per_core"),"status":$(json_string "$status")}
EOF
)

    register_section "cpu" "CPU" "$status" "$text" "$json"
}
