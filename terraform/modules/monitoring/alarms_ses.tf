resource "aws_cloudwatch_metric_alarm" "ses_bounce_rate_high" {
  alarm_name          = "SES-Bounce-Rate-High"
  namespace           = "AWS/SES"
  metric_name         = "Bounce"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    var.ses_sns_topic_arn
  ]

  tags = {
    Name               = "SES-Bounce-Rate-High"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "medium"
  }
}

resource "aws_cloudwatch_metric_alarm" "ses_complaint_rate_high" {
  alarm_name          = "SES-Complaint-Rate-High"
  namespace           = "AWS/SES"
  metric_name         = "Complaint"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    var.ses_sns_topic_arn
  ]

  tags = {
    Name               = "SES-Complaint-Rate-High"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "medium"
  }
}

resource "aws_cloudwatch_metric_alarm" "ses_send_count_high" {
  alarm_name          = "SES-Send-Count-High"
  namespace           = "AWS/SES"
  metric_name         = "Send"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 50
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    var.ses_sns_topic_arn
  ]

  tags = {
    Name               = "SES-Send-Count-High"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "medium"
  }
}
