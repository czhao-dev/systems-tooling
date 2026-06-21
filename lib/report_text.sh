#!/usr/bin/env bash
# report_text.sh - plain/terminal text report formatter
# shellcheck shell=bash

print_summary_table_text() {
    local key
    for key in "${SECTION_ORDER[@]}"; do
        local title="${SECTION_TITLE[$key]}" st="${SECTION_STATUS[$key]}"
        printf '  %s%-10s%s %s%s%s\n' "$COLOR_BOLD" "$title" "$COLOR_RESET" \
            "$(status_color "$st")" "$st" "$COLOR_RESET"
    done
}

print_recommendations_text() {
    if [[ ${#RECOMMENDATIONS[@]} -eq 0 ]]; then
        printf 'Recommendations:\n  - None. All checked systems look healthy.\n'
        return
    fi
    printf 'Recommendations:\n'
    local rec
    for rec in "${RECOMMENDATIONS[@]}"; do
        printf '  - %s\n' "$rec"
    done
}

generate_text_report() {
    local generated_at="$1" overall="$2"

    printf 'SysDoctor Health Report\n'
    printf 'Generated: %s\n\n' "$generated_at"

    printf 'Overall status: %s%s%s\n\n' "$(status_color "$overall")" "$overall" "$COLOR_RESET"

    printf 'Summary:\n'
    print_summary_table_text
    printf '\n'

    if [[ "$QUIET" != true ]]; then
        local key
        for key in "${SECTION_ORDER[@]}"; do
            local title="${SECTION_TITLE[$key]}" st="${SECTION_STATUS[$key]}"
            printf '%s%s:%s\n' "$COLOR_BOLD" "$title" "$COLOR_RESET"
            printf '%s\n' "${SECTION_TEXT[$key]}" | sed 's/^/  /'
            printf '\n'
        done
    fi

    print_recommendations_text
}
