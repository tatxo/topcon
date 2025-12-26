resource "aws_sns_topic" "alerts" {
  name = "ecs-wordpress-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_mail
}

resource "aws_cloudwatch_log_group" "wordpress-logs" {
  name              = "/ecs/wordpress"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "mysql-logs" {
  name              = "/ecs/mysql"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_metric_filter" "wordpress-error-filter" {
  name           = "WordPressErrorCount"
  pattern        = "%error|Error%"
  log_group_name = aws_cloudwatch_log_group.wordpress-logs.name

  metric_transformation {
    name      = "WordPressErrorMetric"
    namespace = "LogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "service-error" {
  alarm_name          = "wordpress-error-notification"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "WordPressErrorMetric"
  namespace           = "LogMetrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_event_rule" "ecs-events" {
  name        = "wordpress-ecs-events"
  description = "Alert for ECS taks stops"
  depends_on  = [aws_cloudwatch_metric_alarm.service-error, aws_cloudwatch_log_metric_filter.wordpress-error-filter] # Workaround concurrent creation error
  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Taks State Change"]
    detail = {
      lastStatus = ["STOPPED"]
      clusterArn = [aws_ecs_cluster.wordpress.arn]
      stoppedReason = [{
        "anything-but": "Scaling activity initiated by (deployment)"
      }]
    }
  })
}

resource "aws_cloudwatch_event_target" "send-to-sns" {
  rule      = aws_cloudwatch_event_rule.ecs-events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alerts.arn
}
