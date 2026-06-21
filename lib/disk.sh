#!/usr/bin/env bash
# disk.sh - filesystem space and inode usage diagnostics
# shellcheck shell=bash

# Filters out pseudo/virtual filesystem mount points that aren't useful for capacity checks.
is_real_mount() {
    local mount="$1"
    case "$mount" in
        /proc*|/sys*|/dev*|/run*|/snap*) return 1 ;;
    esac
    return 0
}

# Emits "mount use_pct" lines from `df -kP`, real mounts only.
list_disk_usage() {
    df -kP 2>/dev/null | tail -n +2 | while read -r _ _ _ _ pct mount; do
        pct="${pct%\%}"
        [[ "$pct" =~ ^[0-9]+$ ]] || continue
        is_real_mount "$mount" || continue
        printf '%s %s\n' "$mount" "$pct"
    done
}

# Emits "mount use_pct" lines from `df -iP`, real mounts only.
list_inode_usage() {
    df -iP 2>/dev/null | tail -n +2 | while read -r _ _ _ _ pct mount; do
        pct="${pct%\%}"
        [[ "$pct" =~ ^[0-9]+$ ]] || continue
        is_real_mount "$mount" || continue
        printf '%s %s\n' "$mount" "$pct"
    done
}

run_disk_checks() {
    local status="$STATUS_OK" top_n=5
    [[ "$VERBOSE" == true ]] && top_n=15

    if ! has_cmd df; then
        register_section "disk" "Disk" "$STATUS_UNKNOWN" "df command not available." '{"status":"UNKNOWN"}'
        return
    fi

    local disk_usage inode_usage
    disk_usage="$(list_disk_usage | sort -k2 -rn)"
    inode_usage="$(list_inode_usage | sort -k2 -rn)"

    local disk_lines="" inode_lines="" json_mounts="[]" json_inodes="[]"
    local mount pct first=true

    if [[ -n "$disk_usage" ]]; then
        json_mounts="["
        while read -r mount pct; do
            [[ -z "$mount" ]] && continue
            disk_lines+="  $mount: ${pct}%"$'\n'
            if (( pct >= DISK_CRITICAL_THRESHOLD )); then
                status="$STATUS_CRITICAL"
                add_recommendation "Disk usage on $mount is critical (${pct}%)."
            elif (( pct >= DISK_WARNING_THRESHOLD )); then
                status="$(worse_status "$status" "$STATUS_WARNING")"
                add_recommendation "Disk usage on $mount is high (${pct}%)."
            fi
            [[ "$first" == true ]] || json_mounts+=","
            json_mounts+="{\"mount\":$(json_string "$mount"),\"use_percent\":$pct}"
            first=false
        done <<< "$(printf '%s\n' "$disk_usage" | take_n "$top_n")"
        json_mounts+="]"
    fi

    first=true
    if [[ -n "$inode_usage" ]]; then
        json_inodes="["
        while read -r mount pct; do
            [[ -z "$mount" ]] && continue
            inode_lines+="  $mount: ${pct}%"$'\n'
            if (( pct >= INODE_CRITICAL_THRESHOLD )); then
                status="$STATUS_CRITICAL"
                add_recommendation "Inode usage on $mount is critical (${pct}%)."
            elif (( pct >= INODE_WARNING_THRESHOLD )); then
                status="$(worse_status "$status" "$STATUS_WARNING")"
                add_recommendation "Inode usage on $mount is high (${pct}%)."
            fi
            [[ "$first" == true ]] || json_inodes+=","
            json_inodes+="{\"mount\":$(json_string "$mount"),\"use_percent\":$pct}"
            first=false
        done <<< "$(printf '%s\n' "$inode_usage" | take_n "$top_n")"
        json_inodes+="]"
    fi

    [[ -z "$disk_lines" ]] && disk_lines="  (no real filesystems found)\n"
    [[ -z "$inode_lines" ]] && inode_lines="  (no real filesystems found)\n"

    local text
    text="$(cat <<EOF
Filesystem usage:
${disk_lines}
Inode usage:
${inode_lines}Status: $status
EOF
)"

    local json
    json="{\"filesystems\":${json_mounts},\"inodes\":${json_inodes},\"status\":$(json_string "$status")}"

    register_section "disk" "Disk" "$status" "$text" "$json"
}
