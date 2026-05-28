output "task_definition_arn" {
  description = "Task Definition の ARN（改訂込み）"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Task Definition family 名"
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_revision" {
  description = "Task Definition のリビジョン番号"
  value       = aws_ecs_task_definition.this.revision
}

output "task_role_arn" {
  description = "Task Role の ARN"
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Task Role 名"
  value       = aws_iam_role.task.name
}

output "ecr_repository_url" {
  description = "ECR Repository の URL（create_ecr_repository=true で作成した場合、または渡された値）"
  value       = local.ecr_repository_url
}

output "ecr_repository_arn" {
  description = "ECR Repository の ARN（create_ecr_repository=true 時のみ）"
  value       = var.create_ecr_repository ? aws_ecr_repository.this[0].arn : null
}

output "log_group_name" {
  description = "CloudWatch Log Group 名"
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "CloudWatch Log Group の ARN"
  value       = aws_cloudwatch_log_group.this.arn
}
