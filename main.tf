provider "aws" {
  region = "us-east-1"
}

# --- 1. Network Resources for 192.168.x.x ---

# Create the new VPC using the 192.168.0.0/16 range
resource "aws_vpc" "custom_vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Jenkins-Demo-VPC"
  }
}

# Create the Internet Gateway (IGW) for public traffic
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.custom_vpc.id
  tags = {
    Name = "Jenkins-Demo-GW"
  }
}

# Create the Route Table to route traffic through the IGW
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.custom_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "Jenkins-Demo-Route"
  }
}

# Create the Subnet using your desired CIDR
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "192.168.0.0/24" # Your desired CIDR
  map_public_ip_on_launch = true # Required for public IP address

  tags = {
    Name = "Jenkins-Demo-Subnet"
  }
}

# Associate the Route Table with the new Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.route_table.id
}

# --- 2. Compute Resources ---

# Get the latest Amazon Linux 2 AMI (data source is reused)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Security Group (must be linked to the new VPC)
resource "aws_security_group" "web_sg" {
  name        = "web_server_sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.custom_vpc.id # Link to the new custom VPC

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

# EC2 Instance
resource "aws_instance" "web_server" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t3.micro"
  security_groups = [aws_security_group.web_sg.id]
  subnet_id       = aws_subnet.my_subnet.id # Link to the new subnet

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
              echo "<h1>Hello from Khaled</h1>" >> /var/www/html/index.html
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