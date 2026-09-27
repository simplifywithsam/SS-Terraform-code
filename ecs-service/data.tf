# Look up the resources that already exist so this service plugs into them.

data "aws_ecs_cluster" "this" {
  cluster_name = var.cluster_name
}

data "aws_lb" "this" {
  name = var.alb_name
}

data "aws_lb_listener" "this" {
  load_balancer_arn = data.aws_lb.this.arn
  port              = var.alb_listener_port
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
