#!/usr/bin/env bats

setup() {
    ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    # shellcheck disable=SC1091
    source "$ROOT_DIR/lib/common.sh"
}

@test "worse_status picks the more severe status" {
    result="$(worse_status "$STATUS_OK" "$STATUS_WARNING")"
    [ "$result" = "WARNING" ]

    result="$(worse_status "$STATUS_CRITICAL" "$STATUS_WARNING")"
    [ "$result" = "CRITICAL" ]

    result="$(worse_status "$STATUS_OK" "$STATUS_OK")"
    [ "$result" = "OK" ]

    result="$(worse_status "$STATUS_UNKNOWN" "$STATUS_OK")"
    [ "$result" = "OK" ]
}

@test "status_rank orders severities correctly" {
    [ "$(status_rank "$STATUS_UNKNOWN")" -lt "$(status_rank "$STATUS_OK")" ]
    [ "$(status_rank "$STATUS_OK")" -lt "$(status_rank "$STATUS_WARNING")" ]
    [ "$(status_rank "$STATUS_WARNING")" -lt "$(status_rank "$STATUS_CRITICAL")" ]
}

@test "json_escape escapes quotes and backslashes" {
    result="$(json_escape 'say "hi" \ there')"
    [ "$result" = 'say \"hi\" \\ there' ]
}

@test "json_string wraps a value in quotes" {
    result="$(json_string 'hello')"
    [ "$result" = '"hello"' ]
}

@test "trim removes leading and trailing whitespace" {
    result="$(trim '   hello world   ')"
    [ "$result" = "hello world" ]
}

@test "human_bytes_kb converts to a readable unit" {
    result="$(human_bytes_kb 1024)"
    [ "$result" = "1.0 MiB" ]

    result="$(human_bytes_kb 512)"
    [ "$result" = "512.0 KiB" ]
}

@test "take_n keeps only the first N lines without erroring" {
    result="$(printf '1\n2\n3\n4\n5\n' | take_n 3)"
    [ "$result" = $'1\n2\n3' ]
}

@test "has_cmd detects an existing and a missing command" {
    run has_cmd bash
    [ "$status" -eq 0 ]

    run has_cmd definitely-not-a-real-command-xyz
    [ "$status" -ne 0 ]
}

@test "add_recommendation appends to the RECOMMENDATIONS array" {
    RECOMMENDATIONS=()
    add_recommendation "first issue"
    add_recommendation "second issue"
    [ "${#RECOMMENDATIONS[@]}" -eq 2 ]
    [ "${RECOMMENDATIONS[0]}" = "first issue" ]
    [ "${RECOMMENDATIONS[1]}" = "second issue" ]
}

@test "register_section records section metadata" {
    SECTION_ORDER=()
    declare -A SECTION_TITLE=() SECTION_STATUS=() SECTION_TEXT=() SECTION_JSON=()
    register_section "cpu" "CPU" "$STATUS_OK" "some text" '{"status":"OK"}'
    [ "${SECTION_ORDER[0]}" = "cpu" ]
    [ "${SECTION_TITLE[cpu]}" = "CPU" ]
    [ "${SECTION_STATUS[cpu]}" = "OK" ]
    [ "${SECTION_TEXT[cpu]}" = "some text" ]
    [ "${SECTION_JSON[cpu]}" = '{"status":"OK"}' ]
}

@test "load_config loads thresholds from the sample fixture" {
    load_config "$ROOT_DIR/tests/fixtures/sample.conf"
    [ "$DISK_WARNING_THRESHOLD" = "70" ]
    [ "$DISK_CRITICAL_THRESHOLD" = "85" ]
    [ "$PING_TARGET" = "1.1.1.1" ]
    [ "$HTTP_TEST_URL" = "https://example.com/health" ]
}

@test "load_config only applies allowed keys" {
    config_file="$BATS_TEST_TMPDIR/linux-sys-report-cli.conf"
    cat > "$config_file" <<'EOF'
DISK_WARNING_THRESHOLD=70
NOT_A_REAL_KEY=danger
# a comment
PING_TARGET="1.1.1.1"
EOF
    load_config "$config_file"
    [ "$DISK_WARNING_THRESHOLD" = "70" ]
    [ "$PING_TARGET" = "1.1.1.1" ]
    [ -z "${NOT_A_REAL_KEY:-}" ]
}
