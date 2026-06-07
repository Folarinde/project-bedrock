# ─────────────────────────────────────────
# VPC
# ─────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true   # required for EKS
  enable_dns_support   = true   # required for EKS

  tags = {
    Name = var.vpc_name
  }
}

# ─────────────────────────────────────────
# Internet Gateway
# Allows public subnets to reach the internet
# ─────────────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# ─────────────────────────────────────────
# Public Subnets (one per AZ)
# Used by: ALB, NAT Gateway
# ─────────────────────────────────────────
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true  # instances here get public IPs

  tags = {
    Name = "${var.vpc_name}-public-${var.availability_zones[count.index]}"

    # Required tag for AWS Load Balancer Controller to discover public subnets
    "kubernetes.io/role/elb" = "1"

    # Tags the subnet as belonging to your EKS cluster
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ─────────────────────────────────────────
# Private Subnets (one per AZ)
# Used by: EKS Nodes, RDS, Lambda
# ─────────────────────────────────────────
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.vpc_name}-private-${var.availability_zones[count.index]}"

    # Required tag for AWS Load Balancer Controller to discover private subnets
    "kubernetes.io/role/internal-elb" = "1"

    # Tags the subnet as belonging to your EKS cluster
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# ─────────────────────────────────────────
# Elastic IP for NAT Gateway
# ─────────────────────────────────────────
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# ─────────────────────────────────────────
# NAT Gateway
# Sits in public subnet, allows private
# subnets to reach the internet (outbound only)
# e.g. EKS nodes pulling container images
# ─────────────────────────────────────────
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # NAT Gateway goes in first public subnet

  tags = {
    Name = "${var.vpc_name}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

# ─────────────────────────────────────────
# Public Route Table
# Sends all outbound traffic to Internet Gateway
# ─────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────
# Private Route Table
# Sends all outbound traffic to NAT Gateway
# ─────────────────────────────────────────
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.vpc_name}-private-rt"
  }
}

# Associate each private subnet with the private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}