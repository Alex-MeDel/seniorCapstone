# ==========================================
# STEP 3: COMPUTE RESOURCES (The Virtual Servers)
# These are the actual computers that will run our hospital software
# ==========================================

# In this terraform file, Google Gemini helped me polish up the code (remove unecessary lines I made and better ways to do things) as well as aided me with a solution for YAML indentation
# AI also helped me with the creation of the PowerShell script given I that I dont know any Windows administration, it is entirely AI generated and checked for errors with testing

# The Brain (Ubuntu 22.04 + ELK Docker) 
# A powerful server used to run the ELK stack for data visualization
# t3.large is important due to resourse consuption of the ELK Stack surpasing what a t3.medium can provide
resource "aws_instance" "the_brain" {
    ami                    = data.aws_ami.ubuntu.id # This is set in the data.tf, dynamic AMI IDs fix
    instance_type          = "t3.large" # Instance type from AWS 
    subnet_id              = aws_subnet.brain_zone.id # Subnets created in vpc.tf
    vpc_security_group_ids = [aws_security_group.brain_sg.id] # This is from security_groups.tf
    private_ip             = "10.0.2.10" # Just sets static IP for this particular device
    key_name               = aws_key_pair.honeypot_key.key_name  # This is part of SSH config
    associate_public_ip_address = true   # This line will give the brain access to a public IP address for bootstraping
#    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name # Part of S3 fix (Had to change due to learners lab)
    iam_instance_profile = "LabInstanceProfile"
    tags                   = { Name = "The-Brain-ELK" }

    # CONFIGURE EVERYTHING ON STARTUP!!!
    # Also creates and RUNS the Docker-Compose File - Cant do due to having multiple heredocs (bash and terraform would likely break the YAML formating and break everything) - heredoc inception no good
    # Proposed solution: An S3 bucket in Terraform to store the file 
    # Will try to do Docker-Compose YAML here first and if it fails will do S3 bucket solution
    # Used AI to try to fix text alignment issues in heredocs before they happen, hoping for best
    user_data = templatefile("${path.module}/scripts/brain_bootstrap.sh", {
      bucket_name = aws_s3_bucket.bootstrap.id
    })
}

# Medical Workstation (Windows 7 or 2012 Legacy) - Still deciding
# Simulates an old Windows computer used by nurses or doctors
resource "aws_instance" "win_workstation" {
#    ami                    = data.aws_ami.windows_2012.id # Windows Server 2012, set in data.tf, dynamic AMI IDs
    ami                    = data.aws_ami.windows_2016.id # <-- Win Server 2016 AMI ID problem fix
    instance_type          = "t3.medium"
    subnet_id              = aws_subnet.clinical_zone.id 
    vpc_security_group_ids = [aws_security_group.clinical_sg.id] 
    key_name               = aws_key_pair.honeypot_key.key_name  # This is part of SSH config
    # IMPORTANT!!!! Once the initial terraform apply finishes and there is Kibana verification and comment out this FIX to remove internet access
    associate_public_ip_address = true   # <-- THE FIX for internet while bootstraping 
#    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name # Part of S3 fix
    iam_instance_profile = "LabInstanceProfile"
    tags                   = { Name = "Win-Clinical-Workstation" } 

    # This part attempts to automate the Windows 2012 Legacy Server Instance 
    # I dont know any PowerShell, so this is 100% AI generated code(Gemeni AI), NEEDS REVISION!!!!
    user_data = <<-EOF
        <powershell>
        $bucket = "${aws_s3_bucket.bootstrap.id}"
        $dest   = "C:\windows_bootstrap.ps1"

        # Force TLS 1.2 for AWS S3 compatibility (Absolutely necesary or 403)
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Download and silently install the AWS CLI
        Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\AWSCLIV2.msi"
        Start-Process msiexec.exe -Wait -ArgumentList '/i C:\AWSCLIV2.msi /qn'
        
        # Use the AWS CLI to download the bootstrap script. 
        # This automatically signs the request using your LabInstanceProfile!
        & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" s3 cp s3://$bucket/windows_bootstrap.ps1 $dest
        
        # Execute the downloaded script
        PowerShell.exe -ExecutionPolicy Bypass -File $dest
        </powershell>
        EOF
}

# Imaging Server (Ubuntu + DICOM Sim) 
# Mimics a PACS system used to store X-rays and MRI scans
resource "aws_instance" "imaging_server" {
    ami                    = data.aws_ami.ubuntu.id # This is set in the data.tf, dynamic AMI IDs fix
    instance_type          = "t3.micro"
    subnet_id              = aws_subnet.clinical_zone.id
    vpc_security_group_ids = [aws_security_group.clinical_sg.id]
    private_ip             = "10.0.1.20"
    key_name               = aws_key_pair.honeypot_key.key_name  # This is part of SSH config
    associate_public_ip_address = true   # <-- THE FIX for internet while bootstraping 
    iam_instance_profile = "LabInstanceProfile"
#    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name # Part of S3 fix
    tags                   = { Name = "Imaging-Server-PACS" }

    # AUTOMATE EVERYTHING!!! 
    user_data = file("${path.module}/scripts/imaging_bootstrap.sh")
}

# IoT Gateway (Ubuntu + Conpot Docker)
# A specialized tool (Conpot) that pretends to be a medical device
resource "aws_instance" "iot_gateway" {
    ami                    = data.aws_ami.ubuntu.id # This is set in the data.tf, dynamic AMI IDs fix
    instance_type          = "t3.micro"
    subnet_id              = aws_subnet.clinical_zone.id
    vpc_security_group_ids = [aws_security_group.clinical_sg.id]
    private_ip             = "10.0.1.30"
    key_name               = aws_key_pair.honeypot_key.key_name  # This is part of SSH config
    associate_public_ip_address = true   # <-- THE FIX for internet while bootstraping 
#    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name # Part of S3 fix
    iam_instance_profile = "LabInstanceProfile"
    tags                   = { Name = "IoT-Gateway-Conpot" }

    # AUTOMATE EVERYTHING!!! 
    # This will install docker and run conpot to mimic medical equipment, will also install and configure filebeat
    user_data = file("${path.module}/scripts/iot_bootstrap.sh")
}
