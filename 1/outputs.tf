output "alb_dns" {
  value = aws_lb.wordpress-alb.dns_name
}
