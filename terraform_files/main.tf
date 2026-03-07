
# Goal of this, is to redeploy the entire hospital environment automatically if an instance crashes or needs to be reset
# Hybrid Architecture (Containers + VMs) + VPC, Subnets, Security Groups, compute resources, etc.
# Full Disclosure, I used Google, Google Gemini and claude AI to aid in the creation of this file, specially around networking and security, as well as code revisions and PowerShell, 
# its roll has been key to overcome the learning curve of containerization and HashiCorp Language, given that this is my first time using Terraform, it is mostly used to learn
# the use of AI generated code has only been used as a last resource and will be properly cited. 

# TO DO LIST: 
# 5. Solution for how to deploy the docker-compose YAML within AWS would be to store the docker-compose file in an S3 bucket and have user_data pull it down with aws s3 cp. 



# Deploy sequence should be: (Check README.md for more information on deployment sequence)
# 1. ssh-keygen -t rsa -b 4096 -f ~/.ssh/honeypot_key
# 2. terraform init
# 3. terraform plan
# 4. terraform apply
# 5. Wait ~5min for user_data to finish then SSH into brain and run `docker ps` to confirm ELK is up
# THEN
# 1. Make changes to main.tf to restrict internet access
# 2. Run Validation Script from "The Brain" instance, can maybe put it in an S3 bucket
# 3. Check if Kibana lights up

# ==========================================
# HOSPITAL HONEYPOT AUTOMATED DEPLOYMENT
# This script acts as a sort of blueprint, when run, AWS will automatically build 
# the entire hospital network, servers, and security rules, as defined
# Compliance: Strict outbound blocking to adhere to AWS Terms of Service 
# ==========================================


# This tells Terraform to build the infrastructure in the region us-east-1 (I thought it was most comvinient)
provider "aws" {
    region = var.aws_region
}