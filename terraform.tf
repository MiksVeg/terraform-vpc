resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "custom_vpc"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"
  tags = {
    Name = "public_subnet"
  }
}
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "private_subnet"
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
  tags = {
    Name = "public_route_table"
  }
}
resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet.id
}
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "private_route_table"
  }
}
resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet.id
}
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.vpc.id
}
resource "aws_eip" "eip" {}
resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.public_subnet.id
  allocation_id = aws_eip.eip.id
}
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "allow_sg"
  }
}
resource "aws_security_group_rule" "ingress_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_all.id
}
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_all.id
}
resource "aws_instance" "public_instance" {
  ami                    = "ami-0ea3c35c5c3284d82"
  subnet_id              = aws_subnet.public_subnet.id
  availability_zone      = "us-east-2a"
  instance_type          = "t2.micro"
  key_name               = "ohio2"
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  tags = {
    Name = "frontend-server"
  }
}
resource "aws_instance" "private_instance" {
  ami               = "ami-0ea3c35c5c3284d82"
  subnet_id         = aws_subnet.private_subnet.id
  availability_zone = "us-east-2b"
  instance_type     = "t2.micro"
  key_name          = "ohio2"
  user_data              = file("apache2.sh")
  root_block_device {
    volume_size = 10
  }
  depends_on = [ aws_nat_gateway.nat, aws_route_table_association.private ]
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  tags = {
    Name = "Backend-server"
  }
}
