# --- Values for ecs_task-definition/<ENV>/vars.yaml -------------------------
output "task_role_arn" {
  description = "vars.yaml taskRoleArn"
  value       = aws_iam_role.task.arn
}

output "execution_role_arn" {
  description = "vars.yaml executionRoleArn"
  value       = aws_iam_role.execution.arn
}

output "otel_log_group_name" {
  description = "vars.yaml CLOUDWATCH_LOG_GROUP_NAME"
  value       = aws_cloudwatch_log_group.otel.name
}

# --- Values for the Harness ECS self-service (Step 3) -----------------------
output "ecr_repository_name" {
  value = var.ecr_repository_name
}

output "ecr_repository_url" {
  value = var.create_ecr_repository ? aws_ecr_repository.this[0].repository_url : "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository_name}"
}

output "target_cluster" {
  value = data.aws_ecs_cluster.this.cluster_name
}

# --- Service definition metadata (Step 5, Harness Filestore) ----------------
output "harness_filestore_path" {
  description = "Where the service definition metadata should land in the Harness Filestore"
  value       = "ecs/service_pvt/servicedef/${var.environment_name}/${local.harness_infra_folder}/"
}

output "ecs_service_definition_yaml" {
  description = "-> servicedef-yaml"
  value       = yamlencode(local.ecs_service_definition)
}

output "ecs_scalable_target_yaml" {
  description = "-> scalling_target/"
  value       = yamlencode(local.ecs_scalable_target)
}

output "ecs_scaling_policy_yaml" {
  description = "-> scalling_policy/"
  value       = yamlencode(local.ecs_scaling_policy)
}

# --- Other ------------------------------------------------------------------
output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "tasks_security_group_id" {
  value = aws_security_group.service.id
}

output "alb_dns_name" {
  value = data.aws_lb.this.dns_name
}
