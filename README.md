# Terraform AWS ECS Service Module

This module creates an ECS service and task definition, designed to work with the ECS cluster module.

## Features

- Creates an ECS service
- Creates a task definition with optional container definitions
- Configures service auto-scaling
- Sets up IAM roles for task execution and tasks
- Supports load balancer integration
- Standardized tagging system

## Usage

```hcl
module "ecs_service" {
  source  = "your-org/aws-ecs-service/terraform"
  version = "0.1.0"

  tag_org          = "company"
  env              = "dev"
  service_name     = "api"
  cluster_id       = module.ecs_cluster_asg.cluster_id
  
  # Task configuration
  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/api:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 0
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/api"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  
  # Service configuration
  desired_count = 2
  
  # Load balancer integration
  load_balancer = {
    target_group_arn = module.alb.target_group_arn
    container_name   = "api"
    container_port   = 8080
  }
  
  # Networking
  vpc_id             = module.vpc.id
  security_group_ids = [module.vpc.vpc_default_sg_id]
  subnet_ids         = module.vpc.private_subnet_ids
  
  # Auto-scaling
  enable_autoscaling = true
  scaling_min_capacity = 1
  scaling_max_capacity = 10
  
  tags = {
    Project     = "my-project"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tag_org | Organization tag | `string` | n/a | yes |
| env | Environment (dev, staging, prod) | `string` | n/a | yes |
| service_name | Name of the ECS service | `string` | n/a | yes |
| cluster_id | ID of the ECS cluster | `string` | n/a | yes |
| container_definitions | JSON string of container definitions | `string` | n/a | yes |
| task_cpu | CPU units for task | `number` | `256` | no |
| task_memory | Memory for task in MiB | `number` | `512` | no |
| desired_count | Desired count of tasks | `number` | `1` | no |
| deployment_maximum_percent | Maximum task percentage during deployment | `number` | `200` | no |
| deployment_minimum_healthy_percent | Minimum healthy task percentage during deployment | `number` | `100` | no |
| health_check_grace_period_seconds | Health check grace period | `number` | `60` | no |
| load_balancer | Load balancer configuration | `object` | `null` | no |
| vpc_id | VPC ID | `string` | n/a | yes |
| security_group_ids | Security group IDs for the service | `list(string)` | `[]` | no |
| subnet_ids | Subnet IDs where the service will be placed | `list(string)` | n/a | yes |
| enable_autoscaling | Whether to enable auto scaling | `bool` | `false` | no |
| scaling_min_capacity | Minimum capacity for auto scaling | `number` | `1` | no |
| scaling_max_capacity | Maximum capacity for auto scaling | `number` | `5` | no |
| scaling_cpu_target | Target CPU utilization for auto scaling | `number` | `60` | no |
| scaling_memory_target | Target Memory utilization for auto scaling | `number` | `60` | no |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_id | The ECS service ID |
| service_name | The ECS service name |
| service_arn | The ECS service ARN |
| task_definition_arn | The ARN of the task definition |
| task_execution_role_arn | The ARN of the task execution role |
| task_role_arn | The ARN of the task role |
| security_group_id | The security group ID for the ECS service |

## Cloudflare Integration

To use Cloudflare for DNS records pointing to your service, you can use the Cloudflare provider in your root module:

```hcl
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "service" {
  zone_id = var.cloudflare_zone_id
  name    = var.service_name
  value   = module.alb.dns_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}
```