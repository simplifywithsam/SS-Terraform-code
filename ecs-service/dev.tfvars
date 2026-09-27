# TODO: the image reference printed by app/build_and_push.sh
container_image = "<artifactory-host>/<docker-repo>/iec-sample-app:1.0.0"
container_port  = 8080
task_cpu        = 256
task_memory     = 512
desired_count   = 2

# Artifactory pull credentials (Secrets Manager). Set to null for anonymous pulls.
# TODO: replace with your secret ARN
artifactory_credentials_secret_arn  = "arn:aws:secretsmanager:us-east-1:185449614149:secret:iec/artifactory/pull-creds-XXXXXX"
artifactory_credentials_kms_key_arn = null

# ALB routing
alb_listener_port           = 443
listener_rule_priority      = 100
listener_rule_path_patterns = ["/*"]
listener_rule_host_headers  = ["dev.domain.com"]
health_check_path           = "/health"

# Auto scaling
autoscaling_min_capacity = 2
autoscaling_max_capacity = 4
autoscaling_cpu_target   = 70