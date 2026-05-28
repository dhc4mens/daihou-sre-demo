variable "project_name" {
  description = "プロジェクト名。ECS Cluster名と IAM Role のプレフィックスに使用"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "project_name は小文字英数字とハイフンのみ。先頭は英字。"
  }
}

variable "cluster_name" {
  description = "ECS Cluster 名。未指定時は project_name を使用"
  type        = string
  default     = null
}

variable "enable_container_insights_enhanced" {
  description = "Container Insights enhanced を有効化するか"
  type        = bool
  default     = true
}

variable "capacity_providers" {
  description = "Cluster で利用可能な capacity provider のリスト"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider" {
  description = "デフォルトの capacity provider"
  type        = string
  default     = "FARGATE"
}

variable "secrets_manager_prefix_arns" {
  description = "Task Execution Role に SecretsManager 読み取り権限を付与する ARN パターン。空リスト時は権限付与しない"
  type        = list(string)
  default     = []
}

variable "extra_tags" {
  description = "全リソースに追加するタグ"
  type        = map(string)
  default     = {}
}
