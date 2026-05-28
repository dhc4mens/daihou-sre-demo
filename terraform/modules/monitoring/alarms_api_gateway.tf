resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx_errors" {
  alarm_name          = "Daihou-APIGateway-prod-5xxErrors"
  alarm_description   = "API Gateway prod で5xxエラー多発"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = "daihou-contact-api"
    Stage   = "prod"
  }

  alarm_actions = [
    "arn:aws:sns:ap-northeast-1:182803334083:daihou-website-alerts"
  ]

  tags = {
    Name               = "Daihou-APIGateway-prod-5xxErrors"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_high_latency" {
  alarm_name          = "Daihou-APIGateway-prod-HighLatency"
  alarm_description   = "API Gateway prod で応答遅延"
  namespace           = "AWS/ApiGateway"
  metric_name         = "Latency"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 2000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = "daihou-contact-api"
    Stage   = "prod"
  }

  alarm_actions = [
    "arn:aws:sns:ap-northeast-1:182803334083:daihou-website-alerts"
  ]

  tags = {
    Name               = "Daihou-APIGateway-prod-HighLatency"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}
