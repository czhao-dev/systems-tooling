#!/usr/bin/env bash
# system.sh - OS, kernel, hostname, and uptime diagnostics
# shellcheck shell=bash

get_os_description() {
    if [[ -r /etc/os-release ]]; then
        local name
        # shellcheck disable=SC1091
        name="$(. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-$NAME}")"
        if [[ -n "$name" ]]; then
            printf '%s' "$name"
            return
        fi
    fi
    if has_cmd sw_vers; then
        printf '%s %s' "$(sw_vers -productName)" "$(sw_vers -productVersion)"
        return
    fi
    printf '%s' "$(uname -s)"
}

get_kernel_version() {
    uname -r 2>/dev/null || printf 'unknown'
}

get_uptime_human() {
    if [[ -r /proc/uptime ]]; then
        awk '{
            secs = int($1)
            days = int(secs / 86400)
            hours = int((secs % 86400) / 3600)
            mins = int((secs % 3600) / 60)
            out = ""
            if (days > 0) out = out days "d "
            if (hours > 0 || days > 0) out = out hours "h "
            out = out mins "m"
            print out
        }' /proc/uptime
        return
    fi
    if has_cmd uptime; then
        uptime | sed -E 's/^.*up +//; s/, *[0-9]+ users?.*$//; s/, *load average.*$//'
        return
    fi
    printf 'unknown'
}

run_system_checks() {
    local hostname os kernel uptime status="$STATUS_OK"

    hostname="$(hostname 2>/dev/null || printf 'unknown')"
    os="$(get_os_description)"
    kernel="$(get_kernel_version)"
    uptime="$(get_uptime_human)"

    if [[ "$os" == "unknown" && "$kernel" == "unknown" ]]; then
        status="$STATUS_UNKNOWN"
    fi

    local text
    text="$(cat <<EOF
Hostname: $hostname
OS: $os
Kernel: $kernel
Uptime: $uptime
EOF
)"

    local json
    json=$(cat <<EOF
{"hostname":$(json_string "$hostname"),"os":$(json_string "$os"),"kernel":$(json_string "$kernel"),"uptime":$(json_string "$uptime")}
EOF
)

    register_section "system" "System" "$status" "$text" "$json"
}
