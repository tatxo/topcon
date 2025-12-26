data "aws_iam_policy_document" "ecs-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs-task-role-custom" {
  name = "wp-efs-and-exec-policy"
  role = aws_iam_role.ecs-task-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permissions for EFS Mounting/Writing
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = aws_efs_file_system.wp-efs.arn
      },
      {
        # Permissions for ECS Exec (seeing container content)
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECS execution role (startup)
resource "aws_iam_role" "ecs-exec-role" {
  name               = "wp-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role.json
}

# ECS task role (application code)
resource "aws_iam_role" "ecs-task-role" {
  name               = "wp-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-assume-role.json
}

resource "aws_iam_role_policy_attachment" "ecs-exec-role-standard" {
  role       = aws_iam_role.ecs-exec-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
