# ==========================================
# OUTPUTS: Infrastructure Endpoints & Metadata
# Description: Displays crucial connection strings and dynamically 
# fetched AMI IDs immediately after a successful 'terraform apply'.
# ==========================================

# The public IPv4 address for "The Brain" (Management Server)
output "brain_public_ip" {
  value       = aws_instance.the_brain.public_ip
  description = "SSH: ssh -i ~/.ssh/honeypot_key ubuntu@<this IP>"
}
# Direct URL to the Kibana Dashboard
output "elk_kibana_url" {
  value       = "http://${aws_instance.the_brain.public_ip}:5601"
  description = "Kibana dashboard (available ~5min after apply!!, give it time.)"
}

# Debugging/Verification: Displays the dynamically selected Ubuntu AMI
output "ubuntu_ami_used" {
  value = data.aws_ami.ubuntu.id
  description = "The specific Ubuntu AMI ID provisioned for Linux instances"
}

# Debugging/Verification: Displays the dynamically selected Windows Server 2016 AMI
output "windows_ami_used" {
  value = data.aws_ami.windows_2016.id # WIN 2016 Server fix (Swapped the win 2012 due to problems with AMI and End of Life systems)
  description = "The specific Windows Server 2016 AMI provisioned for the Medical Workstation"
}

# OLD CODE, REMOVE LATER!!
#output "windows_ami_used" {
#  value = data.aws_ami.windows_2012.id
#}