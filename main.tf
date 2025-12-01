provider "aws" {
  region = "us-east-1"
}

# 1. Get the existing Default VPC
data "aws_vpc" "default" {
  default = true
}

# 2. Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 3. CREATE a new Subnet in the Default VPC
resource "aws_subnet" "my_subnet" {
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "192.168.0.0/16" 
  # REMOVED strict availability_zone pinning. 
  # This allows AWS to pick a zone (a, b, c, etc.) that works for the instance type.
  map_public_ip_on_launch = true

  tags = {
    Name = "Jenkins-Demo-Subnet"
  }
}

# 4. Security Group
resource "aws_security_group" "web_sg" {
  name        = "web_server_sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id

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

# 5. EC2 Instance
resource "aws_instance" "web_server" {
  ami             = data.aws_ami.amazon_linux.id
  
  # CHANGE: Switched from t2.micro to t3.micro (Newer Free Tier)
  instance_type   = "t3.micro"
  
  security_groups = [aws_security_group.web_sg.id]
  subnet_id       = aws_subnet.my_subnet.id

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              
              # IMDSv2 method to get Private IP
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
              
              echo "<html><body>" > /var/www/html/index.html
              echo "<h1>Created by: Khaled</h1>" >> /var/www/html/index.html
              echo "<p>My Private IP is: $PRIVATE_IP</p>" >> /var/www/html/index.html
              echo "</body></html>" >> /var/www/html/index.html
              EOF

  tags = {
    Name = "Terraform-Jenkins-Demo"
  }
}

output "website_url" {
  value = "http://${aws_instance.web_server.public_ip}"
}