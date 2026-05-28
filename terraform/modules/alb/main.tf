# ================================================================
# ALB モジュール（HTTPS 前提・複数サービス対応）
# - internet-facing Application Load Balancer
# - HTTP 80 → HTTPS 443 リダイレクト
# - HTTPS listener のデフォルトアクション: 404 fixed response
# - サービス側で aws_lb_listener_rule を追加してルーティング
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
  name      = coalesce(var.name, "${var.project_name}-alb")
  base_tags = merge({ Component = "network" }, var.extra_tags)
}

# ----------------------------------------------------------------
# Security Group（ALB 用）
# ----------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name}-sg"
  description = "ALB inbound HTTP/HTTPS"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = "${local.name}-sg"
  })
}

# ----------------------------------------------------------------
# ALB
# ----------------------------------------------------------------

resource "aws_lb" "main" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = true

  dynamic "access_logs" {
    for_each = var.access_logs_bucket != null ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.base_tags, {
    Name = local.name
  })
}

# ----------------------------------------------------------------
# HTTP Listener（80 → 443 リダイレクト）
# ----------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ----------------------------------------------------------------
# HTTPS Listener（443）- デフォルト: 404
# サービスごとに aws_lb_listener_rule を追加してルーティング
# ----------------------------------------------------------------

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}
