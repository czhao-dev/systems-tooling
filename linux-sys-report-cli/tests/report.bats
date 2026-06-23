#!/usr/bin/env bats

setup() {
    ROOT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export NO_COLOR=1
    # shellcheck disable=SC1091
    source "$ROOT_DIR/lib/common.sh"
    # shellcheck disable=SC1091
    source "$ROOT_DIR/lib/report_text.sh"
    # shellcheck disable=SC1091
    source "$ROOT_DIR/lib/report_markdown.sh"
    # shellcheck disable=SC1091
    source "$ROOT_DIR/lib/report_json.sh"

    SECTION_ORDER=()
    declare -gA SECTION_TITLE=() SECTION_STATUS=() SECTION_TEXT=() SECTION_JSON=()
    RECOMMENDATIONS=()
    QUIET=false
    VERBOSE=false

    register_section "cpu" "CPU" "$STATUS_OK" "Load average: 0.1 0.2 0.3
CPU cores: 4
Status: OK" '{"load1":"0.1","cores":"4","status":"OK"}'

    register_section "disk" "Disk" "$STATUS_WARNING" "Filesystem usage:
  /: 85%
Status: WARNING" '{"filesystems":[{"mount":"/","use_percent":85}],"status":"WARNING"}'

    add_recommendation "Disk usage on / is high (85%)."
}

@test "generate_text_report includes header, summary, and sections" {
    output="$(generate_text_report "2026-06-21 12:00:00" "$STATUS_WARNING")"
    [[ "$output" == *"linux-sys-report-cli Health Report"* ]]
    [[ "$output" == *"Generated: 2026-06-21 12:00:00"* ]]
    [[ "$output" == *"Overall status: WARNING"* ]]
    [[ "$output" == *"CPU"*"OK"* ]]
    [[ "$output" == *"Load average: 0.1 0.2 0.3"* ]]
    [[ "$output" == *"Disk usage on / is high (85%)."* ]]
}

@test "generate_text_report in quiet mode omits section detail" {
    QUIET=true
    output="$(generate_text_report "2026-06-21 12:00:00" "$STATUS_WARNING")"
    [[ "$output" != *"Load average: 0.1 0.2 0.3"* ]]
    [[ "$output" == *"Disk usage on / is high (85%)."* ]]
}

@test "generate_text_report reports healthy when there are no recommendations" {
    RECOMMENDATIONS=()
    output="$(generate_text_report "2026-06-21 12:00:00" "$STATUS_OK")"
    [[ "$output" == *"None. All checked systems look healthy."* ]]
}

@test "generate_markdown_report produces a summary table and recommendations" {
    output="$(generate_markdown_report "2026-06-21 12:00:00" "$STATUS_WARNING")"
    [[ "$output" == *"# linux-sys-report-cli Health Report"* ]]
    [[ "$output" == *"| CPU | OK |"* ]]
    [[ "$output" == *"| Disk | WARNING |"* ]]
    [[ "$output" == *"- Disk usage on / is high (85%)."* ]]
}

@test "generate_markdown_report in quiet mode omits the Details section" {
    QUIET=true
    output="$(generate_markdown_report "2026-06-21 12:00:00" "$STATUS_WARNING")"
    [[ "$output" != *"## Details"* ]]
}

@test "generate_json_report produces valid, structured JSON" {
    skip_if_no_jq
    output="$(generate_json_report "2026-06-21 12:00:00" "$STATUS_WARNING")"
    echo "$output" | jq -e . >/dev/null

    overall="$(echo "$output" | jq -r '.overall_status')"
    [ "$overall" = "WARNING" ]

    cpu_status="$(echo "$output" | jq -r '.sections.cpu.status')"
    [ "$cpu_status" = "OK" ]

    rec_count="$(echo "$output" | jq '.recommendations | length')"
    [ "$rec_count" -eq 1 ]
}

@test "generate_json_report in quiet mode collapses sections to plain statuses" {
    skip_if_no_jq
    QUIET=true
    output="$(generate_json_report "2026-06-21 12:00:00" "$STATUS_WARNING")"
    disk_value="$(echo "$output" | jq -r '.sections.disk')"
    [ "$disk_value" = "WARNING" ]
}

skip_if_no_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        skip "jq not installed"
    fi
}
