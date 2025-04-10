##############################################
# main.tf
##############################################

# Create IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.tag_org}-${var.env}-${var.service_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-${var.service_name}-task-execution-role"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Attach policies to the ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create IAM role for ECS tasks
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.tag_org}-${var.env}-${var.service_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-${var.service_name}-task-role"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.tag_org}-${var.env}-${var.service_name}-sg"
  description = "Security group for ECS tasks in service ${var.service_name}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-${var.service_name}-sg"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create CloudWatch log group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.tag_org}-${var.env}-${var.service_name}"
  retention_in_days = 30

  tags = merge(
    {
      Name        = "/ecs/${var.tag_org}-${var.env}-${var.service_name}"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create ECS task definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.tag_org}-${var.env}-${var.service_name}"
  container_definitions    = var.container_definitions
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-${var.service_name}-task-definition"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )
}

# Create ECS service
resource "aws_ecs_service" "this" {
  name                               = "${var.tag_org}-${var.env}-${var.service_name}"
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  health_check_grace_period_seconds  = var.load_balancer != null ? var.health_check_grace_period_seconds : null
  force_new_deployment               = true
  
  # Service deployment circuit breaker
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Network configuration
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = concat([aws_security_group.ecs_tasks.id], var.security_group_ids)
    assign_public_ip = false
  }

  # Load balancer configuration
  dynamic "load_balancer" {
    for_each = var.load_balancer != null ? [var.load_balancer] : []
    
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  # Ensure proper ordering on resource creation and deletion
  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  tags = merge(
    {
      Name        = "${var.tag_org}-${var.env}-${var.service_name}-service"
      Environment = var.env
      Organization = var.tag_org
    },
    var.tags
  )

  # Prevent Terraform from trying to manage the service's desired count if autoscaling is enabled
  lifecycle {
    ignore_changes = var.enable_autoscaling ? [desired_count] : []
  }
}

# Create Application Auto Scaling Target if autoscaling is enabled
resource "aws_appautoscaling_target" "this" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.scaling_max_capacity
  min_capacity       = var.scaling_min_capacity
  resource_id        = "service/${basename(var.cluster_id)}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Create CPU-based auto scaling policy
resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.tag_org}-${var.env}-${var.service_name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.scaling_cpu_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Create Memory-based auto scaling policy
resource "aws_appautoscaling_policy" "memory" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.tag_org}-${var.env}-${var.service_name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.scaling_memory_target
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}