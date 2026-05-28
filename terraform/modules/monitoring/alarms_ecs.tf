# ──────────────────────────────────────────────
# ECS Fargate (Container Insights) アラーム
# ecs_cluster_name が空の場合は全リソースをスキップ
# ──────────────────────────────────────────────

locals {
  ecs_enabled = var.ecs_cluster_name != ""
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count = local.ecs_enabled ? 1 : 0

  alarm_name          = "Daihou-ECS-${var.ecs_cluster_name}-${var.ecs_service_name}-CPUHigh"
  alarm_description   = "ECS Fargate CPU使用率が${var.ecs_cpu_threshold}%を超過"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.ecs_cpu_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = {
    Name               = "Daihou-ECS-${var.ecs_cluster_name}-${var.ecs_service_name}-CPUHigh"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  count = local.ecs_enabled ? 1 : 0

  alarm_name          = "Daihou-ECS-${var.ecs_cluster_name}-${var.ecs_service_name}-MemoryHigh"
  alarm_description   = "ECS Fargate メモリ使用率が${var.ecs_memory_threshold}%を超過"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.ecs_memory_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = {
    Name               = "Daihou-ECS-${var.ecs_cluster_name}-${var.ecs_service_name}-MemoryHigh"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "high"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_task_count_low" {
  count = local.ecs_enabled ? 1 : 0

  alarm_name          = "Daihou-ECS-${var.ecs_cluster_name}-${var.ecs_service_name}-TaskCountLow"
  alarm_description   = "ECS Fargate 稼働タスク数が${var.ecs_min_task_count}を下回った（サービス停止の可能性）"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = var.ecs_min_task_count
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  tags = {
    Name               = "Daihou-ECS-${var.ecs_cluster_name}-${var.ecs_service_name}-TaskCountLow"
    Component          = "monitoring"
    Role               = "cloudwatch-alarm"
    ServiceCriticality = "critical"
  }
}
