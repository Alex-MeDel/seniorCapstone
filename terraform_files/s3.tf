# S3 Bucket fix!!!
# OK, this will be the S3 bucket solution to the heredoc chorizo within instances.tf 
# Claude AI helped me with research and code polishing in this section


# ==============================
# S3 Bucket Configuration (Part of the S3 fix to avoid YAML syntax errors within a heredoc chorizo)
# ==============================

resource "aws_s3_bucket" "bootstrap" {
  bucket        = "hospital-honeypot-bootstrap-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags          = { Name = "honeypot-bootstrap-scripts" }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Upload each script
resource "aws_s3_object" "brain_script" {
  bucket = aws_s3_bucket.bootstrap.id
  key    = "brain_bootstrap.sh"
  source = "${path.module}/scripts/brain_bootstrap.sh"
  etag   = filemd5("${path.module}/scripts/brain_bootstrap.sh")
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





# ==============================
# IAM permissions
# EC2 instances need IAM permission to read from the S3 bucket, according to claude AI it will get a 403 error, IAM role attached to instances is needed
# Claude AI generated this code and it was checked by me with HCL and AWS documentation
# ==============================

# A BIG NO NO APPEARED!!! 
# Turns out that with AWS Academy student lab environment they remove access to changing IAM policies (as I was doing)
# This means, that I have to find a workaround
# According to Gemini AI there is a pre-built "God-Mode" Role  almost always named LabIntanceProfile
# I need to addapt the code, first thing is commenting out all this IAM shit
# Verified the LabInstanceProfile thing within the AWS EC2 portal by clicking Launch instance button
# going to advanced details 
# and the dropdown of "IAM instance profile" had it exactly like the AI said


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