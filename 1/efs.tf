resource "aws_efs_file_system" "wp-efs" {
  creation_token  = "wordpress-data"
  encrypted       = true
  
  tags = {
    Name = "WordPress-EFS"
  }
}

resource "aws_efs_file_system" "mysql-efs" {
  creation_token  = "mysql-data"
  encrypted       = true

  tags = {
    Name = "MySQL-EFS"
  }
}

# EFS security group
resource "aws_security_group" "efs-sg" {
  name          = "allow_efs_from_ecs"
  vpc_id        =  aws_vpc.default.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.wordpress-sg.id, aws_security_group.mysql-sg.id]
  }
}

# EFS mount points
resource "aws_efs_mount_target" "wp-mount" {
  count           = length(var.pub-subnet) 
  file_system_id  = aws_efs_file_system.wp-efs.id
  subnet_id       = aws_subnet.pub-subnet[count.index].id
  security_groups = [aws_security_group.efs-sg.id]
}

resource "aws_efs_mount_target" "mysql-mount" {
  count           = length(var.pri-subnet)
  file_system_id  = aws_efs_file_system.mysql-efs.id
  subnet_id       = aws_subnet.pri-subnet[count.index].id
  security_groups = [aws_security_group.efs-sg.id]
}

# Storage access point (WordPress)
resource "aws_efs_access_point" "wp-ap" {
  file_system_id    = aws_efs_file_system.wp-efs.id

  posix_user {
    gid = 33
    uid = 33
  }

  root_directory {
    path = "/wp-content"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "755"
    }
  }
}
# Storage access point (MySQL)
resource "aws_efs_access_point" "mysql-ap" {
  file_system_id = aws_efs_file_system.mysql-efs.id

  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/mysql"
    creation_info {
      owner_gid = 999
      owner_uid = 999
      permissions = "755"
    }
  }
}
