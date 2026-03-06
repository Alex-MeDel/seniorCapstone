# In theory this should print the Brain's public IP automatically so I dont have to dig through AWS console
output "brain_public_ip" {
  value       = aws_instance.the_brain.public_ip
  description = "SSH: ssh -i ~/.ssh/honeypot_key ubuntu@<this IP>"
}
# This will in theory tell me when the ELK stack starts
output "elk_kibana_url" {
  value       = "http://${aws_instance.the_brain.public_ip}:5601"
  description = "Kibana dashboard (available ~5min after apply)"
}
# This is mainly for debugging, it will verify which AMIs were actually seleced after each apply, since they are not hardcoded anymore

output "ubuntu_ami_used" {
  value = data.aws_ami.ubuntu.id
}

output "windows_ami_used" {
  value = data.aws_ami.windows_2012.id
}