#!/usr/bin/env bash
# network.sh - interfaces, routing, DNS, connectivity, and port diagnostics
# shellcheck shell=bash

# Optional URL set via --url; falls back to HTTP_TEST_URL from config.
NETWORK_HTTP_URL="${NETWORK_HTTP_URL:-}"

list_interfaces() {
    if has_cmd ip; then
        ip -o -4 addr show 2>/dev/null | awk '{print $2": "$4}'
        return
    fi
    if has_cmd ifconfig; then
        ifconfig 2>/dev/null | awk '
            /^[a-zA-Z0-9]+:/ { iface = $1; sub(/:$/, "", iface) }
            /inet / { print iface": "$2 }
        '
        return
    fi
    printf 'no interface tool available\n'
}

get_default_gateway() {
    if has_cmd ip; then
        ip route show default 2>/dev/null | awk '/default/ {print $3; exit}'
        return
    fi
    if has_cmd route; then
        route -n get default 2>/dev/null | awk '/gateway/ {print $2; exit}'
        return
    fi
    if has_cmd netstat; then
        netstat -rn 2>/dev/null | awk '$1 == "default" || $1 == "0.0.0.0" {print $2; exit}'
        return
    fi
    printf 'unknown'
}

check_dns() {
    local host="$1"
    if has_cmd getent; then
        getent hosts "$host" 2>/dev/null | awk '{print $1; exit}'
        return
    fi
    if has_cmd dig; then
        dig +short "$host" 2>/dev/null | take_n 1
        return
    fi
    if has_cmd host; then
        host "$host" 2>/dev/null | awk '/has address/ {print $NF; exit}'
        return
    fi
    if has_cmd nslookup; then
        nslookup "$host" 2>/dev/null | awk '/^Address: / {print $2; exit}'
        return
    fi
    return 1
}

check_internet() {
    local target="$1" timeout_cmd=""
    has_cmd timeout && timeout_cmd="timeout 5"
    has_cmd gtimeout && timeout_cmd="gtimeout 5"

    if ! has_cmd ping; then
        return 2
    fi
    $timeout_cmd ping -c 1 "$target" >/dev/null 2>&1
}

get_listening_ports() {
    local count="$1"
    if has_cmd ss; then
        {
            printf '%-6s %-22s %s\n' "PROTO" "LOCAL ADDRESS" "PROCESS"
            ss -tulpen 2>/dev/null | tail -n +2 | take_n "$count" \
                | awk '{print $1, $5, $NF}' | column -t 2>/dev/null
        }
        return
    fi
    if has_cmd lsof; then
        {
            printf '%-6s %-22s %s\n' "PROTO" "LOCAL ADDRESS" "PROCESS"
            lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2 | take_n "$count" \
                | awk '{print "tcp", $9, $1}'
        }
        return
    fi
    if has_cmd netstat; then
        {
            printf '%-6s %s\n' "PROTO" "LOCAL ADDRESS"
            netstat -an 2>/dev/null | grep -i listen | take_n "$count"
        }
        return
    fi
    printf 'no port-listing tool available (ss, lsof, or netstat required)\n'
}

run_network_checks() {
    local status="$STATUS_OK" port_n=10
    [[ "$VERBOSE" == true ]] && port_n=30

    local interfaces gateway dns_ip dns_status internet_status http_status="n/a" http_code=""
    local url="${NETWORK_HTTP_URL:-$HTTP_TEST_URL}"

    interfaces="$(list_interfaces)"
    [[ -z "$interfaces" ]] && interfaces="(none found)"
    gateway="$(get_default_gateway)"

    if dns_ip="$(check_dns "$DNS_TEST_HOST")" && [[ -n "$dns_ip" ]]; then
        dns_status="OK ($dns_ip)"
    else
        dns_status="FAILED"
        status="$(worse_status "$status" "$STATUS_WARNING")"
        add_recommendation "DNS resolution for $DNS_TEST_HOST failed."
    fi

    if check_internet "$PING_TARGET"; then
        internet_status="OK"
    else
        internet_status="FAILED"
        status="$(worse_status "$status" "$STATUS_WARNING")"
        add_recommendation "Outbound connectivity to $PING_TARGET failed."
    fi

    if [[ -n "$url" ]]; then
        if has_cmd curl; then
            http_code="$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' "$url" 2>/dev/null)"
            if [[ "$http_code" =~ ^[23][0-9][0-9]$ ]]; then
                http_status="OK ($http_code)"
            else
                http_status="FAILED (${http_code:-no response})"
                status="$(worse_status "$status" "$STATUS_WARNING")"
                add_recommendation "HTTP check for $url failed (${http_code:-no response})."
            fi
        elif has_cmd wget; then
            if wget -q --spider --timeout=5 "$url" 2>/dev/null; then
                http_status="OK"
            else
                http_status="FAILED"
                status="$(worse_status "$status" "$STATUS_WARNING")"
                add_recommendation "HTTP check for $url failed."
            fi
        else
            http_status="SKIPPED (no curl or wget)"
        fi
    fi

    local ports
    ports="$(get_listening_ports "$port_n")"

    local text
    text="$(cat <<EOF
Interfaces:
$interfaces

Default gateway: $gateway
DNS check ($DNS_TEST_HOST): $dns_status
Internet check ($PING_TARGET): $internet_status
HTTP check: $http_status
Status: $status

Listening ports:
$ports
EOF
)"

    local json
    json=$(cat <<EOF
{"gateway":$(json_string "$gateway"),"dns_check":$(json_string "$dns_status"),"internet_check":$(json_string "$internet_status"),"http_check":$(json_string "$http_status"),"status":$(json_string "$status")}
EOF
)

    register_section "network" "Network" "$status" "$text" "$json"
}
