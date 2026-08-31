resource "aws_cloudwatch_metric_alarm" "lambda_contact_handler_errors" {
  alarm_name          = "Daihou-Lambda-contact-handler-Errors"
  alarm_description   = "Lambda関数 contact-handler でエラー多発"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "contact-handler"
  }

  alarm_actions = [
    var.sns_topic_arn
  ]

  tags = {
    Name               = "Daihou-Lambda-contact-handler-Errors"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_contact_handler_throttles" {
  alarm_name          = "Daihou-Lambda-contact-handler-Throttles"
  alarm_description   = "Lambda関数 contact-handler でスロットリング発生"
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "contact-handler"
  }

  alarm_actions = [
    var.sns_topic_arn
  ]

  tags = {
    Name               = "Daihou-Lambda-contact-handler-Throttles"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}
