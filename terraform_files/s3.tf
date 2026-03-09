# ==========================================
# S3 BOOTSTRAP STORAGE
# Description: Provisions a temporary, randomized S3 bucket to store 
# configuration scripts, bypassing EC2 user_data size limits and 
# formatting constraints.
# ==========================================

# Claude AI helped me understand the HCL syntax for this section, it was used for research 
# Google Gemini AI helped me Polish comments and code after successfull deployment

# This block creates the storage container in the cloud to hold scripts, this is the solution
# to the "heredoc chorizo" I had going on in instance.tf before, much cleaner, more professional
resource "aws_s3_bucket" "bootstrap" { # bootstrap is the nickname I chose for the s3 bucket
  bucket        = "hospital-honeypot-bootstrap-${random_id.bucket_suffix.hex}" # Must have random numbers to be unique
  force_destroy = true # important!, without this the terraform destroy would not be as effective and AWS will give out errors each deployment
  tags          = { Name = "honeypot-bootstrap-scripts" } # this is for billing according to Claude AI
}

# Creates "randomness" for block above
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ------------------------------------------
# S3 OBJECT UPLOADS (Scripts & Configurations)
# ------------------------------------------
resource "aws_s3_object" "brain_script" {
  bucket = aws_s3_bucket.bootstrap.id # Where to put file
  key    = "brain_bootstrap.sh" # file name inside the s3 bucket
  source = "${path.module}/scripts/brain_bootstrap.sh" # where is file in local computer
  etag   = filemd5("${path.module}/scripts/brain_bootstrap.sh") # This was a Claude AI recommendation, it calculates math hash (MD5) of lcal file
  # if you open script and change a single line and save, the hash changes, and when terraform apply is ran, it comparates hashes, realizes changes and uploads new version
}

resource "aws_s3_object" "docker_compose" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "docker-compose.yml"
  source = "${path.module}/scripts/docker-compose.yml"
  etag   = filemd5("${path.module}/scripts/docker-compose.yml")
}

resource "aws_s3_object" "imaging_script" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "imaging_bootstrap.sh"
  source = "${path.module}/scripts/imaging_bootstrap.sh"
  etag   = filemd5("${path.module}/scripts/imaging_bootstrap.sh")
}

resource "aws_s3_object" "iot_script" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "iot_bootstrap.sh"
  source = "${path.module}/scripts/iot_bootstrap.sh"
  etag   = filemd5("${path.module}/scripts/iot_bootstrap.sh")
}

resource "aws_s3_object" "windows_script" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "windows_bootstrap.ps1"
  source = "${path.module}/scripts/windows_bootstrap.ps1"
  etag   = filemd5("${path.module}/scripts/windows_bootstrap.ps1")
}

resource "aws_s3_object" "logstash_conf" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "logstash.conf"
  source = "${path.module}/scripts/logstash.conf"
  etag   = filemd5("${path.module}/scripts/logstash.conf")
}

resource "aws_s3_object" "validation_script" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "validationScript.py"
  source = "${path.module}/scripts/validationScript.py"
  etag   = filemd5("${path.module}/scripts/validationScript.py")
}




# ==========================================
# ARCHITECTURE NOTE: IAM Instance Profiles
# ==========================================
# Turns out that with AWS Academy student lab environment they remove access to changing IAM policies (as I was doing)
# This means, that I have to find a workaround
# According to Gemini AI there is a pre-built "God-Mode" Role  almost always named LabIntanceProfile
# I need to addapt the code, first thing is commenting out all this IAM shit
# Verified the LabInstanceProfile thing within the AWS EC2 portal by clicking Launch instance button
# going to advanced details 
# and the dropdown of "IAM instance profile" had it exactly like the AI said
# I'll leave this code here, its untested but should in theory, if there is access to IAM permissions, be a better solution.



# ==============================
# IAM permissions
# EC2 instances need IAM permission to read from the S3 bucket, according to claude AI it will get a 403 error, IAM role attached to instances is needed
# Claude AI generated this code and it was checked by me with HCL and AWS documentation
# ==============================

#resource "aws_iam_role" "ec2_bootstrap_role" {
#  name = "honeypot-ec2-bootstrap-role"
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [{
#      Action    = "sts:AssumeRole"
#      Effect    = "Allow"
#      Principal = { Service = "ec2.amazonaws.com" }
#    }]
#  })
#}

#resource "aws_iam_role_policy" "s3_read" {
#  name = "s3-bootstrap-read"
#  role = aws_iam_role.ec2_bootstrap_role.id

#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [{
#      Effect   = "Allow"
#      Action   = ["s3:GetObject"]
#      Resource = "${aws_s3_bucket.bootstrap.arn}/*"
#    }]
#  })
#}

#resource "aws_iam_instance_profile" "ec2_profile" {
#  name = "honeypot-ec2-profile"
#  role = aws_iam_role.ec2_bootstrap_role.name
#}