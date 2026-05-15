# modules/terraform-aws-compute/main.tf
# Private Module Registry — EC2 Compute Module

resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_groups
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = var.associate_public_ip

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  user_data = var.user_data

  tags = merge(var.tags, {
    Name = var.instance_name
  })

  lifecycle {
    create_before_destroy = true
  }
}
