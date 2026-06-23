#!/usr/bin/env bash
# docker.sh - Docker container diagnostics
# shellcheck shell=bash

run_docker_checks() {
    local status="$STATUS_OK"

    if ! has_cmd docker; then
        register_section "docker" "Docker" "$STATUS_UNKNOWN" "Docker is not installed on this system." \
            '{"status":"UNKNOWN","available":false}'
        return
    fi

    if ! docker ps >/dev/null 2>&1; then
        register_section "docker" "Docker" "$STATUS_UNKNOWN" \
            "Docker daemon is not accessible (not running, or insufficient permissions)." \
            '{"status":"UNKNOWN","available":false}'
        return
    fi

    local running_n stopped_n unhealthy_list unhealthy_n=0
    running_n="$(docker ps -q 2>/dev/null | grep -c .)" || running_n=0
    stopped_n="$(docker ps -aq --filter status=exited 2>/dev/null | grep -c .)" || stopped_n=0
    unhealthy_list="$(docker ps -a --filter health=unhealthy --format '{{.Names}}' 2>/dev/null)"
    [[ -n "$unhealthy_list" ]] && unhealthy_n="$(printf '%s\n' "$unhealthy_list" | grep -c .)"

    if (( unhealthy_n > 0 )); then
        status="$STATUS_WARNING"
        local name
        while read -r name; do
            [[ -z "$name" ]] && continue
            add_recommendation "Docker container '$name' is reporting unhealthy."
        done <<< "$unhealthy_list"
    fi

    local restart_lines
    restart_lines="$(docker ps -aq 2>/dev/null | xargs -r docker inspect --format '{{.Name}} {{.RestartCount}}' 2>/dev/null \
        | sed 's#^/##' | awk '$2 > 0')"

    local usage_block="(unavailable)"
    if (( running_n > 0 )); then
        usage_block="$(docker stats --no-stream --format '{{.Name}}: CPU {{.CPUPerc}}, MEM {{.MemUsage}}' 2>/dev/null)"
        [[ -z "$usage_block" ]] && usage_block="(unavailable)"
    fi

    local text
    text="$(cat <<EOF
Running containers: $running_n
Stopped containers: $stopped_n
Unhealthy containers: $unhealthy_n
Status: $status

Containers with restarts:
${restart_lines:-  (none)}

Resource usage:
$usage_block
EOF
)"

    local json
    json=$(cat <<EOF
{"available":true,"running":$running_n,"stopped":$stopped_n,"unhealthy":$unhealthy_n,"status":$(json_string "$status")}
EOF
)

    register_section "docker" "Docker" "$status" "$text" "$json"
}
