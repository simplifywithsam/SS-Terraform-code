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

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Existing infrastructure (looked up, not created)
# ---------------------------------------------------------------------------
variable "cluster_name" {
  description = "Name of the existing ECS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC that hosts the cluster and the ALB"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the Fargate tasks (need a route to Artifactory, e.g. via NAT or proxy)"
  type        = list(string)
}

variable "alb_name" {
  description = "Name of the existing Application Load Balancer"
  type        = string
}

variable "alb_listener_port" {
  description = "Port of the existing ALB listener to attach the service to (443 for HTTPS)"
  type        = number
  default     = 443
}

# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------
variable "service_name" {
  description = "ECS service / application name (max 28 chars so the target group name fits)"
  type        = string
  default     = "iec-dev-ecs-sample-app"

  validation {
    condition     = length(var.service_name) <= 28
    error_message = "service_name must be 28 characters or fewer."
  }
}

variable "container_image" {
  description = "Full Artifactory image reference, e.g. mycompany.jfrog.io/iec-docker-local/iec-sample-app:1.0.0"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, ...)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64 — must match the image platform"
  type        = string
  default     = "X86_64"
}

variable "desired_count" {
  description = "Initial number of tasks"
  type        = number
  default     = 2
}

variable "environment_variables" {
  description = "Plain environment variables passed to the container"
  type        = map(string)
  default     = {}
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for debugging into running tasks"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention for container logs"
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------------
# Artifactory pull credentials
# ---------------------------------------------------------------------------
variable "artifactory_credentials_secret_arn" {
  description = <<-EOT
    ARN of a Secrets Manager secret holding {"username":"...","password":"..."} for
    pulling from Artifactory. Set to null if the repo allows anonymous pulls.
  EOT
  type        = string
  default     = null
}

variable "artifactory_credentials_kms_key_arn" {
  description = "Customer-managed KMS key that encrypts the Artifactory secret (null if it uses the AWS managed key)"
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Load balancer routing / health check
# ---------------------------------------------------------------------------
variable "listener_rule_priority" {
  description = "Priority of the listener rule on the existing ALB listener (must be unique on that listener)"
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

variable "manage_alb_egress_rule" {
  description = "Add an egress rule on the ALB security group(s) towards the tasks"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health"
}

# ---------------------------------------------------------------------------
# Auto scaling
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
  description = "Target average CPU utilisation (%) for scaling"
  type        = number
  default     = 70
}
