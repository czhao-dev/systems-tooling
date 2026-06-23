#!/usr/bin/env bash
# services.sh - systemd service diagnostics
# shellcheck shell=bash

# Optional service name set via --service.
SERVICE_NAME="${SERVICE_NAME:-}"

get_failed_units() {
    systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}'
}

get_service_status_line() {
    local name="$1" active enabled
    active="$(systemctl is-active "$name" 2>/dev/null || true)"
    enabled="$(systemctl is-enabled "$name" 2>/dev/null || true)"
    printf '%s: %s (%s)' "$name" "${active:-unknown}" "${enabled:-unknown}"
}

get_service_recent_logs() {
    local name="$1" lines="$2"
    if has_cmd journalctl; then
        journalctl -u "$name" -n "$lines" --no-pager 2>/dev/null
    else
        printf 'journalctl not available\n'
    fi
}

run_services_checks() {
    local status="$STATUS_OK"

    if ! has_cmd systemctl; then
        register_section "services" "Services" "$STATUS_UNKNOWN" \
            "systemctl not available on this system (not a systemd Linux host)." \
            '{"status":"UNKNOWN","available":false}'
        return
    fi

    local failed_units failed_count=0 failed_lines=""
    failed_units="$(get_failed_units)"
    if [[ -n "$failed_units" ]]; then
        failed_count="$(printf '%s\n' "$failed_units" | grep -c .)"
        status="$STATUS_WARNING"
        local unit
        while read -r unit; do
            [[ -z "$unit" ]] && continue
            failed_lines+="  $unit"$'\n'
            add_recommendation "Investigate failed systemd unit: $unit."
        done <<< "$failed_units"
    fi

    local service_block="" service_logs=""
    if [[ -n "$SERVICE_NAME" ]]; then
        service_block="$(get_service_status_line "$SERVICE_NAME")"
        if [[ "$(systemctl is-active "$SERVICE_NAME" 2>/dev/null)" != "active" ]]; then
            status="$(worse_status "$status" "$STATUS_WARNING")"
            add_recommendation "Service '$SERVICE_NAME' is not active."
        fi
        if [[ "$VERBOSE" == true ]]; then
            service_logs="$(get_service_recent_logs "$SERVICE_NAME" 20)"
        fi
    fi

    local text
    text="Failed units: $failed_count"$'\n'
    if [[ -n "$failed_lines" ]]; then
        text+="$failed_lines"
    fi
    if [[ -n "$service_block" ]]; then
        text+=$'\n'"$service_block"$'\n'
    fi
    if [[ -n "$service_logs" ]]; then
        text+=$'\n'"Recent logs for $SERVICE_NAME:"$'\n'"$service_logs"$'\n'
    fi
    text+="Status: $status"

    local json_failed="[]"
    if [[ -n "$failed_units" ]]; then
        json_failed="["
        local first=true unit2
        while read -r unit2; do
            [[ -z "$unit2" ]] && continue
            [[ "$first" == true ]] || json_failed+=","
            json_failed+="$(json_string "$unit2")"
            first=false
        done <<< "$failed_units"
        json_failed+="]"
    fi

    local json
    json="{\"available\":true,\"failed_units\":${json_failed},\"failed_count\":${failed_count}"
    if [[ -n "$SERVICE_NAME" ]]; then
        json+=",\"checked_service\":$(json_string "$SERVICE_NAME")"
    fi
    json+=",\"status\":$(json_string "$status")}"

    register_section "services" "Services" "$status" "$text" "$json"
}
