# NetRecon - Advanced Network Reconnaissance Tool

**NetRecon** is an interactive, stealth-first network scanner designed for penetration testing and network analysis. It automatically detects devices, subnets, gateways, DNS servers, and VLANs on a local network with multiple detection modes and auto-switching for optimal results.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Passive Mode** | Stealthy detection using `tcpdump` (no packets sent) |
| **Promiscuous Mode** | Listens to all traffic on the interface |
| **ARP Scan Mode** | Actively sends ARP requests to detect devices |
| **MAC Spoof Mode** | Spoofs a detected device's MAC to capture its traffic |
| **Auto Mode** | Automatically switches modes based on detection results |
| **Real-time Display** | Colorful, dynamic output with device lists and network info |
| **OUI Database** | Uses nmap's OUI database for accurate manufacturer detection |
| **Random MAC** | Changes your MAC address at start (restored on exit) |
| **Keyboard Shortcuts** | Switch modes on the fly (`P`, `M`, `A`, `S`, `T`, `Q`, `R`) |
| **Physical Connection Check** | Asks for user confirmation before starting the scan |
| **Starting Mode Selection** | Lets you choose the initial mode (Auto recommended for beginners) |

---

## 📦 Installation

### One-liner (Debian/Parrot OS/Kali)
\`\`\`bash
sudo apt update && sudo apt install -y tcpdump arp-scan nmap bind9-host && wget https://raw.githubusercontent.com/kali-gvte/netrecon/main/netrecon.sh && chmod +x netrecon.sh
\`\`\`

### Manual Installation
1. Install dependencies:
   \`\`\`bash
   sudo apt update
   sudo apt install -y tcpdump arp-scan nmap bind9-host
   \`\`\`
2. Download the script:
   \`\`\`bash
   wget https://raw.githubusercontent.com/kali-gvte/netrecon/main/netrecon.sh
   \`\`\`
3. Make it executable:
   \`\`\`bash
   chmod +x netrecon.sh
   \`\`\`

---

## 🚀 Usage

### Basic Usage
\`\`\`bash
sudo ./netrecon.sh
\`\`\`

### Workflow
1. **Select Interface**: Choose the network interface to use (e.g., `eth0`).
2. **Connect Physically**: Plug your cable into the target network and press **Enter** to confirm.
3. **Select Starting Mode**:
   - `1` or `P`: Passive mode (stealth)
   - `2` or `M`: Promiscuous mode
   - `3` or `A`: ARP scan mode (active)
   - `4` or `T` or **Enter**: **Auto mode (recommended if unsure)**
4. **Switch Modes**: Use keyboard shortcuts to change modes:
   - `P`: Passive mode
   - `M`: Promiscuous mode
   - `A`: ARP scan mode
   - `S`: MAC spoof mode
   - `T`: Auto mode
   - `Q`: Quit

### In MAC Spoof Mode
- `R`: Restore original MAC and select a new target to spoof.

---

## 📊 Modes Overview

| Mode       | Description                          | Detectability | Best For                     |
|------------|--------------------------------------|---------------|------------------------------|
| **Passive**    | Listens to existing traffic           | 🟢 Stealth    | Initial scan on quiet networks |
| **Promiscuous**| Listens to all traffic on interface    | 🟢 Stealth    | Hubs or misconfigured switches |
| **ARP Scan**   | Sends ARP requests                    | 🟠 Detectable | Modern switches (recommended) |
| **MAC Spoof**  | Spoofs a device's MAC to capture traffic | 🔴 Detectable | Advanced traffic capture      |
| **Auto**       | Switches modes based on results       | Varies        | Beginners & convenience       |

---

## ⚠️ Warnings

- **MAC Address Change**: The script changes your interface's MAC address at start (restored on exit). This may briefly disconnect your network.
- **Active Modes**: ARP scan and MAC spoofing are **detectable** and may disrupt network services.
- **Switch Limitations**: Passive/promiscuous modes **won't work on modern switches** (use ARP scan instead).
- **Gateway Spoofing**: Spoofing the gateway may **disrupt network connectivity** for all devices.
- **Spoof Mode Requirement**: Spoof mode requires prior device detection and cannot be selected at start.

---

## 🔧 Troubleshooting

### No devices detected?
- **On a switch**: Use **ARP scan mode (A)**. Passive/promiscuous modes won't work on modern switches.
- **No physical connection**: Ensure your cable is properly connected and the interface is UP.
- **Firewall/IDS blocking**: Active modes (ARP, Spoof) may be blocked by network security.

### Connection drops after running?
The script restores your original MAC on exit. If issues persist, manually restart your network interface:
\`\`\`bash
sudo ip link set <interface> down && sudo ip link set <interface> up
\`\`\`

### Missing dependencies?
Run the one-liner installation command above.

---

## 📜 License
MIT License - Feel free to use, modify, and distribute.

---

## 🤝 Contributing
Pull requests are welcome! Focus on:
- Adding new detection methods (e.g., DHCP, LLDP).
- Improving stealth (e.g., slower ARP scans).
- Supporting more network configurations.
- Enhancing the OUI database integration.

---

## 📌 Notes
- **Tested on Parrot OS**, but should work on most Linux distributions.
- **Requires root privileges** to change MAC addresses and capture traffic.
- For **best results on a switch**, use **ARP scan mode (A)** or **MAC spoof mode (S)**.
