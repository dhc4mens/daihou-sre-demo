resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  alarm_name          = "Daihou-DynamoDB-DaihouContacts-Production-ReadThrottle"
  alarm_description   = "DynamoDB DaihouContacts-Production read throttle events detected"
  namespace           = "AWS/DynamoDB"
  metric_name         = "ReadThrottleEvents"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = "DaihouContacts-Production"
  }

  alarm_actions = [
    var.sns_topic_arn
  ]

  tags = {
    Name               = "Daihou-DynamoDB-DaihouContacts-Production-ReadThrottle"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  alarm_name          = "Daihou-DynamoDB-DaihouContacts-Production-WriteThrottle"
  alarm_description   = "DynamoDB DaihouContacts-Production write throttle events detected"
  namespace           = "AWS/DynamoDB"
  metric_name         = "WriteThrottleEvents"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = "DaihouContacts-Production"
  }

  alarm_actions = [
    var.sns_topic_arn
  ]

  tags = {
    Name               = "Daihou-DynamoDB-DaihouContacts-Production-WriteThrottle"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_system_errors" {
  alarm_name          = "Daihou-DynamoDB-DaihouContacts-Production-SystemErrors"
  alarm_description   = "DynamoDB DaihouContacts-Production system errors"
  namespace           = "AWS/DynamoDB"
  metric_name         = "SystemErrors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = "DaihouContacts-Production"
  }

  alarm_actions = [
    var.sns_topic_arn
  ]

  tags = {
    Name               = "Daihou-DynamoDB-DaihouContacts-Production-SystemErrors"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}
