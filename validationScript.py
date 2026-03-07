import socket
import logging

# Full Disclosure, I used Google, and Google Gemini to assist me in the creation of this script

# "Sanity Check" - Validation Script for Hospital Honeypot
# Goal is to knock on different relevant ports to validate the environment,
# and the avility to collect information, something essential when it comes to honeypots
# This script will be run within the AWS VPC, from the "Brain" instance to verify conectivity and logging
# This script is designed to trigger the ELK Stack (Elasticsearch, Logstash, Kibana) on the t3.large "Brain" instance

# How to Validate Demo: 
# Step 1. Run the Script from the "Brain" VM(t3.large)
# Step 2. Monitor Kibana Dashboard: Look for internal logs from the "Clinical Zone" assets
# Step 3. Verify Data Integrity: Ensure the logs appear as TLS-Encrypted beats traffic reaching the "Brain"

TARGETS = {
    # These will be the internal DNS names that will be defined in the Route 53 Private Hosted Zone (hospital.internal)
    # These can be replaced with static IP addresses, with a few changes if needed
    "Medical Workstation (SMB)": "medical-workstation.hospital.internal", # Windows 7 
    "Imaging Server (DICOM)": "pacs.hospital.internal",                  # Ubuntu + DCM4CHE 
    "IoT Gateway (HTTP/Modbus)": "iot-gateway.hospital.internal"         # Conpot 
}

# Common ports to "knock" for validation (can add more later)
# 80 - HTTP
# 445 - SMB, Windows espesific port, simulates a scan for vulnerabilities in the unpatched Windows 7 terminal
# 104 - DICOM (Digital Imaging and Communications in Medicine), this proves the PACS system is "visible"
# 502 - Modbus, Port relevant to exploiting vulnerabilities, IoT Gateway that mimics MRI controller or medical IoT device using Conpot
PORTS = [80, 445, 104, 502] 


# Kock Logic: 
# Passive Simulation - Just a regular TCP handshacke instead of sending an exploit or a "real attack"
# Error Handling - "connect_ex" method, in theory returns a 0 if port is open and error code otherwise.
# even if port is closed, the "attempt" itself creates a network event that winlogbeat or filebeat will capture and send to the "Brain" via TLS-Encrypted beats

def knock_port(ip, port): # I know that im not using IPs, original code had hardcoded IPs in mind and I decided to just keep the name to avoid confucion
    try:
        # Create a socket object
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s: # This socket solution was recommended as a "professional polish" to my original code
            s.settimeout(2) # Times out after the set time, this is important
            # Attempt to connect to simulate a "knock"
            # By using connect_ex the script will just try to archive a TCP handshake, 
            # this, in theory is enough to trigger a log entry in filebeat or Winlogbeat with out performing a malicious exploit
            result = s.connect_ex((ip, port))
            if result == 0:
                print(f"[SUCCESS] Port {port} is open on {ip}")
            else:
                print(f"[KNOCK] Sent request to {ip}:{port} (No direct response expected)")
    except Exception as e:
        print(f"[ERROR] Could not connect to {ip}:{port}: {e}")

# main() functipn will iterate through every asset and every port
# Trafic Generation: it systematically "knocks" on every door in the Clinical Zone
# Dashboard Verification: The script concludes by prompting the user to check Kibana if the "Brain" shows these connection attempts in its logs,
# we would have successfully validated the honeypot's visibility without violating AWS policies against active penetration testing. 
def main():
    print("--- Starting Hospital Honeypot Validation Script ---")
    print("Goal: Generate traffic to verify ELK stack logging \n")

    for name, host in TARGETS.items():
        print(f"Testing {name} ({host})...")
        for port in PORTS:
            knock_port(host, port)
    
    print("\n--- Validation Packets Sent ---")
    print("Next Step: Check the Kibana dashboard for updated logs.")

if __name__ == "__main__":
    main()