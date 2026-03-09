# ==========================================
# DATA SOURCES: Dynamic AMI Retrieval
# Description: Queries the AWS API to dynamically fetch the latest 
# official Amazon Machine Images (AMIs) for the honeypot instances.
# This prevents the use of hardcoded, deprecated OS versions.
# ==========================================

# This is to get rid of hardcoded AMI IDs, this just retreives the latests AMI IDs from each OS
# Claude AI Helped me with this section, it gave me the AWS account IDs, and explained the filtering process

# ------------------------------------------
# LINUX AMI: Ubuntu 22.04 LTS (Jammy Jellyfish)
# ------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ------------------------------------------
# WINDOWS AMI: Windows Server 2016 Base
# ------------------------------------------
# ARCHITECTURE NOTE: The original design scoped Windows 7, then Windows Server 2012 R2. 
# Due to AWS End of Life (EOL) restrictions preventing new 2012 deployments, 
# the architecture was successfully pivoted to Server 2016 to maintain 
# the legacy vulnerability scope (SMBv1/v2) while allowing provisioning.
# This was an inebitable change if we wanted to avoid creating an AMI from scratch
data "aws_ami" "windows_2016" {
  most_recent = true
  owners      = ["801119661308"] # Amazon's official Windows AMI account ID

  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# OLD CODE, DELETE LATER!!! 
# WIN Server 2012 END OF LIFE caused errors in initial terraform plan, will switch to Win Server 2016 to avoid having to create a custum AMI ID 
# Dynamically fetch latest Windows Server 2012 R2 AMI from Amazon
#data "aws_ami" "windows_2012" {
#  most_recent = true
#  owners      = ["801119661308"] # Amazon's official Windows AMI account ID
#
#  filter {
#    name   = "name"
#    values = ["Windows_Server-2012-R2_RTM-English-64Bit-Base-*"]
#  }
#
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#}
