# ECS cluster
resource "aws_ecs_cluster" "wordpress" {
  name = var.ecs_cluster_name
}

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
  family                   = "wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs-task-role.arn
  #    task_role_arn            = aws_iam_role.ecs-task-role.arn

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
