# VPC
resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "wordpress-vpc"
  }
}

# Subnets

resource "aws_subnet" "pub-subnet" {
  vpc_id                  = aws_vpc.default.id
  count                   = length(var.pub-subnet)
  cidr_block              = var.pub-subnet[count.index]["cidr_block"]
  availability_zone       = var.pub-subnet[count.index]["availability_zone"]
  map_public_ip_on_launch = true

  tags = {
    Name = var.pub-subnet[count.index]["name"]
  }
}

resource "aws_subnet" "pri-subnet" {
  vpc_id            = aws_vpc.default.id
  count             = length(var.pri-subnet)
  cidr_block        = var.pri-subnet[count.index]["cidr_block"]
  availability_zone = var.pub-subnet[count.index]["availability_zone"]

  tags = {
    Name = var.pri-subnet[count.index]["name"]
  }
}

#  Internet Gateway for Public Subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "topcon-wp-igw"
  }
}

# NAT Gateway for Private Subnets
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id     = aws_eip.nat.id
  subnet_id         = aws_subnet.pub-subnet[0].id # Must reside on a public subnet
  connectivity_type = "public"
  depends_on        = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-gateway"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "public-rta" {
  count          = length(var.pub-subnet)
  subnet_id      = aws_subnet.pub-subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-rta" {
  count          = length(var.pri-subnet)
  subnet_id      = aws_subnet.pri-subnet[count.index].id
  route_table_id = aws_route_table.private.id
}
