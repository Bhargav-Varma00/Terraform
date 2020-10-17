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

#RDS Subnet Group
resource "aws_db_subnet_group" "db-subnet" {
  name       = "rds_db subnet group"
  subnet_ids = ["${aws_subnet.main-private-1c.id}", "${aws_subnet.main-private-1a.id}"]
}

#RDS IN 2 Private Subnets
resource "aws_db_instance" "default" {
  allocated_storage     = 20
  max_allocated_storage = 100
  identifier            = "magentoinstance"
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.m4.large"
  name                  = "test"
  username              = "admin"
  password              = "admin1234"
  parameter_group_name  = "default.mysql5.7"
  db_subnet_group_name  = "${aws_db_subnet_group.db-subnet.name}"
}

#Creating Snapshot of RDS Instance
resource "aws_db_snapshot" "test" {
  db_instance_identifier = "${aws_db_instance.default.id}"
  db_snapshot_identifier = "testsnapshot1234"
}

#Security Groups
resource "aws_security_group" "allow-ssh" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "allow-ssh"
  description = "security groups for allowing ssh and traffic"
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow-ssh"
  }
}

#Elastic Cache Subnet Group
resource "aws_elasticache_subnet_group" "elastic-subnet" {
  name       = "elastic-subnet-group"
  subnet_ids = ["${aws_subnet.main-private-1c.id}", "${aws_subnet.main-private-1a.id}"]
}

#AWS Elastic Cache
resource "aws_elasticache_cluster" "cached" {
  cluster_id           = "cached"
  engine               = "memcached"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 2
  parameter_group_name = "memcached1.4"
  port                 = 11211
}

