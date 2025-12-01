provider "aws" {
  region = "us-east-1" # Change this to your preferred region
}

# 1. Get the latest Amazon Linux 2 AMI automatically
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 2. Create a Security Group to allow Web (80) and SSH (22) traffic
resource "aws_security_group" "web_sg" {
  name        = "web_server_sg"
  description = "Allow HTTP and SSH"

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

# 3. Create the EC2 Instance with User Data
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.name]

  # This script runs once when the instance first boots
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              
              # Get the Private IP using Instance Metadata Service (IMDS)
              PRIVATE_IP=$(hostname -i)
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

# Output the Public IP so you can check the website later
output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}