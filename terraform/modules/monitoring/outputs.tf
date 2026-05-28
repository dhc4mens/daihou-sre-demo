output "alarm_arns" {
  description = "作成されたCloudWatch Alarm ARNマップ"
  value = {
    api_gateway_5xx_errors           = aws_cloudwatch_metric_alarm.api_gateway_5xx_errors.arn
    api_gateway_high_latency         = aws_cloudwatch_metric_alarm.api_gateway_high_latency.arn
    cloudfront_high_error_rate       = aws_cloudwatch_metric_alarm.cloudfront_high_error_rate.arn
    cloudfront_high_latency          = aws_cloudwatch_metric_alarm.cloudfront_high_latency.arn
    dynamodb_read_throttle           = aws_cloudwatch_metric_alarm.dynamodb_read_throttle.arn
    dynamodb_write_throttle          = aws_cloudwatch_metric_alarm.dynamodb_write_throttle.arn
    dynamodb_system_errors           = aws_cloudwatch_metric_alarm.dynamodb_system_errors.arn
    lambda_contact_handler_errors    = aws_cloudwatch_metric_alarm.lambda_contact_handler_errors.arn
    lambda_contact_handler_throttles = aws_cloudwatch_metric_alarm.lambda_contact_handler_throttles.arn
    waf_high_block_rate              = aws_cloudwatch_metric_alarm.waf_high_block_rate.arn
    ses_bounce_rate_high             = aws_cloudwatch_metric_alarm.ses_bounce_rate_high.arn
    ses_complaint_rate_high          = aws_cloudwatch_metric_alarm.ses_complaint_rate_high.arn
    ses_send_count_high              = aws_cloudwatch_metric_alarm.ses_send_count_high.arn
  }
}

output "ecs_alarm_arns" {
  description = "ECS Fargate アラーム ARN（ecs_cluster_name 未設定時は空）"
  value = {
    cpu_high       = local.ecs_enabled ? aws_cloudwatch_metric_alarm.ecs_cpu_high[0].arn : ""
    memory_high    = local.ecs_enabled ? aws_cloudwatch_metric_alarm.ecs_memory_high[0].arn : ""
    task_count_low = local.ecs_enabled ? aws_cloudwatch_metric_alarm.ecs_task_count_low[0].arn : ""
  }
}
