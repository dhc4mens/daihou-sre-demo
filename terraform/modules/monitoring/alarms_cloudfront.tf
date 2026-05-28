resource "aws_cloudwatch_metric_alarm" "cloudfront_high_error_rate" {
  alarm_name          = "Daihou-CloudFront-HighErrorRate"
  alarm_description   = "CloudFront 4xx/5xxエラー率が高い"
  namespace           = "AWS/CloudFront"
  metric_name         = "4xxErrorRate"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 5
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DistributionId = "E32NZ7HF4H9PBZ"
  }

  alarm_actions = [
    "arn:aws:sns:ap-northeast-1:182803334083:daihou-website-alerts"
  ]

  tags = {
    Name               = "Daihou-CloudFront-HighErrorRate"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_high_latency" {
  alarm_name          = "Daihou-CloudFront-HighLatency"
  alarm_description   = "CloudFrontオリジン応答時間が遅い"
  namespace           = "AWS/CloudFront"
  metric_name         = "OriginLatency"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 3000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DistributionId = "E32NZ7HF4H9PBZ"
  }

  alarm_actions = [
    "arn:aws:sns:ap-northeast-1:182803334083:daihou-website-alerts"
  ]

  tags = {
    Name               = "Daihou-CloudFront-HighLatency"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}
