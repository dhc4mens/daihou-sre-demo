variable "project_name" {
  description = "プロジェクト名。ALB 名・タグのプレフィックスに使用"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "project_name は小文字英数字とハイフンのみ。先頭は英字。"
  }
}

variable "name" {
  description = "ALB 名。未指定時は <project_name>-alb を使用"
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "ALB を配置する VPC の ID（networking モジュールの vpc_id を渡す）"
  type        = string
}

variable "subnet_ids" {
  description = "ALB を配置するパブリックサブネット ID のリスト（2AZ 以上必須）"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "ALB には 2 つ以上のサブネットが必要です。"
  }
}

variable "acm_certificate_arn" {
  description = "HTTPS リスナーに使用する ACM 証明書の ARN"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "ALB へのインバウンドを許可する CIDR ブロックリスト"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssl_policy" {
  description = "HTTPS リスナーの SSL ポリシー"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "enable_deletion_protection" {
  description = "誤削除防止を有効化するか（本番環境では true 推奨）"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "アイドルタイムアウト（秒）"
  type        = number
  default     = 60
}

variable "access_logs_bucket" {
  description = "アクセスログ保存先 S3 バケット名。null の場合はログ無効"
  type        = string
  default     = null
}

variable "access_logs_prefix" {
  description = "アクセスログの S3 プレフィックス"
  type        = string
  default     = "alb"
}

variable "extra_tags" {
  description = "全リソースに追加するタグ"
  type        = map(string)
  default     = {}
}
