# Generate private key
resource "tls_private_key" "jenkins_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

# Create aws key pair
resource "aws_key_pair" "generated_key" {
    key_name = "new-keypair"
    public_key = tls_private_key.jenkins_key.public_key_openssh
}

# Save private key to file
resource "local_file" "private_key" {
    content = tls_private_key.jenkins_key.private_key_pem
    filename = "new-keypair.pem"
}

# Create VPC
resource "aws_vpc" "devseops_vpc" {
    cidr_block = "10.0.0.0/24"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
      Name = "devsecops-vpc"
    }
}

# Create security group
resource "aws_security_group" "jenkins_sg" {
    vpc_id = aws_vpc.devseops_vpc.id
    name = "jenkins-worker-sg"

    tags = {
      Name = "jenkins-sg"
    }

    # Allow ssh
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow jenkins 8080
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow sonar 9000
    ingress {
        from_port = 9000
        to_port = 9000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

     # Allow http 80
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Outbount
    egress {
        to_port = 0
        from_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

# Public subnet
resource "aws_subnet" "public-subnet" {
    vpc_id = aws_vpc.devseops_vpc.id
    availability_zone = "ap-south-1a"
    cidr_block = "10.0.1.0/24"

    tags = {
      Name = "public-subnet"
    }
}

# Private subnet
resource "aws_subnet" "private-subnet" {
    vpc_id = aws_vpc.devseops_vpc.id
    availability_zone = "ap-south-1b"
    cidr_block = "10.0.2.0/24"

    tags = {
      Name = "private-subnet"
    }
}

# Internet gateway
resource "aws_internet_gateway" "iwg" {
    vpc_id = aws_vpc.devseops_vpc.id
    
    tags = {
      Name = "devsecops-igw"
    }
}

# Route table
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.devseops_vpc.id
    tags = {
      Name = "public-route-table"
    }
}

# Add route
resource "aws_route" "public_internet_access" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.iwg.id
}

# Route table association
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Create elastic ip for NAT gateway
resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
      Name = "devsecops-nat"
    }
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.private-subnet.id

    tags = {
      Name = "devsecops-nat"
    }
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.devseops_vpc.id

    tags = {
      Name = "private-subnet-rt"
    }
}

resource "aws_route" "private_rt" {
    route_table_id = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private_rt.id
}


data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["229704422334"]

    filter {
      name = "name"
      values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
    }

    filter {
      name = "virualization-type"
      values = ["hvm"]
    }
}

# EC2 instance
resource "aws_instance" "server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = "c5a.xlarge"
    vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
    subnet_id = aws_subnet.public-subnet.id
    key_name = aws_key_pair.generated_key.key_name
    user_data = file(("script.sh"))

    tags = {
      Name = "jenkins-server"
    }

    root_block_device {
      volume_size = 25
      volume_type = "gp3"
    }

}