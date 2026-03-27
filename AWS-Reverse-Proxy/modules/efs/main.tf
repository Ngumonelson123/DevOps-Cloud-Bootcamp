# ============================================================
#  MODULE: EFS
#  Creates: EFS filesystem, mount targets (one per AZ), access point
# ============================================================

resource "aws_efs_file_system" "main" {
  creation_token   = "${var.project_name}-efs"
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = { Name = "${var.project_name}-efs" }
}

# Mount targets – one in each data subnet AZ
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_data_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_data_subnet_ids[count.index]
  security_groups = [var.data_sg_id]
}

# Access point (used by webservers to mount EFS)
resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/wordpress"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "755"
    }
  }

  tags = { Name = "${var.project_name}-efs-wordpress-ap" }
}

resource "aws_efs_access_point" "tooling" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/tooling"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "755"
    }
  }

  tags = { Name = "${var.project_name}-efs-tooling-ap" }
}
