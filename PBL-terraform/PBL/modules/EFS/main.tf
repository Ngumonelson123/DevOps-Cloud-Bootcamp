# ============================================================
#  modules/EFS/main.tf
#  Creates: EFS File System, Mount Targets per subnet,
#           EFS Access Point for the app
# ============================================================

resource "aws_efs_file_system" "main" {
  creation_token   = "${var.environment}-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, { Name = "${var.environment}-efs" })
}

# Mount Targets — one per private subnet for multi-AZ access
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

# Access Point — scoped to /app directory
resource "aws_efs_access_point" "app" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/app"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = merge(var.tags, { Name = "${var.environment}-efs-access-point" })
}
