# ---------------------------------------------------------------------------
# Account / environment
# ---------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region of the existing ECS cluster"
  type        = string
  default     = "us-east-1"
}

variable "assume_role_arn" {
  description = "IAM role HCP Terraform assumes to deploy"
  type        = string
}

variable "environment_name" {
  description = "Environment folder name used by Harness (DEV, UAT, BUAT, PROD)"
  type        = string
  default     = "DEV"

  validation {
    condition     = contains(["DEV", "UAT", "BUAT", "PROD"], var.environment_name)
    error_message = "environment_name must be one of DEV, UAT, BUAT, PROD."
  }
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Existing infrastructure (looked up, not created)
# ---------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the existing ECS cluster (Harness target_cluster)"
  type        = string
}

variable "vpc_id" {
  description = "VPC that hosts the cluster and the ALB"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the Fargate tasks (need a route to ECR, CloudWatch Logs and Secrets Manager)"
  type        = list(string)
}

variable "alb_name" {
  description = "Name of the existing Application Load Balancer"
  type        = string
}

variable "alb_listener_port" {
  description = "Port of the existing ALB listener to attach the service to"
  type        = number
  default     = 443
}

# ---------------------------------------------------------------------------
# Service (must match ecs_task-definition/<ENV>/vars.yaml)
# ---------------------------------------------------------------------------
variable "service_name" {
  description = "ECS service name = vars.yaml serviceName (max 28 chars so derived names fit)"
  type        = string
  default     = "iec-sample-app"

  validation {
    condition     = length(var.service_name) <= 28
    error_message = "service_name must be 28 characters or fewer."
  }
}

variable "container_name" {
  description = "Main container name = vars.yaml containerDefinitions[0].name"
  type        = string
  default     = "iec-sample-app"
}

variable "container_port" {
  description = "Main container port = vars.yaml containerPort"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "Initial number of tasks in the service definition"
  type        = number
  default     = 2
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging into running tasks"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# ECR
# ---------------------------------------------------------------------------
variable "create_ecr_repository" {
  description = "Create the ECR repo here. Set false if it already exists (e.g. created by the self-service)."
  type        = bool
  default     = true
}

variable "ecr_repository_name" {
  description = "ECR repository for the service image (Harness ecr_repository_name)"
  type        = string
  default     = "iec-sample-app"
}

variable "ecr_images_to_keep" {
  description = "How many images the lifecycle policy keeps"
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# Logs (OTEL sidecar pushes the app's log file here)
# ---------------------------------------------------------------------------
variable "otel_log_group_name" {
  description = "CloudWatch log group = vars.yaml CLOUDWATCH_LOG_GROUP_NAME. Defaults to /ecs/<cluster>/<service>."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# Load balancer routing / health check
# ---------------------------------------------------------------------------
variable "listener_rule_priority" {
  description = "Priority of the listener rule (must be unique on the listener)"
  type        = number
  default     = 100
}

variable "listener_rule_path_patterns" {
  description = "Path patterns routed to this service"
  type        = list(string)
  default     = ["/*"]
}

variable "listener_rule_host_headers" {
  description = "Optional host headers routed to this service (empty = any host)"
  type        = list(string)
  default     = []
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health"
}

variable "manage_alb_egress_rule" {
  description = "Add an egress rule on the ALB security group(s) towards the tasks (only if the ALB SG restricts egress)"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Auto scaling (rendered into Harness scaling_target / scaling_policy)
# ---------------------------------------------------------------------------
variable "autoscaling_min_capacity" {
  type    = number
  default = 2
}

variable "autoscaling_max_capacity" {
  type    = number
  default = 4
}

variable "autoscaling_cpu_target" {
  description = "Target average CPU utilisation (%)"
  type        = number
  default     = 70
}
