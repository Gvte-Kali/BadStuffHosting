#!/usr/bin/env python3
"""
PharmaScan - Network Discovery Tool
Author: b1g_ph4rm4
"""

import argparse
import netifaces
import socket
import struct
from scapy.all import *
import time
import os
import sys
import threading

# Global IP tracker
detected_ips = set()

def print_banner():
    """Display custom ASCII art banner"""
    print("\033[1;36m")
    print("\033[0m\033[1;33m")
    print("author : b1g_ph4rm4                  |")
    print("_____________________________________|")
    print("            ,        ,               |")
    print("           /(        )`              |")
    print("           \ \___   / |              |")
    print("           /- _  `-/  '              |")
    print("          (/\/ \ \   /\              |")
    print("          / /   | `                  |")
    print("          O O   ) /    |             |")
    print("          `-^--'`<     '             |")
    print("         (_.)  _  )   /              |")
    print("          `.___/`    /               |")
    print("            `-----' /                |")
    print("<----.     __ / __   \               |")
    print("<----|====O)))==) \) /====           |")
    print("<----'    `--' `.__,' \              |")
    print("            |        |               |")
    print("             \       /               |")
    print("       ______( (_  / \______         |")
    print("     ,'  ,-----'   |        \        |")
    print("     `--{__________)        \/       |")
    print("_____________________________________|")
    print("\033[0m")
    print("Network Discovery Tool")
    print("Usage: pharmascan [--passive] [--aggressive] [--interface IFACE]")
    print("       pharmascan -h for detailed help\n")

def print_help():
    """Display extended help"""
    print("\033[1;36mPharmaScan - Network Discovery Tool\033[0m")
    print("Author: b1g_ph4rm4\n")
    print("\033[1mDESCRIPTION:\033[0m")
    print("  Discovers IP ranges in unknown networks through:")
    print("  - Passive network traffic listening")
    print("  - Active probing (ARP/ping) to stimulate responses")
    print("  Auto-detects and restores interface settings after scanning\n")
    
    print("\033[1mMODES:\033[0m")
    print("  \033[1m--passive\033[0m (default)")
    print("      - Listens for ARP and IP packets")
    print("      - No network traffic generated")
    print("      - Safe for stealth operations\n")
    
    print("  \033[1m--aggressive\033[0m")
    print("      - Sends ARP probes to common subnets")
    print("      - Pings broadcast address")
    print("      - Generates network traffic to reveal hosts\n")
    
    print("\033[1mOPTIONS:\033[0m")
    print("  \033[1m--interface IFACE\033[0m")
    print("      Specify network interface (e.g., eth0, wlan0)")
    print("      If omitted, interactive selection is shown\n")
    
    print("\033[1mEXAMPLES:\033[0m")
    print("  pharmascan --passive")
    print("  pharmascan --aggressive --interface wlan0")
    print("  pharmascan -h\n")
    
    print("\033[1mNOTES:\033[0m")
    print("  - Requires root privileges for raw socket access")
    print("  - ARP scanning covers RFC 1918 private ranges")
    print("  - Auto-restores interface promiscuity settings")
    sys.exit(0)

def get_promisc_state(iface):
    """Get initial promiscuity state"""
    try:
        with open(f"/sys/class/net/{iface}/flags", 'r') as f:
            flags = int(f.read().strip(), 16)
            return (flags & 0x100) != 0  # IFF_PROMISC = 0x100
    except:
        return False

def set_promisc_state(iface, state):
    """Set interface promiscuity"""
    try:
        os.system(f"ip link set {iface} promisc {'on' if state else 'off'}")
    except:
        pass

def select_interface():
    """List available interfaces"""
    print("\nAvailable interfaces:")
    valid_ifaces = []
    for iface in netifaces.interfaces():
        if iface == 'lo':
            continue
        addrs = netifaces.ifaddresses(iface)
        if netifaces.AF_INET in addrs:
            ip = addrs[netifaces.AF_INET][0].get('addr', 'No IP')
            print(f"- {iface} (IP: {ip})")
            valid_ifaces.append(iface)
    
    while True:
        iface = input("\nSelect interface: ").strip()
        if iface in valid_ifaces:
            return iface
        print("Invalid interface. Try again.")

def packet_handler(pkt):
    """Process captured packets"""
    if pkt.haslayer(ARP):
        ip = pkt[ARP].psrc
        print(f"[+] ARP detected: {ip} (MAC: {pkt[ARP].hwsrc})")
        detected_ips.add(ip)
    elif pkt.haslayer(IP):
        src = pkt[IP].src
        dst = pkt[IP].dst
        if not src.startswith("169.254.") and not dst.startswith("169.254."):
            print(f"[+] IP packet: {src} -> {dst}")
            detected_ips.add(src)
            detected_ips.add(dst)

def calculate_broadcast(ip, netmask):
    """Calculate broadcast address"""
    ip_int = struct.unpack("!I", socket.inet_aton(ip))[0]
    mask_int = struct.unpack("!I", socket.inet_aton(netmask))[0]
    broadcast_int = ip_int | ~mask_int
    return socket.inet_ntoa(struct.pack("!I", broadcast_int & 0xFFFFFFFF))

def passive_scan(iface, original_promisc):
    """Passive listening mode"""
    print(f"\n\033[1;32m[+] Starting PASSIVE scan on {iface}\033[0m")
    print("Listening for network traffic... (Ctrl+C to stop)")
    try:
        sniff(iface=iface, prn=packet_handler, store=0)
    except KeyboardInterrupt:
        print("\nScan interrupted by user")
    except Exception as e:
        print(f"Error: {str(e)}")

def aggressive_scan(iface, original_promisc):
    """Active probing mode"""
    print(f"\n\033[1;31m[+] Starting AGGRESSIVE scan on {iface}\033[0m")
    
    # Get network configuration
    try:
        addrs = netifaces.ifaddresses(iface)
        if netifaces.AF_INET in addrs:
            ip_info = addrs[netifaces.AF_INET][0]
            ip = ip_info['addr']
            netmask = ip_info['netmask']
            broadcast = calculate_broadcast(ip, netmask)
            print(f"Detected IP: {ip}, Netmask: {netmask}")
            print(f"Broadcast: {broadcast}")
            
            # Generate ARP traffic
            print("\nSending ARP probes...")
            arp_thread = threading.Thread(target=send_arp_probes, args=(iface, ip, netmask))
            arp_thread.daemon = True
            arp_thread.start()
            
            # Send broadcast ping
            print("Sending broadcast ping...")
            os.system(f"ping -c 3 -b {broadcast} -I {iface} >/dev/null 2>&1 &")
    except:
        print("No IP configured, scanning common ranges")
        common_ranges = [
            "192.168.0.0/16", "10.0.0.0/8", "172.16.0.0/12"
        ]
        for net in common_ranges:
            print(f"Scanning {net}")
            os.system(f"arp-scan {net} >/dev/null 2>&1 &")
    
    # Start passive listening
    print("\nListening for responses... (Ctrl+C to stop)")
    try:
        sniff(iface=iface, prn=packet_handler, store=0, timeout=120)
    except KeyboardInterrupt:
        print("\nScan interrupted by user")
    except Exception as e:
        print(f"Error: {str(e)}")

def send_arp_probes(iface, ip, netmask):
    """Send ARP requests to common IPs"""
    base_ip = ".".join(ip.split('.')[:-1]) + "."
    
    # Scan common gateway addresses
    for i in [1, 10, 100, 254]:
        target_ip = base_ip + str(i)
        arp = ARP(pdst=target_ip)
        send(arp, iface=iface, verbose=False)
        time.sleep(0.1)
    
    # Scan entire subnet (limited)
    if netmask == "255.255.255.0":
        for i in range(2, 255):
            if i % 50 == 0:  # Limit traffic
                time.sleep(1)
            target_ip = base_ip + str(i)
            arp = ARP(pdst=target_ip)
            send(arp, iface=iface, verbose=False)

def analyze_ips(ip_list):
    """Analyze detected IPs for subnet patterns"""
    if not ip_list:
        return "No IPs detected for analysis"
    
    # Count first octets
    octet_counts = {}
    for ip in ip_list:
        first_octet = ip.split('.')[0]
        octet_counts[first_octet] = octet_counts.get(first_octet, 0) + 1
    
    # Find most common first octet
    common_octet = max(octet_counts, key=octet_counts.get)
    subnet_candidates = [ip for ip in ip_list if ip.startswith(common_octet + '.')]
    
    # Find min/max in subnet
    if subnet_candidates:
        sorted_ips = sorted(subnet_candidates, key=lambda x: [int(part) for part in x.split('.')])
        return f"Likely subnet: {sorted_ips[0].rsplit('.',1)[0]}.0/24 (IPs: {sorted_ips[0]} - {sorted_ips[-1]})"
    
    return "Multiple subnets detected: " + ", ".join(set(ip.split('.')[0] for ip in ip_list))

if __name__ == "__main__":
    # Help system
    if '-h' in sys.argv or '--help' in sys.argv:
        print_help()
    
    # Argument parsing
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('--passive', action='store_true', help='Passive mode (default)')
    parser.add_argument('--aggressive', action='store_true', help='Active probing')
    parser.add_argument('--interface', help='Specify network interface')
    args = parser.parse_args()
    
    # Display banner
    print_banner()
    
    # Root check
    if os.geteuid() != 0:
        print("\033[1;31m[!] Root privileges required!\033[0m")
        print("Please run with sudo")
        sys.exit(1)
    
    # Interface selection
    iface = args.interface if args.interface else select_interface()
    
    # Save and set promisc mode
    original_promisc = get_promisc_state(iface)
    set_promisc_state(iface, True)
    
    # Start scanning
    try:
        if args.aggressive:
            aggressive_scan(iface, original_promisc)
        else:
            passive_scan(iface, original_promisc)
    finally:
        # Restore original state
        set_promisc_state(iface, original_promisc)
        print(f"\nInterface {iface} promiscuity restored to {'ON' if original_promisc else 'OFF'}")
    
    # Results analysis
    print("\n" + "="*40)
    if detected_ips:
        print("\033[1;32m[+] Scan Results:\033[0m")
        print(f"Detected {len(detected_ips)} unique IPs")
        print("\n".join(sorted(detected_ips)))
        print("\n" + analyze_ips(detected_ips))
    else:
        print("\033[1;31m[!] No IP addresses detected\033[0m")
        print("Troubleshooting tips:")
        print("- Verify physical connection")
        print("- Try aggressive mode (--aggressive)")
        print("- Test different interface")
    
    print("="*40)
