# This is just the AMI IDs and the region made variables for a cleaner code, can add more variables later if needed
# reference later with ~"var.brain_ami" etc
variable "aws_region" {
  default = "us-east-1"
}


# CHANGE, "default =" must point to a litteral value, I just referenced data.aws_ami.ubuntu.id and the windows counterpart directly in the instance.tf
# OLD hardcoded AMI IDs
#variable "brain_ami" {
#  default = "ami-0c7217cdde317cfec" - Old, hardcoded AMI IDs
#   default = data.aws_ami.ubuntu.id
#}

#variable "win_ami" {
#  default = "ami-032599769356f916d"
#   default = data.aws_ami.windows_2012.id
#}