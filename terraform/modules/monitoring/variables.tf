variable "sns_topic_arn" {
  description = "アラート通知先 SNS トピック ARN"
  type        = string
  default     = "arn:aws:sns:ap-northeast-1:182803334083:daihou-website-alerts"
}

# ── ECS Fargate アラーム（空文字の場合はスキップ）──

variable "ecs_cluster_name" {
  description = "監視対象 ECS クラスター名（空文字でアラーム無効）"
  type        = string
  default     = ""
}

variable "ecs_service_name" {
  description = "監視対象 ECS サービス名"
  type        = string
  default     = ""
}

variable "ecs_cpu_threshold" {
  description = "CPU使用率アラームしきい値（%）"
  type        = number
  default     = 80
}

variable "ecs_memory_threshold" {
  description = "メモリ使用率アラームしきい値（%）"
  type        = number
  default     = 80
}

variable "ecs_min_task_count" {
  description = "稼働タスク数の最小値（これを下回るとアラーム）"
  type        = number
  default     = 1
}
