# This is just the AMI IDs and the region made variables for a cleaner code
# reference later with ~"var.brain_ami" etc
variable "aws_region" {
  default = "us-east-1"
}

# OLD hardcoded AMI IDs
variable "brain_ami" {
#  default = "ami-0c7217cdde317cfec" - Old, hardcoded AMI IDs
   default = data.aws_ami.ubuntu.id
}

variable "win_ami" {
#  default = "ami-032599769356f916d"
   default = data.aws_ami.windows_2012.id
}