#!/usr/bin/env bash
# report_json.sh - JSON report formatter
# shellcheck shell=bash

generate_json_report() {
    local generated_at="$1" overall="$2"

    local sections="{}"
    if [[ ${#SECTION_ORDER[@]} -gt 0 ]]; then
        sections="{"
        local key first=true
        for key in "${SECTION_ORDER[@]}"; do
            [[ "$first" == true ]] || sections+=","
            if [[ "$QUIET" == true ]]; then
                sections+="$(json_string "$key"):$(json_string "${SECTION_STATUS[$key]}")"
            else
                sections+="$(json_string "$key"):${SECTION_JSON[$key]}"
            fi
            first=false
        done
        sections+="}"
    fi

    local recs_json="[]"
    if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
        recs_json="["
        local rec first=true
        for rec in "${RECOMMENDATIONS[@]}"; do
            [[ "$first" == true ]] || recs_json+=","
            recs_json+="$(json_string "$rec")"
            first=false
        done
        recs_json+="]"
    fi

    local out
    out="{\"generated_at\":$(json_string "$generated_at"),\"overall_status\":$(json_string "$overall"),\"sections\":${sections},\"recommendations\":${recs_json}}"

    if has_cmd jq; then
        printf '%s' "$out" | jq .
    else
        printf '%s\n' "$out"
    fi
}
