#!/usr/bin/env bats

setup() {
    ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    # shellcheck disable=SC1091
    source "$ROOT_DIR/linux-sys-report-cli.sh"
}

@test "contains finds an existing element" {
    run contains "cpu" "system" "cpu" "disk"
    [ "$status" -eq 0 ]
}

@test "contains returns failure for a missing element" {
    run contains "network" "system" "cpu" "disk"
    [ "$status" -ne 0 ]
}

@test "add_selected does not duplicate entries" {
    SELECTED=()
    add_selected "cpu"
    add_selected "cpu"
    add_selected "memory"
    [ "${#SELECTED[@]}" -eq 2 ]
}

@test "parse_args enables --full" {
    parse_args --full
    [ "$FULL" = true ]
}

@test "parse_args selects individual categories" {
    SELECTED=()
    parse_args --cpu --memory
    [ "${#SELECTED[@]}" -eq 2 ]
    contains "cpu" "${SELECTED[@]}"
    contains "memory" "${SELECTED[@]}"
}

@test "parse_args captures --service and implies services category" {
    SELECTED=()
    parse_args --service nginx
    [ "$SERVICE_NAME_ARG" = "nginx" ]
    contains "services" "${SELECTED[@]}"
}

@test "parse_args captures --url and implies network category" {
    SELECTED=()
    parse_args --url "https://example.com/health"
    [ "$URL_ARG" = "https://example.com/health" ]
    contains "network" "${SELECTED[@]}"
}

@test "parse_args sets format and output" {
    parse_args --format json --output /tmp/report.json
    [ "$FORMAT" = "json" ]
    [ "$OUTPUT" = "/tmp/report.json" ]
}

@test "parse_args sets verbose and quiet flags" {
    parse_args --verbose --quiet
    [ "$VERBOSE" = true ]
    [ "$QUIET" = true ]
}

@test "parse_args rejects an unknown option" {
    run parse_args --not-a-real-flag
    [ "$status" -eq 2 ]
}

@test "validate_format accepts text, markdown, and json" {
    FORMAT="text"; run validate_format; [ "$status" -eq 0 ]
    FORMAT="markdown"; run validate_format; [ "$status" -eq 0 ]
    FORMAT="json"; run validate_format; [ "$status" -eq 0 ]
}

@test "validate_format rejects an invalid format" {
    FORMAT="xml"
    run validate_format
    [ "$status" -eq 2 ]
}

@test "status_to_exit_code maps statuses to expected codes" {
    [ "$(status_to_exit_code "$STATUS_OK")" -eq 0 ]
    [ "$(status_to_exit_code "$STATUS_WARNING")" -eq 1 ]
    [ "$(status_to_exit_code "$STATUS_CRITICAL")" -eq 2 ]
    [ "$(status_to_exit_code "$STATUS_UNKNOWN")" -eq 3 ]
}

@test "--help prints usage and exits 0" {
    run "$ROOT_DIR/linux-sys-report-cli.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "running with no arguments prints usage and exits 1" {
    run "$ROOT_DIR/linux-sys-report-cli.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}
