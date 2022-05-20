resource "aws_vpc" "decilo" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.region
  }
}

# NETWORKING

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.decilo.id

  tags = {
    Name = "public"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.decilo.id

  tags = {
    Name = "default"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# SUBNETS

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.decilo.id
  cidr_block        = element(var.public_subnet_cidr_blocks, 0)
  availability_zone = element(var.availability_zones, 0)

  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.decilo.id
  cidr_block        = element(var.public_subnet_cidr_blocks, 1)
  availability_zone = element(var.availability_zones, 1)

  tags = {
    Name = "public-2"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
