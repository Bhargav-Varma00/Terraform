resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "main"
  }
}

#Subnets(Az-1)
resource "aws_subnet" "main-public-1c" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1c"
  tags = {
    Name = "main-public-1c"
  }
}

resource "aws_subnet" "main-private-1c" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1c"
  tags = {
    Name = "main-private-1c"
  }
}

#Subnets(Az-2)
resource "aws_subnet" "main-public-1a" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "main-public-1a"
  }
}

resource "aws_subnet" "main-private-1a" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "main-private-1a"
  }
}

#Internet-Gateway
resource "aws_internet_gateway" "main-gw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "main-gw"
  }
}

#Route-Tables
resource "aws_route_table" "route-public" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main-gw.id}"
  }
  tags = {
    Name = "route-public"
  }
}

#Route-Table-Association with 2 Public Subnets In Two AZs
resource "aws_route_table_association" "main-public-1c" {
  subnet_id      = "${aws_subnet.main-public-1c.id}"
  route_table_id = "${aws_route_table.route-public.id}"
}

resource "aws_route_table_association" "main-public-1a" {
  subnet_id      = "${aws_subnet.main-public-1a.id}"
  route_table_id = "${aws_route_table.route-public.id}"
}


#NAT Gateway For AZ-1
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.main-public-1c.id}"
  depends_on    = ["aws_internet_gateway.main-gw"]
}

#VPC setup for NAT
resource "aws_route_table" "main-private" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat-gw.id}"
  }
  tags = {
    Name = "main-private-1"
  }
}

#Route Association Private
resource "aws_route_table_association" "main-private_1" {
  subnet_id      = "${aws_subnet.main-private-1c.id}"
  route_table_id = "${aws_route_table.main-private.id}"
}

#NAT Gateway For AZ-2
resource "aws_eip" "nat1" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw1" {
  allocation_id = "${aws_eip.nat1.id}"
  subnet_id     = "${aws_subnet.main-public-1a.id}"
  depends_on    = ["aws_internet_gateway.main-gw"]
}

#VPC setup for NAT
resource "aws_route_table" "main-private1" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat-gw1.id}"
  }
  tags = {
    Name = "main-private-2"
  }
}

#Route Association Private
resource "aws_route_table_association" "main-private_2" {
  subnet_id      = "${aws_subnet.main-private-1a.id}"
  route_table_id = "${aws_route_table.main-private1.id}"
}
