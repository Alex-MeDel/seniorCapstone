# For SSH, this part adds a key pair resource
# KEY STEP: Before!! terraform apply, generate key locally
# ssh-keygen -t rsa -b 4096 -f ~/.ssh/honeypot_key
# Then SSH after deploy
# ssh -i ~/.ssh/honeypot_key ubuntu@10.0.2.10
resource "aws_key_pair" "honeypot_key" {
    key_name   = "honeypot-key"
    public_key = file("~/.ssh/honeypot_key.pub")
}
