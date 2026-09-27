locals {
  container_name = var.service_name

  container_environment = [
    for k, v in merge(
      {
        APP_NAME = var.service_name
        APP_ENV  = lookup(var.tags, "ENV", "dev")
        PORT     = tostring(var.container_port)
      },
      var.environment_variables
    ) : { name = k, value = v }
  ]

  # Only add repositoryCredentials when a secret is supplied
  repository_credentials = var.artifactory_credentials_secret_arn != null ? {
    repositoryCredentials = {
      credentialsParameter = var.artifactory_credentials_secret_arn
    }
  } : {}
}

# ---------------------------------------------------------------------------
# Logs
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.cluster_name}/${var.service_name}"
  retention_in_days = var.log_retention_days
}

# ---------------------------------------------------------------------------
# Security group for the tasks: only the ALB may reach the container port
# ---------------------------------------------------------------------------
resource "aws_security_group" "service" {
  name        = "${var.service_name}-tasks-sg"
  description = "ECS Fargate tasks for ${var.service_name}"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.service_name}-tasks-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  for_each = toset(data.aws_lb.this.security_groups)

  security_group_id            = aws_security_group.service.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  description                  = "App traffic from ALB"
}

# Outbound: pull from Artifactory, CloudWatch Logs, Secrets Manager
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.service.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Outbound for image pull, logs and secrets"
}

# The ALB security group must be allowed to send to the tasks. Only needed if
# the ALB SG does not already allow outbound to the VPC; leave off if the
# security-groups workspace manages that SG's egress with inline rules.
resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  for_each = var.manage_alb_egress_rule ? toset(data.aws_lb.this.security_groups) : toset([])

  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.service.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  description                  = "ALB to ${var.service_name} tasks"
}

# ---------------------------------------------------------------------------
# Target group + listener rule on the existing ALB
# ---------------------------------------------------------------------------
resource "aws_lb_target_group" "this" {
  name                 = "${var.service_name}-tg"
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip" # required for Fargate (awsvpc)
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = data.aws_lb_listener.this.arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = var.listener_rule_path_patterns
    }
  }

  dynamic "condition" {
    for_each = length(var.listener_rule_host_headers) > 0 ? [1] : []
    content {
      host_header {
        values = var.listener_rule_host_headers
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Task definition (image pulled from Artifactory)
# ---------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  container_definitions = jsonencode([
    merge(
      {
        name      = local.container_name
        image     = var.container_image
        essential = true

        portMappings = [{
          containerPort = var.container_port
          protocol      = "tcp"
        }]

        environment = local.container_environment

        healthCheck = {
          command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:${var.container_port}${var.health_check_path}', timeout=3)\" || exit 1"]
          interval    = 30
          timeout     = 5
          retries     = 3
          startPeriod = 15
        }

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.this.name
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = var.service_name
          }
        }
      },
      local.repository_credentials
    )
  ])
}

# ---------------------------------------------------------------------------
# ECS Fargate service
# ---------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  name                              = var.service_name
  cluster                           = data.aws_ecs_cluster.this.arn
  task_definition                   = aws_ecs_task_definition.this.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 60
  enable_execute_command            = var.enable_execute_command
  propagate_tags                    = "SERVICE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  # Autoscaling owns desired_count after the first apply
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [
    aws_lb_listener_rule.this,
    aws_iam_role_policy_attachment.execution_managed,
  ]
}

# ---------------------------------------------------------------------------
# Auto scaling on CPU
# ---------------------------------------------------------------------------
resource "aws_appautoscaling_target" "this" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.service_name}-cpu-target"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.this.service_namespace
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = 120
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
