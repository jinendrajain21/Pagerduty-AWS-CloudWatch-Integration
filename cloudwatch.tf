
resource "aws_sns_topic" "pagerdutysns" {
  name = "Pagerdutysns"
}


/*data "aws_sns_topic" "pagerdutysns" {
  name = "Pagerdutysns"
}*/

resource "aws_sns_topic_subscription" "pagerdutysnsub" {
  topic_arn                       = aws_sns_topic.pagerdutysns.arn
  protocol                        = "https"
  endpoint                        = "https://events.pagerduty.com/integration/${pagerduty_service_integration.cloudwatch.integration_key}/enqueue"
  confirmation_timeout_in_minutes = "3"
  endpoint_auto_confirms          = "true"
}
resource "aws_cloudwatch_metric_alarm" "CPU" {
  alarm_name          = "web-CPU-ec2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "0.05"
  alarm_description   = "monitor the CPU utilazation"
  alarm_actions       = [aws_sns_topic.pagerdutysns.arn]
  dimensions = {
    InstanceId = aws_instance.PagerDuty-instance.id
  }
}
resource "aws_cloudwatch_metric_alarm" "Health" {
  alarm_name          = "web-Health-ec2"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "0.05"
  alarm_description   = "monitor the Health of EC2 utilazation"
  alarm_actions       = [aws_sns_topic.pagerdutysns.arn]
  dimensions = {
    InstanceId = aws_instance.PagerDuty-instance.id
  }

}
