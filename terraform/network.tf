resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "honey-net"
  }
}

resource "aws_flow_log" "vpc-flow-log" {
  log_destination      = aws_s3_bucket.log-bucket.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
}

# Subnet
resource "aws_subnet" "subnet-public-1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"

  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "honey-net-public-1a"
  }
}

resource "aws_subnet" "subnet-public-1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"

  cidr_block = "192.168.2.0/24"

  tags = {
    Name = "honey-net-public-1c"
  }
}

resource "aws_subnet" "subnet-public-1d" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1d"

  cidr_block = "192.168.3.0/24"

  tags = {
    Name = "honey-net-public-1d"
  }
}

# Internet Gateway
# Global to Public subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "honey-net"
  }
}


# Route Table
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "honey-net"
  }
}

# Route
resource "aws_route" "route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public-rtb.id
  gateway_id             = aws_internet_gateway.igw.id
}

# Association
resource "aws_route_table_association" "associate-public-1a" {
  subnet_id      = aws_subnet.subnet-public-1a.id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table_association" "associate-public-1c" {
  subnet_id      = aws_subnet.subnet-public-1c.id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table_association" "associate-public-1d" {
  subnet_id      = aws_subnet.subnet-public-1d.id
  route_table_id = aws_route_table.public-rtb.id
}


# Security Group
resource "aws_security_group" "allow-ping" {
  name   = "allow-ping"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow-ssh" {
  name   = "allow-ssh"
  vpc_id = aws_vpc.main.id
}


resource "aws_security_group_rule" "allow-wellknown-ssh" {
  type      = "ingress"
  from_port = 22
  to_port   = 23
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id = aws_security_group.allow-ssh.id
}

resource "aws_security_group_rule" "allow-other-ssh" {
  type      = "ingress"
  from_port = 2222
  to_port   = 2223
  protocol  = "tcp"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id = aws_security_group.allow-ssh.id
}


resource "aws_security_group" "allow-mysql" {
  name   = "allow-mysql"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
