# The Load Balancer
resource "aws_lb" "wordpress-alb" {
  name               = "wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  subnets            = [aws_subnet.pub-subnet[0].id, aws_subnet.pub-subnet[1].id] # Requires at least 2 AZs
}

# Target Group (Where the containers register themselves)
resource "aws_lb_target_group" "wordpress-tg" {
  name        = "wordpress-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"


  health_check {
    path = "/wp-admin/install.php" # Valid path before setup
    # path                = "/"     #WordPress root
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399" # Accept redirects 
  }
}

# Listener (Redirects port 80 to the Target Group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wordpress-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress-tg.arn
  }
}

# Security groups
resource "aws_security_group" "alb-sg" {
  name        = "alb-sg"
  description = "Security Group for the ALB"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "alb-sg"
  }
}
