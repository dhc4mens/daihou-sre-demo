resource "aws_cloudwatch_metric_alarm" "waf_high_block_rate" {
  alarm_name          = "Daihou-WAF-HighBlockRate"
  alarm_description   = "WAFでブロックリクエスト急増（攻撃の可能性）"
  namespace           = "AWS/WAFV2"
  metric_name         = "BlockedRequests"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 100
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    Rule   = "ALL"
    WebACL = "daihou-corporate-web-acl"
    Region = "us-east-1"
  }

  alarm_actions = [
    var.sns_topic_arn
  ]

  tags = {
    Name               = "Daihou-WAF-HighBlockRate"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}
