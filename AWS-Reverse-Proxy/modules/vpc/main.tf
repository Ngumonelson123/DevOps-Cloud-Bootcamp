# ============================================================
#  MODULE: VPC
#  Creates: VPC, 6 subnets, IGW, NAT GW, Elastic IPs,
#           route tables + associations
# ============================================================

# ── VPC ──────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

# ── Internet Gateway ─────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# ── Public Subnets (Nginx + Bastion) ─────────────────────────
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-${count.index + 1}" }
}

# ── Private Web Subnets (WordPress + Tooling) ────────────────
resource "aws_subnet" "private_web" {
  count             = length(var.private_web_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_web_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.project_name}-private-web-${count.index + 1}" }
}

# ── Private Data Subnets (RDS + EFS) ─────────────────────────
resource "aws_subnet" "private_data" {
  count             = length(var.private_data_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.project_name}-private-data-${count.index + 1}" }
}

# ── Elastic IP for NAT Gateway ───────────────────────────────
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }

  depends_on = [aws_internet_gateway.igw]
}

# ── NAT Gateway (in first public subnet) ─────────────────────
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = { Name = "${var.project_name}-nat-gw" }

  depends_on = [aws_internet_gateway.igw]
}

# ── Public Route Table ────────────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Private Route Table (uses NAT) ───────────────────────────
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private_web" {
  count          = length(aws_subnet.private_web)
  subnet_id      = aws_subnet.private_web[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_data" {
  count          = length(aws_subnet.private_data)
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private.id
}
