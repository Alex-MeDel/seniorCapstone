(README.md Generated entirely by Claude AI and inspected for errors)
# 🏥 Hospital Honeypot — Senior Capstone Project

A cloud-based honeypot environment that simulates a vulnerable hospital network to observe, capture, and analyze simulated cyberattack patterns targeting healthcare infrastructure.

---

## 📌 Project Overview

This project deploys a realistic, isolated hospital network on AWS that intentionally exposes legacy medical systems as decoys. All traffic is captured and forwarded to a centralized logging stack for analysis. The goal is to study attack behaviors targeting healthcare-specific protocols and systems, such as DICOM imaging servers, Modbus IoT gateways, and legacy Windows workstations.

> ⚠️ **Disclaimer:** This environment is strictly isolated within an AWS VPC with no outbound internet access. It is designed for academic research only and is fully compliant with AWS Terms of Service. No real patient data is used.

---

## 🏗️ Architecture

The environment is divided into two network zones within a private AWS VPC (`10.0.0.0/16`):

### 🧠 The Brain Zone (`10.0.2.0/24`)
The secure management server running the ELK Stack for log collection, processing, and visualization.

| Component     | Role                                                   |
|---------------|--------------------------------------------------------|
| Elasticsearch | Stores and indexes all captured log data               |
| Logstash      | Ingests and transforms incoming Beats log streams      |
| Kibana        | Web dashboard for real-time log visualization          |

> Hosted on a `t3.large` EC2 instance (Ubuntu 22.04). All three services run as Docker containers via `docker-compose`.

### 🏥 Clinical Zone (`10.0.1.0/24`)
Simulated legacy medical assets acting as honeypot decoys.

| Asset                     | Hostname                          | Simulates                              | Key Ports     |
|---------------------------|-----------------------------------|----------------------------------------|---------------|
| Medical Workstation       | `medical-workstation.hospital.internal` | Legacy Windows 7 / 2012 terminal  | 445 (SMB)     |
| Imaging Server (PACS)     | `pacs.hospital.internal`          | DICOM-based radiology system           | 104 (DICOM)   |
| IoT Gateway (Conpot)      | `iot-gateway.hospital.internal`   | Medical IoT / MRI controller           | 502 (Modbus), 80 (HTTP) |

---

## 📁 Repository Structure

```
.
├── main.tf                  # Terraform — AWS infrastructure (VPC, subnets, EC2, Route 53)
├── docker-compose.yml       # ELK Stack deployment for "The Brain"
├── validationScript.py      # Connectivity validation and traffic generation script
└── logstash/
    └── pipeline/
        └── logstash.conf    # Logstash pipeline config (Beats → Elasticsearch)
```

---

## 🚀 Deployment

### Prerequisites

- [Terraform](https://www.terraform.io/) installed
- [Docker](https://www.docker.com/) & Docker Compose installed on the Brain instance
- AWS CLI configured with appropriate IAM permissions
- AWS Client VPN configured for Kibana access

### Step 1 — Provision Infrastructure

```bash
terraform init
terraform apply
```

This will create:
- A VPC with Clinical and Brain subnets
- Security groups with strict inter-zone and outbound rules
- EC2 instances for all four nodes
- A Route 53 private hosted zone (`hospital.internal`)

### Step 2 — Deploy the ELK Stack

SSH into the Brain instance (`10.0.2.10`) and run:

```bash
# Required: increase virtual memory for Elasticsearch
sudo sysctl -w vm.max_map_count=262144

# Start all ELK containers
docker-compose up -d
```

Kibana will be accessible at `http://10.0.2.10:5601` via the AWS Client VPN.

### Step 3 — Configure Logstash Pipeline

Create `./logstash/pipeline/logstash.conf` on the Brain instance:

```conf
input {
  beats { port => 5044 }
}
output {
  elasticsearch { hosts => ["elasticsearch:9200"] }
}
```

### Step 4 — Install Log Shippers on Clinical Assets

- **Windows Workstation:** Install and configure [Winlogbeat](https://www.elastic.co/beats/winlogbeat) to forward to `10.0.2.10:5044`
- **Ubuntu Nodes (PACS, IoT Gateway):** Install and configure [Filebeat](https://www.elastic.co/beats/filebeat) to forward to `10.0.2.10:5044`

---

## ✅ Validation

Run the validation script **from the Brain instance** to generate synthetic traffic across all Clinical Zone assets and confirm the ELK stack is capturing events:

```bash
python3 validationScript.py
```

The script performs passive TCP "knocks" on all honeypot nodes across ports 80, 104, 445, and 502. These connection attempts are captured by Filebeat/Winlogbeat and forwarded to the Brain.

After running, open Kibana and verify that log entries are appearing for the Clinical Zone hosts.

---

## 🔒 Security & Compliance

| Control                        | Implementation                                      |
|-------------------------------|------------------------------------------------------|
| Network isolation              | All assets are in a private VPC with no IGW attached |
| Outbound internet blocked      | Security group egress rules block all external traffic |
| No active exploits used        | Validation uses passive TCP handshakes only           |
| Elasticsearch security         | `xpack.security.enabled=false` for dev; enable TLS for production |
| AWS ToS compliance             | No active penetration testing performed              |

---

## ⚠️ Known Limitations & TODOs

- [ ] AMI IDs and AWS region (`us-east-1`) are hardcoded — no `terraform.tfvars` or variable definitions yet
- [ ] Windows 7 AMI availability on AWS is limited; currently using Windows Server 2012 as a substitute
- [ ] Elasticsearch security (`xpack`) is disabled for development — must be enabled with TLS before any production-like use

---

## 🛠️ Tech Stack

- **Cloud:** AWS (EC2, VPC, Route 53, Security Groups)
- **Infrastructure as Code:** Terraform
- **Logging:** ELK Stack (Elasticsearch 8.10.2, Logstash 8.10.2, Kibana 8.10.2)
- **Log Shippers:** Filebeat, Winlogbeat
- **Honeypot Simulation:** Conpot (IoT/Modbus), DCM4CHE (DICOM/PACS)
- **Containerization:** Docker, Docker Compose
- **Scripting:** Python 3

---

## 📚 Acknowledgments

Google and Google Gemini were used to assist in the creation of several configuration files in this project, particularly around CIDR block calculations, ELK Stack tuning, and Docker Compose configuration. All AI-assisted content has been reviewed and adapted for this specific use case.

---

*Senior Capstone Project — Cybersecurity*
