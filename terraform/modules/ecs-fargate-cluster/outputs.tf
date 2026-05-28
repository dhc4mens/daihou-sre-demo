output "cluster_id" {
  description = "ECS Cluster の ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "ECS Cluster の ARN"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "ECS Cluster 名"
  value       = aws_ecs_cluster.main.name
}

output "task_execution_role_arn" {
  description = "共有 Task Execution Role の ARN（TaskDef の execution_role_arn に渡す）"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_execution_role_name" {
  description = "共有 Task Execution Role 名"
  value       = aws_iam_role.ecs_task_execution.name
}
