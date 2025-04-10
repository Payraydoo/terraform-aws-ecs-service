variable "tag_org" {
  description = "Organization tag"
  type        = string
}

variable "env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "container_definitions" {
  description = "JSON string of container definitions"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for task in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired count of tasks"
  type        = number
  default     = 1
}

variable "deployment_maximum_percent" {
  description = "Maximum task percentage during deployment"
  type        = number
  default     = 200
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy task percentage during deployment"
  type        = number
  default     = 100
}

variable "health_check_grace_period_seconds" {
  description = "Health check grace period"
  type        = number
  default     = 60
}

variable "load_balancer" {
  description = "Load balancer configuration"
  type = object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  })
  default = null
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs for the service"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet IDs where the service will be placed"
  type        = list(string)
}

variable "enable_autoscaling" {
  description = "Whether to enable auto scaling"
  type        = bool
  default     = false
}

variable "scaling_min_capacity" {
  description = "Minimum capacity for auto scaling"
  type        = number
  default     = 1
}

variable "scaling_max_capacity" {
  description = "Maximum capacity for auto scaling"
  type        = number
  default     = 5
}

variable "scaling_cpu_target" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 60
}

variable "scaling_memory_target" {
  description = "Target Memory utilization for auto scaling"
  type        = number
  default     = 60
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}