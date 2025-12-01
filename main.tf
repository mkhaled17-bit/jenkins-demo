provider "aws" {
  region = "us-east-1" # Ensure this matches your AWS region
}

# --- Data Sources to Resolve Subnet Error ---
# 1. Look up the default VPC
data "aws_vpc" "default" {
  default = true
}

# 2. Look up the first available subnet in the default VPC
data "aws_subnet" "public_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  # This finds a subnet in the first Availability Zone (us-east-1a)
  # Change the AZ if this specific one is deleted in your account
  availability_zone = "us-east-1a" 
}
# ---------------------------------------------

# 3. Get the latest Amazon Linux 2 AMI automatically
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 4. Create a Security Group to allow Web (80) and SSH (22) traffic
resource "aws_security_group" "web_sg" {
  name        = "web_server_sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id # Specify VPC ID for SG

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. Create the EC2 Instance with Subnet ID and User Data
resource "aws_instance" "web_server" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_sg.name]
  
  # FIX: Use the subnet ID found by the data source
  subnet_id = data.aws_subnet.public_subnet.id

  # This script installs Apache and sets the HTML page
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
                          
              # Get the Private IP using Instance Metadata Service (IMDS)
              # Note: Changed to the reliable IMDSv2 method for best practice
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

              # Create the HTML file
              echo "<html><body>" > /var/www/html/index.html
              echo "<h1>Created by: Khaled</h1>" >> /var/www/html/index.html
              echo "<p>My Private IP is: $PRIVATE_IP</p>" >> /var/www/html/index.html
              echo "</body></html>" >> /var/www/html/index.html
              EOF

  tags = {
    Name = "Terraform-Jenkins-Demo"
  }
}

# Output the Public IP
output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}