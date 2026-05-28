output "vpc_id" {
  description = "VPC の ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC の CIDR"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "Public subnet の ID（シングルAZ構成）"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet の ID（シングルAZ構成）"
  value       = aws_subnet.private.id
}

output "public_subnet_ids" {
  description = "Public subnet の ID list（将来のMulti-AZ対応用）"
  value       = [aws_subnet.public.id]
}

output "private_subnet_ids" {
  description = "Private subnet の ID list（将来のMulti-AZ対応用）"
  value       = [aws_subnet.private.id]
}

output "internet_gateway_id" {
  description = "Internet Gateway の ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "NAT Gateway の ID（enable_nat_gateway=false の場合は null）"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "ecs_task_security_group_id" {
  description = "汎用 ECS Task 用 Security Group の ID（create_default_task_sg=false の場合は null）"
  value       = var.create_default_task_sg ? aws_security_group.ecs_task[0].id : null
}

output "availability_zone" {
  description = "使用しているAvailability Zone"
  value       = var.availability_zone
}
