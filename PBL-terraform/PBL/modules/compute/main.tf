# ============================================================
#  modules/compute/main.tf
#  Creates: IAM role + instance profile for EC2,
#           Launch Template with user_data that mounts EFS
# ============================================================

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

# Allow SSM Session Manager (no need to open port 22)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow reading from S3 (e.g. app artifacts)
resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Instance Profile binds the role to EC2
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Launch Template
resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
    delete_on_termination       = true
  }

  # EBS root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  # User data: install httpd, mount EFS, write test page
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y amazon-efs-utils httpd

    # Start and enable Apache
    systemctl enable httpd
    systemctl start httpd

    # Mount EFS
    mkdir -p /mnt/efs
    mount -t efs -o tls ${var.efs_dns_name}:/ /mnt/efs || true

    # Persist mount across reboots
    echo "${var.efs_dns_name}:/ /mnt/efs efs defaults,_netdev,tls 0 0" >> /etc/fstab

    # Simple health check page
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
      <head><title>PBL App</title></head>
      <body>
        <h1>&#9989; PBL Terraform Deployment</h1>
        <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
        <p><strong>AZ:</strong> $AZ</p>
        <p><strong>Environment:</strong> ${var.environment}</p>
      </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.environment}-app-instance" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.environment}-app-volume" })
  }

  lifecycle {
    create_before_destroy = true
  }
}
