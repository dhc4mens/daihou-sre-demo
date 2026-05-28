output "alb_arn" {
  description = "ALB の ARN"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ALB の ARN サフィックス（CloudWatch メトリクス用）"
  value       = aws_lb.main.arn_suffix
}

output "alb_dns_name" {
  description = "ALB の DNS 名（Route 53 エイリアスレコードに使用）"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB のホストゾーン ID（Route 53 エイリアスレコードに使用）"
  value       = aws_lb.main.zone_id
}

output "alb_name" {
  description = "ALB の名前"
  value       = aws_lb.main.name
}

output "http_listener_arn" {
  description = "HTTP (80) リスナーの ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS (443) リスナーの ARN（サービス側で aws_lb_listener_rule を追加）"
  value       = aws_lb_listener.https.arn
}

output "alb_security_group_id" {
  description = "ALB に割り当てたセキュリティグループ ID（ECS タスク SG の ingress 許可に使用）"
  value       = aws_security_group.alb.id
}
