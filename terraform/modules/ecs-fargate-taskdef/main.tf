# ================================================================
# ECS Fargate 用の1サービス分のリソース一式
# - ECR Repository（オプション）
# - CloudWatch Log Group
# - Task Role（アプリ側の AWS 権限）
# - Task Definition（Fargate 前提）
# ================================================================

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

locals {
  base_tags = merge(
    {
      Component = "compute"
      Service   = var.service_name
    },
    var.client_tag != null ? { Client = var.client_tag } : {},
    var.data_classification != null ? { DataClassification = var.data_classification } : {},
    var.extra_tags,
  )

  log_group_name = "/ecs/${var.service_name}"

  ecr_repository_url = var.create_ecr_repository ? aws_ecr_repository.this[0].repository_url : var.ecr_repository_url

  # container_definitions に awslogs の logConfiguration を自動注入
  container_definitions_with_logs = [
    for c in var.container_definitions : merge(c, var.auto_inject_log_config && !contains(keys(c), "logConfiguration") ? {
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = local.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    } : {})
  ]
}

# ----------------------------------------------------------------
# ECR Repository（オプション）
# ----------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  count                = var.create_ecr_repository ? 1 : 0
  name                 = var.service_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.base_tags, {
    Name = var.service_name
  })
}

resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.create_ecr_repository ? 1 : 0
  repository = aws_ecr_repository.this[0].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.ecr_keep_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_keep_image_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ----------------------------------------------------------------
# CloudWatch Log Group
# ----------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(local.base_tags, {
    Name      = "${var.service_name}-logs"
    Component = "monitoring"
  })
}

# ----------------------------------------------------------------
# Task Role（アプリから AWS リソースへアクセスする用）
# ----------------------------------------------------------------

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task" {
  name               = "${var.project_name}-${var.service_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = merge(local.base_tags, {
    Name      = "${var.project_name}-${var.service_name}-task"
    Component = "iam"
  })
}

resource "aws_iam_role_policy" "task_inline" {
  for_each = var.task_role_policies
  name     = each.key
  role     = aws_iam_role.task.id
  policy   = each.value
}

# ----------------------------------------------------------------
# Task Definition
# ----------------------------------------------------------------

resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    cpu_architecture        = var.cpu_architecture
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode(local.container_definitions_with_logs)

  tags = merge(local.base_tags, {
    Name = var.service_name
  })
}
