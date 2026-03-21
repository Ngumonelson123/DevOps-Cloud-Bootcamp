provider "aws" {
  region = var.region
}

# -------------------------------------------------------
# SSH KEY PAIR — generated and saved locally automatically
# -------------------------------------------------------
resource "tls_private_key" "project14" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "project14" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.project14.public_key_openssh

  tags = { Name = "${var.project_name}-key" }
}

resource "local_file" "private_key" {
  content         = tls_private_key.project14.private_key_pem
  filename        = "${path.module}/../project14-key.pem"
  file_permission = "0600"
}

# -------------------------------------------------------
# VPC
# -------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags = { Name = "${var.project_name}-public-subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------------------------------------------
# SECURITY GROUPS
# -------------------------------------------------------

# Jenkins — port 8080 (UI) + 22 (SSH)
resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Jenkins server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-jenkins-sg" }
}

# SonarQube — port 9000
resource "aws_security_group" "sonarqube" {
  name        = "${var.project_name}-sonarqube-sg"
  description = "SonarQube server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube UI"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sonarqube-sg" }
}

# Artifactory — ports 8081 (service) + 8082 (UI)
resource "aws_security_group" "artifactory" {
  name        = "${var.project_name}-artifactory-sg"
  description = "Artifactory server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Artifactory service"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Artifactory UI"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-artifactory-sg" }
}

# Nginx — HTTP + HTTPS reverse proxy
resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-nginx-sg"
  description = "Nginx reverse proxy security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-nginx-sg" }
}

# Webservers — Tooling + TODO apps
resource "aws_security_group" "webserver" {
  name        = "${var.project_name}-webserver-sg"
  description = "Webserver (Tooling and TODO) security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-webserver-sg" }
}

# Database — MySQL port only from webservers
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Database server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-db-sg" }
}

resource "aws_security_group_rule" "db_mysql_from_webserver" {
  type                     = "ingress"
  description              = "MySQL from webservers"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.webserver.id
}

# -------------------------------------------------------
# EC2 INSTANCES — CI ENVIRONMENT
# -------------------------------------------------------

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  key_name               = aws_key_pair.project14.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "jenkins-server", Env = "ci", Project = var.project_name }
}

resource "aws_instance" "sonarqube" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.sonarqube.id]
  key_name               = aws_key_pair.project14.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "sonarqube-server", Env = "ci", Project = var.project_name }
}


resource "aws_instance" "nginx_ci" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nginx.id]
  key_name               = aws_key_pair.project14.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = { Name = "nginx-ci-server", Env = "ci", Project = var.project_name }
}

# -------------------------------------------------------
# EC2 INSTANCES — DEV ENVIRONMENT
# -------------------------------------------------------

resource "aws_instance" "tooling" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.webserver.id]
  key_name               = aws_key_pair.project14.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = { Name = "tooling-dev-server", Env = "dev", Project = var.project_name }
}

resource "aws_instance" "todo" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.webserver.id]
  key_name               = aws_key_pair.project14.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = { Name = "todo-dev-server", Env = "dev", Project = var.project_name }
}

resource "aws_instance" "nginx_dev" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nginx.id]
  key_name               = aws_key_pair.project14.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = { Name = "nginx-dev-server", Env = "dev", Project = var.project_name }
}

resource "aws_instance" "db" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = aws_key_pair.project14.key_name

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = { Name = "db-dev-server", Env = "dev", Project = var.project_name }
}

resource "aws_security_group_rule" "db_mysql_from_jenkins" {
  type                     = "ingress"
  description              = "MySQL from Jenkins"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.jenkins.id
}

resource "aws_security_group_rule" "db_mysql_from_vpc" {
  type              = "ingress"
  description       = "MySQL from VPC"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = ["10.0.0.0/16"]
}
