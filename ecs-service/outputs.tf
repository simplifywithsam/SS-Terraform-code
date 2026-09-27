output "service_name" {
  value = aws_ecs_service.this.name
}

output "service_id" {
  value = aws_ecs_service.this.id
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "tasks_security_group_id" {
  value = aws_security_group.service.id
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}

output "alb_dns_name" {
  description = "Hit https://<this or your Route53 record>/ to reach the app"
  value       = data.aws_lb.this.dns_name
}
