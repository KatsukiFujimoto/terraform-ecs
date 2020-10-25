# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr[var.env]
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.env}-${var.project}-vpc" }
}

# Subnet
resource "aws_subnet" "public_a" {
  depends_on              = [aws_vpc.vpc]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_cidr["${var.env}_public_a"]
  availability_zone       = var.az["az_a"]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.env}-${var.project}-public-a-subnet" }
}

resource "aws_subnet" "public_c" {
  depends_on              = [aws_vpc.vpc]
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_cidr["${var.env}_public_c"]
  availability_zone       = var.az["az_c"]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.env}-${var.project}-public-c-subnet" }
}

resource "aws_subnet" "private_a" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr["${var.env}_private_a"]
  availability_zone = var.az["az_a"]
  tags              = { Name = "${var.env}-${var.project}-private-a-subnet" }
}

resource "aws_subnet" "private_c" {
  depends_on        = [aws_vpc.vpc]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr["${var.env}_private_c"]
  availability_zone = var.az["az_c"]
  tags              = { Name = "${var.env}-${var.project}-private-c-subnet" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  depends_on = [aws_vpc.vpc]
  vpc_id     = aws_vpc.vpc.id
  tags       = { Name = "${var.env}-${var.project}-igw" }
}

# Route Table
resource "aws_route_table" "public" {
  depends_on = [aws_vpc.vpc, aws_internet_gateway.igw]
  vpc_id     = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.env}-${var.project}-public-rtb" }
}

# いらないかも
resource "aws_route_table" "private" {
  depends_on = [aws_vpc.vpc, aws_internet_gateway.igw]
  vpc_id     = aws_vpc.vpc.id
  tags       = { Name = "${var.env}-${var.project}-private-rtb" }
}

resource "aws_route_table_association" "public_a" {
  depends_on     = [aws_subnet.public_a, aws_route_table.public]
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# いらないかも
resource "aws_route_table_association" "private_a" {
  depends_on     = [aws_subnet.private_a, aws_route_table.private]
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# いらないかも
resource "aws_route_table_association" "private_c" {
  depends_on     = [aws_subnet.private_c, aws_route_table.private]
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}
