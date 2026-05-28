variable "project_name" {
  description = "プロジェクト名。全リソースのプレフィックスに使用（例: daihou-gbp）"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "project_name は小文字英数字とハイフンのみ。先頭は英字。"
  }
}

variable "availability_zone" {
  description = "シングルAZ構成で使用するAZ"
  type        = string
  default     = "ap-northeast-1a"
}

variable "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet の CIDR"
  type        = string
  default     = "10.10.0.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet の CIDR"
  type        = string
  default     = "10.10.1.0/24"
}

variable "enable_nat_gateway" {
  description = "NAT Gateway を作成するか。false の場合 Private subnet からの outbound は不可（月$32削減）"
  type        = bool
  default     = true
}

variable "create_default_task_sg" {
  description = "汎用の ECS Task 用 SG（outbound only）をモジュール内で作成するか"
  type        = bool
  default     = true
}

variable "extra_tags" {
  description = "全リソースに追加するタグ。module 呼び出し側で default_tags があればそちらで吸収するのが基本"
  type        = map(string)
  default     = {}
}
