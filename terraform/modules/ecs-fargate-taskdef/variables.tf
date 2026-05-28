variable "project_name" {
  description = "プロジェクト名。IAM Role プレフィックスに使用（例: daihou-gbp）"
  type        = string
}

variable "service_name" {
  description = "サービス名。ECR リポ・Log Group・TaskDef family に使用（例: takatsuen-csv）"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.service_name))
    error_message = "service_name は小文字英数字とハイフンのみ。先頭は英字。"
  }
}

variable "task_execution_role_arn" {
  description = "ecs-fargate-cluster モジュールの task_execution_role_arn を渡す"
  type        = string
}

variable "cpu" {
  description = "Task の CPU（vCPU 単位 x 1024。例: '1024' = 1 vCPU）"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Task のメモリ（MB）"
  type        = string
  default     = "1024"
}

variable "container_definitions" {
  description = "Task Definition の container definitions（jsonencode 前のオブジェクトリスト）。logConfiguration は自動注入される"
  type        = any
}

variable "cpu_architecture" {
  description = "CPU アーキテクチャ（X86_64 / ARM64）"
  type        = string
  default     = "X86_64"
  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture は X86_64 または ARM64 のみ。"
  }
}

variable "create_ecr_repository" {
  description = "ECR リポジトリをモジュール内で作成するか。false の場合 ecr_repository_url を渡す必要あり"
  type        = bool
  default     = true
}

variable "ecr_repository_url" {
  description = "create_ecr_repository=false 時に使用する既存 ECR の URL"
  type        = string
  default     = null
}

variable "ecr_keep_image_count" {
  description = "ECR で保持するイメージ数"
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch Log Group の保持日数"
  type        = number
  default     = 30
}

variable "task_role_policies" {
  description = "Task Role に付与する inline policy のマップ（name -> jsonencoded policy）"
  type        = map(string)
  default     = {}
}

variable "auto_inject_log_config" {
  description = "container_definitions 各要素に awslogs の logConfiguration を自動注入するか"
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "AWSリージョン。auto_inject_log_config=true のとき使用"
  type        = string
  default     = "ap-northeast-1"
}

variable "client_tag" {
  description = "リソースに付与する Client タグ（マルチテナント時。省略可）"
  type        = string
  default     = null
}

variable "data_classification" {
  description = "リソースに付与する DataClassification タグ（pii 等を含む場合）"
  type        = string
  default     = null
}

variable "extra_tags" {
  description = "全リソースに追加するタグ"
  type        = map(string)
  default     = {}
}
