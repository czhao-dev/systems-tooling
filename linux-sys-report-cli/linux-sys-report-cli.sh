#!/usr/bin/env bash
# linux-sys-report-cli - Linux system diagnostics and health report tool
set -euo pipefail

# Resolve the real script location even when invoked through a symlink
# (e.g. the one scripts/install.sh creates on PATH).
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "$SOURCE" ]]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=lib/system.sh
source "$LIB_DIR/system.sh"
# shellcheck source=lib/cpu.sh
source "$LIB_DIR/cpu.sh"
# shellcheck source=lib/memory.sh
source "$LIB_DIR/memory.sh"
# shellcheck source=lib/disk.sh
source "$LIB_DIR/disk.sh"
# shellcheck source=lib/network.sh
source "$LIB_DIR/network.sh"
# shellcheck source=lib/services.sh
source "$LIB_DIR/services.sh"
# shellcheck source=lib/logs.sh
source "$LIB_DIR/logs.sh"
# shellcheck source=lib/docker.sh
source "$LIB_DIR/docker.sh"
# shellcheck source=lib/report_text.sh
source "$LIB_DIR/report_text.sh"
# shellcheck source=lib/report_markdown.sh
source "$LIB_DIR/report_markdown.sh"
# shellcheck source=lib/report_json.sh
source "$LIB_DIR/report_json.sh"

readonly ALL_SECTIONS=(system cpu memory disk network services logs docker)

FORMAT="text"
OUTPUT=""
CONFIG_FILE=""
FULL=false
SERVICE_NAME_ARG=""
URL_ARG=""
SELECTED=()

print_usage() {
    cat <<'EOF'
Usage:
  linux-sys-report-cli.sh [options]

Options:
  --full                         Run all diagnostics
  --system                       Run system diagnostics
  --cpu                          Show CPU diagnostics
  --memory                       Show memory diagnostics
  --disk                         Show disk diagnostics
  --network                      Show network diagnostics
  --services                     Show service diagnostics
  --logs                         Show recent log diagnostics
  --docker                       Show Docker diagnostics
  --service NAME                 Check a specific systemd service
  --url URL                      Check an HTTP endpoint
  --format text|markdown|json    Output format (default: text)
  --output PATH                  Write report to file instead of stdout
  --config PATH                  Load thresholds from a config file
  --verbose                      Print detailed diagnostics
  --quiet                        Print only summary
  --help                         Show this help message
EOF
}

contains() {
    local needle="$1"; shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

add_selected() {
    local key="$1"
    contains "$key" "${SELECTED[@]:-}" || SELECTED+=("$key")
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --full) FULL=true ;;
            --system) add_selected system ;;
            --cpu) add_selected cpu ;;
            --memory) add_selected memory ;;
            --disk) add_selected disk ;;
            --network) add_selected network ;;
            --services) add_selected services ;;
            --logs) add_selected logs ;;
            --docker) add_selected docker ;;
            --service)
                [[ $# -ge 2 ]] || { log_error "--service requires a value"; exit 2; }
                SERVICE_NAME_ARG="$2"
                add_selected services
                shift
                ;;
            --url)
                [[ $# -ge 2 ]] || { log_error "--url requires a value"; exit 2; }
                URL_ARG="$2"
                add_selected network
                shift
                ;;
            --format)
                [[ $# -ge 2 ]] || { log_error "--format requires a value"; exit 2; }
                FORMAT="$2"
                shift
                ;;
            --output)
                [[ $# -ge 2 ]] || { log_error "--output requires a value"; exit 2; }
                OUTPUT="$2"
                shift
                ;;
            --config)
                [[ $# -ge 2 ]] || { log_error "--config requires a value"; exit 2; }
                CONFIG_FILE="$2"
                shift
                ;;
            --verbose) VERBOSE=true ;;
            --quiet) QUIET=true ;;
            --help|-h) print_usage; exit 0 ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 2
                ;;
        esac
        shift
    done
}

validate_format() {
    case "$FORMAT" in
        text|markdown|json) ;;
        *)
            log_error "Invalid --format '$FORMAT' (expected text, markdown, or json)"
            exit 2
            ;;
    esac
}

run_selected_checks() {
    local key
    for key in "${ALL_SECTIONS[@]}"; do
        if contains "$key" "${SELECTED[@]:-}"; then
            "run_${key}_checks"
        fi
    done
}

compute_overall_status() {
    local overall="$STATUS_UNKNOWN" key
    for key in "${SECTION_ORDER[@]}"; do
        overall="$(worse_status "$overall" "${SECTION_STATUS[$key]}")"
    done
    printf '%s' "$overall"
}

status_to_exit_code() {
    case "$1" in
        "$STATUS_OK") printf '0' ;;
        "$STATUS_WARNING") printf '1' ;;
        "$STATUS_CRITICAL") printf '2' ;;
        *) printf '3' ;;
    esac
}

main() {
    parse_args "$@"

    if [[ "$FULL" == true ]]; then
        SELECTED=("${ALL_SECTIONS[@]}")
    fi

    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        print_usage
        exit 1
    fi

    validate_format

    if [[ -n "$CONFIG_FILE" ]]; then
        load_config "$CONFIG_FILE"
    fi

    SERVICE_NAME="$SERVICE_NAME_ARG"
    NETWORK_HTTP_URL="$URL_ARG"

    run_selected_checks

    local generated_at overall
    generated_at="$(date '+%Y-%m-%d %H:%M:%S')"
    overall="$(compute_overall_status)"

    if [[ -n "$OUTPUT" ]]; then
        "generate_${FORMAT}_report" "$generated_at" "$overall" | strip_colors > "$OUTPUT"
        log_verbose "Report written to $OUTPUT"
    else
        "generate_${FORMAT}_report" "$generated_at" "$overall"
    fi

    exit "$(status_to_exit_code "$overall")"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
