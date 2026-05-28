# ================================================================
# VPC + シングルAZ（Public / Private）+ オプションで NAT Gateway
# ================================================================
# 命名・タグ規約は daihou-sre/docs/terraform-conventions.md に準拠
# 必須タグ（Project/Environment/ManagedBy/Owner/Repository/CreatedDate）は
# 呼び出し側 provider の default_tags で注入される前提
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
  component_tag = { Component = "network" }
  base_tags     = merge(local.component_tag, var.extra_tags)
}

# ----------------------------------------------------------------
# VPC + IGW
# ----------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-igw"
  })
}

# ----------------------------------------------------------------
# Subnets（Public / Private・シングルAZ）
# ----------------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-public-${var.availability_zone}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-private-${var.availability_zone}"
    Tier = "private"
  })
}

# ----------------------------------------------------------------
# NAT Gateway（オプション・固定費 約$32/月）
# ----------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public.id

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

# ----------------------------------------------------------------
# Route Tables
# ----------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ----------------------------------------------------------------
# 汎用 ECS Task SG（outbound only）
# 特定サービス向けの SG は呼び出し側で別途作成する想定
# ----------------------------------------------------------------

resource "aws_security_group" "ecs_task" {
  count       = var.create_default_task_sg ? 1 : 0
  name        = "${var.project_name}-ecs-task"
  description = "ECS Task outbound only (generic)"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "All outbound (external sites via NAT, AWS APIs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, {
    Name = "${var.project_name}-ecs-task-sg"
  })
}
