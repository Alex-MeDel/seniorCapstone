# ==========================================
# HOSPITAL HONEYPOT AUTOMATED DEPLOYMENT
# Description: Infrastructure as Code (IaC) blueprint to automatically provision 
# a segmented hospital network, decoy servers, and security groups.
# Compliance: Strict outbound traffic blocking to adhere to AWS Acceptable Use Policy.
# ==========================================

# ==========================================
# AI Disclosure & Methodology Statement:
# This project utilized Google Gemini and Claude AI as research and brainstorming
# assistants. Specifically, AI was used to assist with HCL (HashiCorp Configuration
# Language) syntax, PowerShell compatibility for legacy Windows environments, and
# the initial structuring of the ELK containerization.
# To ensure academic integrity and technical accuracy, all AI-generated code
# snippets were manually reviewed, cross-referenced with official AWS and HashiCorp
# documentation, and locally tested for functionality. All conceptual networking
# designs and the honeypot strategy are original work. Specific code sections heavily
# influenced by AI are marked with internal comments citing the model used. AI was 
# also used for the purpose of debugging during test deployments, and for code
# and comment polishing after the successful deployment.
# ==========================================

# This tells Terraform to build the infrastructure in the region set in the variables.tf file
# in this case, us-east-1 (N.Virginia) given that it was the default region for our location
provider "aws" {
    region = var.aws_region
}