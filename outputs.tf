output "service_id" {
  description = "The ECS service ID"
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "The ECS service name"
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "The ECS service ARN"
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "task_execution_role_arn" {
  description = "The ARN of the task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_role_arn" {
  description = "The ARN of the task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "security_group_id" {
  description = "The security group ID for the ECS service"
  value       = aws_security_group.ecs_tasks.id
}