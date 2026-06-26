#!/bin/bash

# netrecon - Advanced Network Reconnaissance Tool
# Version: 1.0
# Description: Interactive network scanner with passive/active detection, MAC spoofing, and auto mode
# Author: Kali Gvte
# Priority: Parrot OS, cross-distribution compatible

set -euo pipefail

# --- Global Variables ---
INTERFACE=""                     # Selected network interface
TEMP_DIR="/tmp/netrecon_$(date +%s)"
DEVICES_FILE="$TEMP_DIR/devices.txt"
NETWORK_INFO_FILE="$TEMP_DIR/network_info.txt"
MODE=""                         # Current mode: passive, promisc, arp, spoof, auto
COLORS_ENABLED=true
ORIGINAL_MAC=""                  # Original MAC address
SPOOFED_MAC=""                   # Spoofed MAC address
SPOOF_TARGET_IP=""               # Target IP for spoofing
OUI_DB_FILE=""                   # OUI database file path
RANDOM_MAC=""                    # Random MAC for initial scan

# --- Color Definitions ---
if [ "$COLORS_ENABLED" = true ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; MAGENTA=''; CYAN=''; WHITE=''; BOLD=''; NC=''
fi

# --- Functions ---
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}[!] This script must be run as root. Use sudo.${NC}"
        exit 1
    fi
}

find_oui_db() {
    if [ -f "/usr/share/nmap/nmap-mac-prefixes" ]; then
        OUI_DB_FILE="/usr/share/nmap/nmap-mac-prefixes"
    elif [ -f "/usr/share/nmap/mac-prefixes" ]; then
        OUI_DB_FILE="/usr/share/nmap/mac-prefixes"
    elif command -v nmap &>/dev/null; then
        OUI_DB_FILE=$(nmap --script-args-list 2>/dev/null | grep -i "mac-prefixes" | awk -F'=' '{print $2}' | tr -d '"' || echo "")
        [ -z "$OUI_DB_FILE" ] || [ ! -f "$OUI_DB_FILE" ] && OUI_DB_FILE=""
    fi

    if [ -z "$OUI_DB_FILE" ] || [ ! -f "$OUI_DB_FILE" ]; then
        for path in /usr/share/ieee-data/oui.txt /usr/share/misc/oui.txt /etc/oui.txt; do
            [ -f "$path" ] && OUI_DB_FILE="$path" && break
        done
    fi

    if [ -z "$OUI_DB_FILE" ] || [ ! -f "$OUI_DB_FILE" ]; then
        OUI_DB_FILE="$TEMP_DIR/oui_db.txt"
        cat > "$OUI_DB_FILE" << 'EOF'
00:11:22:Cisco
00:1C:B3:Cisco
00:0C:29:VMware
00:50:56:VMware
00:0D:3A:Microsoft
00:1D:0F:Samsung
00:1E:68:Apple
00:21:5A:Hewlett Packard
00:23:12:Dell
08:00:27:Cadmus Computer Systems
00:0F:4B:Dell
3C:97:0E:Wistron InfoComm
3C:CD:5A:Technicolor
74:D4:35:Apple
B8:27:EB:Raspberry Pi Foundation
DC:A6:32:Raspberry Pi Foundation
00:16:3E:Xensource
00:1A:4B:Devolo AG
00:1B:21:Dell
00:1C:42:Parallels
00:1D:7E:Cisco
00:21:70:ZTE Corporation
00:22:48:Sony
00:23:DF:Apple
00:25:4B:Apple
00:26:BB:Samsung Electronics
00:50:F2:Microsoft
00:90:0B:Cisco
00:E0:4C:Realtek
50:C7:BF:TP-Link
60:01:94:Espressif
28:CF:DA:Apple
34:64:A9:Amazon Technologies
3C:28:50:Intel
3C:5A:B4:Google
44:37:E6:Hon Hai Precision
54:EE:75:Apple
5C:51:4F:Intel
60:6B:BD:Samsung Electronics
68:5B:35:Apple
78:31:C1:Apple
78:4F:43:Apple
7C:6D:62:Apple
84:38:35:Apple
88:66:A5:Apple
90:72:40:Apple
A4:83:E7:Microsoft
C8:2A:14:Apple
D8:30:62:Apple
DC:71:44:Samsung Electronics
E0:DB:55:Dell
F0:18:98:Apple
EOF
    fi
    echo -e "${GREEN}[+] Using OUI database: $OUI_DB_FILE${NC}"
}

generate_random_mac() {
    local octets=(
        $(printf "%02X" $((RANDOM % 256)))
        "02"
        $(printf "%02X" $((RANDOM % 256)))
        $(printf "%02X" $((RANDOM % 256)))
        $(printf "%02X" $((RANDOM % 256)))
        $(printf "%02X" $((RANDOM % 256)))
    )
    echo "${octets[0]}:${octets[1]}:${octets[2]}:${octets[3]}:${octets[4]}:${octets[5]}"
}

change_mac() {
    local new_mac=$1
    [ -n "$new_mac" ] && {
        echo -e "${YELLOW}[+] Changing MAC to $new_mac...${NC}"
        ip link set "$INTERFACE" down
        ip link set "$INTERFACE" address "$new_mac"
        ip link set "$INTERFACE" up
        echo -e "${GREEN}[+] MAC changed to $new_mac${NC}"
    }
}

restore_mac() {
    [ -n "$ORIGINAL_MAC" ] && {
        echo -e "${YELLOW}[+] Restoring original MAC: $ORIGINAL_MAC...${NC}"
        ip link set "$INTERFACE" down 2>/dev/null || true
        ip link set "$INTERFACE" address "$ORIGINAL_MAC" 2>/dev/null || true
        ip link set "$INTERFACE" up 2>/dev/null || true
        SPOOFED_MAC=""
        SPOOF_TARGET_IP=""
    }
}

list_physical_interfaces() {
    echo -e "${GREEN}[+] Detecting physical interfaces...${NC}"
    local interfaces=()
    while IFS= read -r line; do
        local iface=$(echo "$line" | awk -F: '{print $2}' | tr -d ' ')
        [[ ! "$iface" =~ ^(lo|tun|docker|veth|virbr|vmnet) ]] && [[ "$iface" =~ ^[a-z]+[0-9]*$ ]] && interfaces+=("$iface")
    done < <(ip link | grep -E '^[0-9]+: ' || true)

    [ ${#interfaces[@]} -eq 0 ] && { echo -e "${RED}[!] No physical interfaces detected.${NC}"; exit 1; }

    echo -e "${GREEN}[+] Available interfaces:${NC}"
    for i in "${!interfaces[@]}"; do echo "  $((i+1)). ${interfaces[$i]}"; done

    read -p "[?] Select an interface (number): " choice
    ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#interfaces[@]} ] && { echo -e "${RED}[!] Invalid choice.${NC}"; exit 1; }
    INTERFACE="${interfaces[$((choice-1))]}"
    echo -e "${GREEN}[+] Selected interface: $INTERFACE${NC}"

    ORIGINAL_MAC=$(ip link show "$INTERFACE" | awk '/link\/ether/ {print $2}')
    echo -e "${GREEN}[+] Original MAC: $ORIGINAL_MAC${NC}"

    echo -e "${YELLOW}[!] Please physically connect to the target network with $INTERFACE.${NC}"
    read -p "[?] Press Enter when ready (or Ctrl+C to abort): " confirm

    if ! ip link show "$INTERFACE" | grep -q "UP"; then
        echo -e "${RED}[!] Interface $INTERFACE is not UP. Check physical connection.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}[+] Checking for link activity on $INTERFACE...${NC}"
    timeout 3 tcpdump -i "$INTERFACE" -c 1 -nn -q >/dev/null 2>&1
    [ $? -ne 0 ] && { echo -e "${RED}[!] No traffic detected on $INTERFACE. Check physical connection.${NC}"; exit 1; }

    RANDOM_MAC=$(generate_random_mac)
    change_mac "$RANDOM_MAC"
    [ ! $(ip link show "$INTERFACE" | grep -q "UP") ] && { echo -e "${YELLOW}[+] Activating interface $INTERFACE...${NC}"; ip link set "$INTERFACE" up; }
}

select_start_mode() {
    echo -e "
${GREEN}[+] Select starting mode:${NC}"
    echo -e "  ${BOLD}1. Passive Mode (P)${NC} - Stealthy, no packets sent (undetectable)"
    echo -e "  ${BOLD}2. Promiscuous Mode (M)${NC} - Listens to all traffic on port"
    echo -e "  ${BOLD}3. ARP Scan Mode (A)${NC} - Sends ARP requests (detectable)"
    echo -e "  ${BOLD}4. Auto Mode (T)${NC} - Automatically switches modes based on results (${YELLOW}recommended if unsure${NC})"
    echo -e "  ${RED}[Note: Spoof mode (S) requires prior device detection and cannot be selected at start.${NC}"
    echo ""
    read -p "[?] Select starting mode (number, default=4 for Auto): " mode_choice

    case "$mode_choice" in
        1|p|P) MODE="passive" ;;
        2|m|M) MODE="promisc" ;;
        3|a|A) MODE="arp" ;;
        4|t|T|""|"") MODE="auto" ;;
        *)
            echo -e "${RED}[!] Invalid choice. Defaulting to Auto mode.${NC}"
            MODE="auto"
            ;;
    esac
    echo -e "${GREEN}[+] Starting in ${MODE} mode.${NC}"
}

init_terminal() { stty -echo -icanon -icrnl time 0 min 0; }
restore_terminal() { stty echo icanon icrnl; }

check_keyboard_input() {
    if read -r -s -n 1 -t 0.1 key; then
        case "$key" in
            p) MODE="passive";; m) MODE="promisc";; a) MODE="arp";; s) MODE="spoof";; t) MODE="auto";; q) cleanup;; esac
    fi
}

enable_promisc() { ip link show "$INTERFACE" | grep -q "PROMISC" || { echo -e "${YELLOW}[+] Enabling promiscuous mode...${NC}"; ip link set "$INTERFACE" promisc on; }; }
disable_promisc() { ip link show "$INTERFACE" | grep -q "PROMISC" && { echo -e "${YELLOW}[+] Disabling promiscuous mode...${NC}"; ip link set "$INTERFACE" promisc off; }; }

spoof_mac() {
    local target_mac=$1
    [ -n "$target_mac" ] && {
        echo -e "${MAGENTA}[!] Spoofing MAC: $target_mac${NC}"
        ip link set "$INTERFACE" down
        ip link set "$INTERFACE" address "$target_mac"
        ip link set "$INTERFACE" up
        SPOOFED_MAC="$target_mac"
    }
}

select_spoof_target() {
    [ ! -s "$DEVICES_FILE" ] && { echo -e "${RED}[!] No devices detected. Switch to ARP mode first.${NC}"; MODE="arp"; return; }

    echo -e "${MAGENTA}[?] Select a device to spoof (or press Enter to cancel):${NC}"
    echo "# Detected devices:"
    cat -n "$DEVICES_FILE" | while read -r num line; do echo "  $num. $line"; done
    read -p "[?] Enter device number: " choice

    [[ "$choice" =~ ^[0-9]+$ ]] && {
        local selected_line=$(sed -n "${choice}p" "$DEVICES_FILE")
        [ -n "$selected_line" ] && {
            SPOOF_TARGET_IP=$(echo "$selected_line" | cut -d'|' -f2 | tr -d ' ')
            local target_mac=$(echo "$selected_line" | cut -d'|' -f3 | tr -d ' ')
            local gateway=$(get_gateway)

            [ "$SPOOF_TARGET_IP" = "$gateway" ] && {
                echo -e "${RED}[!] Warning: Spoofing the gateway may disrupt network connectivity.${NC}"
                read -p "[?] Continue anyway? (y/N): " confirm
                [[ ! "$confirm" =~ ^[Yy]$ ]] && { SPOOF_TARGET_IP=""; return; }
            }
            spoof_mac "$target_mac"
        }
    }
}

get_gateway() { [ -f "$TEMP_DIR/dst_ips.txt" ] && [ -s "$TEMP_DIR/dst_ips.txt" ] && sort "$TEMP_DIR/dst_ips.txt" | uniq -c | sort -nr | head -n 1 | awk '{print $2}' || echo ""; }
get_subnet() { [ -f "$NETWORK_INFO_FILE" ] && [ -s "$NETWORK_INFO_FILE" ] && grep "^Network:" "$NETWORK_INFO_FILE" | awk '{print $2}' | head -n 1 || echo ""; }
get_device_count() { [ -f "$DEVICES_FILE" ] && wc -l < "$DEVICES_FILE" | tr -d ' ' || echo "0"; }

get_manufacturer() {
    local mac=$1
    local mac_prefix=${mac:0:8}
    mac_prefix=${mac_prefix//:/}
    mac_prefix=${mac_prefix:0:6}

    [ -n "$OUI_DB_FILE" ] && [ -f "$OUI_DB_FILE" ] && {
        local result
        result=$(grep -i "^${mac_prefix:0:2}:${mac_prefix:2:2}:${mac_prefix:4:2}" "$OUI_DB_FILE" | head -n 1 | cut -d' ' -f2- | tr -d '\n')
        [ -n "$result" ] && { echo "$result"; return; }
        result=$(grep -i "^${mac_prefix}" "$OUI_DB_FILE" | head -n 1 | cut -d' ' -f2- | tr -d '\n')
        [ -n "$result" ] && { echo "$result"; return; }
    }
    echo "Unknown"
}

resolve_hostname() {
    local ip=$1
    local hostname
    hostname=$(host -W 1 "$ip" 2>/dev/null | awk '{print $NF}' | tr -d '.') || hostname="N/A"
    echo "$hostname"
}

process_packet() {
    local line="$1"
    if echo "$line" | grep -q "ARP"; then
        local ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
        local mac=$(echo "$line" | grep -oE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' | head -n 1)
        [ -n "$ip" ] && [ -n "$mac" ] && {
            local manufacturer=$(get_manufacturer "$mac")
            local hostname=$(resolve_hostname "$ip")
            ! grep -q "$mac" "$DEVICES_FILE" && echo "$hostname | $ip | $mac | $manufacturer" >> "$DEVICES_FILE"
        }
    fi

    local network_range=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}' | head -n 1)
    [ -n "$network_range" ] && ! grep -q "Network: $network_range" "$NETWORK_INFO_FILE" && echo "Network: $network_range" >> "$NETWORK_INFO_FILE"

    local dst_ip=$(echo "$line" | grep -oE 'IP ([0-9]{1,3}\.){3}[0-9]{1,3} >' | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
    [ -n "$dst_ip" ] && ! echo "$dst_ip" | grep -qE '^255\.|^224\.|^239\.' && echo "$dst_ip" >> "$TEMP_DIR/dst_ips.txt"

    echo "$line" | grep -q ":53" && {
        local dns_ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
        [ -n "$dns_ip" ] && ! grep -q "DNS: $dns_ip" "$NETWORK_INFO_FILE" && echo "DNS: $dns_ip" >> "$NETWORK_INFO_FILE"
    }

    echo "$line" | grep -q "802.1Q" && {
        local vlan_id=$(echo "$line" | grep -oE 'vlan [0-9]+' | grep -oE '[0-9]+')
        [ -n "$vlan_id" ] && ! grep -q "VLAN: $vlan_id" "$NETWORK_INFO_FILE" && echo "VLAN: $vlan_id" >> "$NETWORK_INFO_FILE"
    }
}

passive_scan() {
    local tcpdump_output="$TEMP_DIR/tcpdump_output.txt"
    > "$tcpdump_output"
    echo -e "${GREEN}[+] Starting passive scan on $INTERFACE...${NC}"
    echo -e "${YELLOW}[!] Press (P)assive, (M)isc, (A)RP, (S)poof, (T)auto, (Q)uit to change mode.${NC}"
    tcpdump -i "$INTERFACE" -nn -q -l -t 2>/dev/null | while IFS= read -r line; do
        echo "$line" >> "$tcpdump_output"
        process_packet "$line"
        check_keyboard_input
        [ "$MODE" != "passive" ] && break
    done
}

arp_scan() {
    echo -e "${MAGENTA}[!] Running ARP scan (active mode - detectable)...${NC}"
    echo -e "${YELLOW}[!] Press (P)assive, (M)isc, (A)RP, (S)poof, (T)auto, (Q)uit to change mode.${NC}"
    command -v arp-scan &>/dev/null || { echo -e "${RED}[+] Installing arp-scan...${NC}"; apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq arp-scan >/dev/null 2>&1; }
    arp-scan --interface="$INTERFACE" --localnet --quiet --ignoredups | while IFS= read -r line; do
        echo "$line" | grep -q "\." && {
            local ip=$(echo "$line" | awk '{print $1}')
            local mac=$(echo "$line" | awk '{print $2}')
            local manufacturer=$(echo "$line" | awk '{print $3}' | tr -d '()')
            local hostname=$(resolve_hostname "$ip")
            ! grep -q "$mac" "$DEVICES_FILE" && echo "$hostname | $ip | $mac | $manufacturer" >> "$DEVICES_FILE"
        }
        check_keyboard_input
        [ "$MODE" != "arp" ] && break
    done
}

spoof_mode() {
    # Check if there are devices to spoof
    if [ ! -s "$DEVICES_FILE" ]; then
        echo -e "${RED}[!] No devices detected. Spoof mode requires prior detection. Switching to ARP scan mode...${NC}"
        MODE="arp"
        arp_scan
        return
    fi
    
    [ -z "$SPOOFED_MAC" ] && { select_spoof_target; [ -z "$SPOOFED_MAC" ] && { MODE="auto"; return; }; }
    echo -e "${MAGENTA}[!] Spoofing MAC: $SPOOFED_MAC (Target: $SPOOF_TARGET_IP)...${NC}"
    echo -e "${YELLOW}[!] Press (P)assive, (M)isc, (A)RP, (S)poof, (T)auto, (Q)uit to change mode.${NC}"
    echo -e "${YELLOW}[!] Press (R) to restore MAC and select a new target.${NC}"
    local tcpdump_output="$TEMP_DIR/tcpdump_output_spoof.txt"
    > "$tcpdump_output"
    tcpdump -i "$INTERFACE" -nn -q -l -t 2>/dev/null | while IFS= read -r line; do
        echo "$line" >> "$tcpdump_output"
        process_packet "$line"
        check_keyboard_input
        if read -r -s -n 1 -t 0.1 key_restore; then
            [ "$key_restore" = "r" ] && { restore_mac; echo -e "${GREEN}[+] MAC restored. Select a new target to spoof.${NC}"; }
        fi
        [ "$MODE" != "spoof" ] && break
    done
}

auto_mode() {
    echo -e "${CYAN}[+] Auto mode: Starting with passive scan for 5 seconds...${NC}"
    MODE="passive"
    echo -e "${CYAN}[+] Trying passive mode for 5 seconds...${NC}"
    timeout 5 bash -c "tcpdump -i '$INTERFACE' -nn -q -l -t 2>/dev/null | while IFS= read -r line; do echo "\$line" >> '$TEMP_DIR/tcpdump_output.txt'; process_packet "\$line"; done" >/dev/null 2>&1

    local has_devices=$(get_device_count)
    local has_subnet=$(get_subnet)
    local has_gateway=$(get_gateway)

    if [ "$has_devices" -gt 0 ] && [ -n "$has_subnet" ] && [ -n "$has_gateway" ]; then
        echo -e "${GREEN}[+] Network fully detected in passive mode!${NC}"
        echo -e "${GREEN}[+] Subnet: $has_subnet | Gateway: $has_gateway | Devices: $has_devices${NC}"
        MODE="passive"
    else
        echo -e "${YELLOW}[!] Incomplete detection in passive mode.${NC}"
        local missing=""
        [ "$has_devices" -eq 0 ] && missing+="No devices detected. "
        [ -z "$has_subnet" ] && missing+="No subnet detected. "
        [ -z "$has_gateway" ] && missing+="No gateway detected. "
        echo -e "${YELLOW}[!] $missing${NC}"

        read -p "[?] Switch to promiscuous mode? (Y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ || -z "$confirm" ]]; then
            MODE="promisc"
            enable_promisc
            echo -e "${CYAN}[+] Trying promiscuous mode for 5 seconds...${NC}"
            timeout 5 bash -c "tcpdump -i '$INTERFACE' -nn -q -l -t 2>/dev/null | while IFS= read -r line; do echo "\$line" >> '$TEMP_DIR/tcpdump_output.txt'; process_packet "\$line"; done" >/dev/null 2>&1

            has_devices=$(get_device_count)
            has_subnet=$(get_subnet)
            has_gateway=$(get_gateway)

            if [ "$has_devices" -gt 0 ] && [ -n "$has_subnet" ] && [ -n "$has_gateway" ]; then
                echo -e "${GREEN}[+] Network fully detected in promiscuous mode!${NC}"
                echo -e "${GREEN}[+] Subnet: $has_subnet | Gateway: $has_gateway | Devices: $has_devices${NC}"
                MODE="promisc"
            else
                echo -e "${YELLOW}[!] Incomplete detection in promiscuous mode.${NC}"
                missing=""
                [ "$has_devices" -eq 0 ] && missing+="No devices detected. "
                [ -z "$has_subnet" ] && missing+="No subnet detected. "
                [ -z "$has_gateway" ] && missing+="No gateway detected. "
                echo -e "${YELLOW}[!] $missing${NC}"

                read -p "[?] Switch to ARP scan mode? (Y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ || -z "$confirm" ]]; then
                    MODE="arp"
                    arp_scan

                    has_devices=$(get_device_count)
                    has_subnet=$(get_subnet)
                    has_gateway=$(get_gateway)

                    if [ "$has_devices" -gt 0 ] && [ -n "$has_subnet" ] && [ -n "$has_gateway" ]; then
                        echo -e "${GREEN}[+] Network fully detected in ARP mode!${NC}"
                        echo -e "${GREEN}[+] Subnet: $has_subnet | Gateway: $has_gateway | Devices: $has_devices${NC}"
                        read -p "[?] Try MAC spoofing for better detection? (y/N): " spoof_confirm
                        [[ "$spoof_confirm" =~ ^[Yy]$ ]] && { MODE="spoof"; select_spoof_target; } || MODE="auto"
                    else
                        echo -e "${RED}[!] Incomplete detection in ARP mode. No more options.${NC}"
                        MODE="auto"
                    fi
                else
                    MODE="auto"
                fi
            fi
        else
            MODE="auto"
        fi
    fi
    auto_mode
}

display_summary() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN} NetRecon - Network Reconnaissance Tool${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}Interface: $INTERFACE | Mode: ${BOLD}$MODE${NC}${YELLOW} | Press: (P)assive, (M)isc, (A)RP, (S)poof, (T)auto, (Q)uit${NC}"

    case "$MODE" in
        passive) echo -e "${GREEN}[STEALTH] Passive mode - No packets sent, undetectable${NC}" ;;
        promisc) echo -e "${YELLOW}[CAUTIOUS] Promiscuous mode - Listening to all traffic on port${NC}" ;;
        arp)     echo -e "${MAGENTA}[ACTIVE] ARP scan mode - Sending ARP requests, detectable${NC}" ;;
        spoof)   echo -e "${RED}[SPOOFING] MAC Spoof mode - Spoofing $SPOOFED_MAC (Target: $SPOOF_TARGET_IP)${NC}" ;;
        auto)    echo -e "${CYAN}[AUTO] Auto mode - Switching modes based on results${NC}" ;;
    esac

    [ "$MODE" = "spoof" ] && echo -e "${YELLOW}[!] Press (R) to restore MAC and select a new target.${NC}"

    local has_devices=$(get_device_count)
    local has_subnet=$(get_subnet)
    local has_gateway=$(get_gateway)

    ([ "$has_devices" -eq 0 ] || [ -z "$has_subnet" ] || [ -z "$has_gateway" ]) && {
        echo -e "${RED}[!] Incomplete network detection.${NC}"
        [ "$has_devices" -eq 0 ] && echo -e "${RED}[!] No devices detected.${NC}"
        [ -z "$has_subnet" ] && echo -e "${RED}[!] No subnet detected.${NC}"
        [ -z "$has_gateway" ] && echo -e "${RED}[!] No gateway detected.${NC}"
        echo -e "${YELLOW}[!] Try a more active mode for better results.${NC}"
    }

    echo ""
    echo -e "${BLUE}--- Detected Devices ($has_devices) ---${NC}"
    [ -f "$DEVICES_FILE" ] && [ -s "$DEVICES_FILE" ] && {
        printf "%-20s | %-16s | %-18s | %-20s\n" "Hostname" "IP Address" "MAC Address" "Manufacturer"
        printf "%-20s-+-%-16s-+-%-18s-+-%-20s\n" "--------------------" "----------------" "------------------" "--------------------"
        sort -u "$DEVICES_FILE" | while IFS="|" read -r hostname ip mac manufacturer; do
            printf "%-20s | %-16s | %-18s | %-20s\n" "$hostname" "$ip" "$mac" "$manufacturer"
        done
    } || echo "No devices detected yet."

    echo ""
    echo -e "${BLUE}--- Network Information ---${NC}"
    [ -f "$NETWORK_INFO_FILE" ] && [ -s "$NETWORK_INFO_FILE" ] && {
        has_subnet=$(get_subnet)
        has_gateway=$(get_gateway)
        local dns_servers=$(grep "^DNS:" "$NETWORK_INFO_FILE" | awk '{print $2}' | tr '
' ' ')
        local vlans=$(grep "^VLAN:" "$NETWORK_INFO_FILE" | awk '{print $2}' | tr '
' ' ')
        [ -n "$has_subnet" ] && echo -e "${GREEN}Subnet:${NC} $has_subnet"
        [ -n "$has_gateway" ] && echo -e "${GREEN}Gateway (guess):${NC} $has_gateway"
        [ -n "$dns_servers" ] && echo -e "${GREEN}DNS servers:${NC} $dns_servers"
        [ -n "$vlans" ] && echo -e "${GREEN}VLAN(s):${NC} $vlans"
    } || echo "No network information detected yet."

    echo ""
    echo -e "${YELLOW}Scan duration: $(awk '{print $1}' /proc/uptime | cut -d. -f1) seconds${NC}"
    echo ""
}

cleanup() {
    restore_terminal
    disable_promisc
    restore_mac
    rm -rf "$TEMP_DIR"
    echo ""
    echo -e "${RED}[!] Scan stopped. Terminal and MAC restored.${NC}"
    exit 0
}

trap cleanup EXIT INT TERM QUIT ABRT

main() {
    check_root
    find_oui_db
    init_terminal
    mkdir -p "$TEMP_DIR"
    list_physical_interfaces
    select_start_mode

    > "$DEVICES_FILE"
    > "$NETWORK_INFO_FILE"
    > "$TEMP_DIR/dst_ips.txt"

    echo -e "\n${GREEN}[+] Starting NetRecon on $INTERFACE${NC}"
    echo -e "${GREEN}[+] Random MAC set: $RANDOM_MAC (Original: $ORIGINAL_MAC)${NC}"
    echo -e "${GREEN}[+] Press:${NC} ${BOLD}(P)${NC}${GREEN}assive, ${NC}${BOLD}(M)${NC}${GREEN}isc, ${NC}${BOLD}(A)${NC}${GREEN}RP, ${NC}${BOLD}(S)${NC}${GREEN}poof, ${NC}${BOLD}(T)${NC}${GREEN}auto, ${NC}${BOLD}(Q)${NC}${GREEN}uit${NC}"
    sleep 2

    while true; do
        case "$MODE" in
            passive) passive_scan ;;
            promisc) enable_promisc; passive_scan ;;
            arp) arp_scan ;;
            spoof) spoof_mode ;;
            auto) auto_mode ;;
        esac
        display_summary
    done
}

main
