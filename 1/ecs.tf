# ECS cluster
resource "aws_ecs_cluster" "wordpress" {
  name = var.ecs_cluster_name
}

# MySQL service
resource "aws_ecs_service" "mysql_service" {
  name                = "mysql-service"
  cluster             = aws_ecs_cluster.wordpress.id
  task_definition     = aws_ecs_task_definition.mysql.arn
  scheduling_strategy = "REPLICA"
  desired_count       = 1
  launch_type         = "FARGATE"
  depends_on          = [aws_iam_role.ecs-task-role]

  network_configuration {
    subnets          = aws_subnet.pri-subnet.*.id
    security_groups  = [aws_security_group.mysql-sg.id]
    assign_public_ip = false
  }
}

#WordPress service
resource "aws_ecs_service" "wordpress" {
  name                 = "wordpress-service"
  cluster              = aws_ecs_cluster.wordpress.id
  task_definition      = aws_ecs_task_definition.wordpress.arn
  desired_count        = 1
  force_new_deployment = true
  launch_type          = "FARGATE"
  depends_on           = [aws_iam_role.ecs-task-role]

  network_configuration {
    subnets          = [aws_subnet.pub-subnet[0].id, aws_subnet.pub-subnet[1].id]
    security_groups  = [aws_security_group.wordpress-sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress-tg.arn
    container_name   = "wordpress"
    container_port   = 80
  }
}

resource "aws_ecs_task_definition" "mysql" {
  family                   = "mysql-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs-task-role.arn

  volume {
    name = "mysql-storage"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.mysql-efs.id
      transit_encryption = "ENABLED"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "mysql"
      image     = "mysql:5.7"
      essential = true
      environment = [
        { name = "MYSQL_ROOT_PASSWORD", value = var.db_password },
        { name = "MYSQL_DATABASE", value = var.db_name },
        { name = "MYSQL_USER", value = var.db_user },
        { name = "MYSQL_PASSWORD", value = var.db_password }
      ]
      portMappings = [
        {
          containerPort = 3306
          protocol      = "tcp"
          hostPort      = 3306
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.mysql-logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "mysql"
        }
      }
    },
  ])
}

resource "aws_ecs_task_definition" "wordpress" {
  :w
  family                   = "wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs-task-role.arn
  #    task_role_arn            = aws_iam_role.ecs-task-role.arn
  volume {
    name = "wp-storage"
    efs_volume_configuration {
      file_system_id        = aws_efs_file_systen.wp-efs.id
      transit_encryption    = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.wp-ap.id
        iam             = "ENABLED"
      }
    }
  }
  container_definitions = jsonencode([
    {
      name     = "wordpress"
      image    = "wordpress:latest"
      esential = true
      environment = [
        { name = "DB_HOST", value = "mysql:3306" },
        { name = "DB_USER", value = var.wp_user },
        { name = "DB_PASSWORD", value = var.wp_password },
        { name = "DB_NAME", value = var.db_name }
      ]
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          hostPort      = 80
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wordpress-logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "wordpress"
        }
      }
    }
  ])
}


resource "aws_security_group" "wordpress-sg" {
  vpc_id = aws_vpc.default.id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    #    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb-sg.id]
  }

  ingress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

  tags = {
    Name = "wordpress-sg"
  }
}

resource "aws_security_group" "mysql-sg" {
  name        = "mysql-sg"
  description = "Access to the RDS instances from the VPC"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress-sg.id]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-sg"
  }
}
