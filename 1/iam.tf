data "aws_iam_policy_document" "ec2-node-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs-combined-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs-node-role" {
  name               = "wp-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-combined-assume-role.json
}

#resource "aws_iam_role" "ecs-exec-role" {
#    name = "ecsTaskExecutionRole"
#    assume_role_policy = data.aws_iam_policy_document.ecs-combined-assume-role.json
#}

resource "aws_iam_role" "ecs-task-role" {
  name               = "wp-ec2-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-combined-assume-role.json
}

resource "aws_iam_role_policy_attachment" "ecs-node-standard" {
  role       = aws_iam_role.ecs-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs-node-ssm" {
  role       = aws_iam_role.ecs-node-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_instance_profile" "ecs-node-profile" {
  name = "wp-ecs-node-profile"
  role = aws_iam_role.ecs-node-role.name
}
