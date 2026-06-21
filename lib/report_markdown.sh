#!/usr/bin/env bash
# report_markdown.sh - Markdown report formatter
# shellcheck shell=bash

generate_markdown_report() {
    local generated_at="$1" overall="$2"

    printf '# SysDoctor Health Report\n\n'
    printf 'Generated: %s\n\n' "$generated_at"
    printf 'Overall status: **%s**\n\n' "$overall"

    printf '## Summary\n\n'
    printf '| Category | Status |\n|---|---|\n'
    local key
    for key in "${SECTION_ORDER[@]}"; do
        printf '| %s | %s |\n' "${SECTION_TITLE[$key]}" "${SECTION_STATUS[$key]}"
    done
    printf '\n'

    if [[ "$QUIET" != true ]]; then
        printf '## Details\n\n'
        for key in "${SECTION_ORDER[@]}"; do
            printf '### %s\n\n' "${SECTION_TITLE[$key]}"
            # shellcheck disable=SC2016
            printf '```text\n%s\n```\n\n' "$(printf '%s' "${SECTION_TEXT[$key]}" | strip_colors)"
        done
    fi

    printf '## Recommendations\n\n'
    if [[ ${#RECOMMENDATIONS[@]} -eq 0 ]]; then
        printf -- '- None. All checked systems look healthy.\n'
        return
    fi
    local rec
    for rec in "${RECOMMENDATIONS[@]}"; do
        printf -- '- %s\n' "$rec"
    done
}
