output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "ecs_cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.main.id
}

output "artifacts_bucket_name" {
  description = "Nome do bucket S3 para artefatos"
  value       = aws_s3_bucket.artifacts.bucket
}

output "ecs_security_group_id" {
  description = "ID do security group para ECS"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "ID do security group para RDS"
  value       = aws_security_group.rds.id
}

output "cloudwatch_log_group_name" {
  description = "Nome do grupo de logs no CloudWatch"
  value       = aws_cloudwatch_log_group.main.name
}

output "nat_gateway_ip" {
  description = "Endereço IP do NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "ecs_task_execution_role_arn" {
  description = "ARN da role de execução de tarefas ECS"
  value       = aws_iam_role.ecs_task_execution_role.arn
}
