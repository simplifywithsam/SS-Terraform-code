# ---------------------------------------------------------------------------
# Task execution role: used by the ECS agent to pull the image from
# Artifactory (via the Secrets Manager secret) and write logs.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "execution" {
  name               = "${var.service_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_pull_secret" {
  count = var.artifactory_credentials_secret_arn != null ? 1 : 0

  statement {
    sid       = "ReadArtifactoryCredentials"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.artifactory_credentials_secret_arn]
  }

  dynamic "statement" {
    for_each = var.artifactory_credentials_kms_key_arn != null ? [1] : []
    content {
      sid       = "DecryptArtifactoryCredentials"
      actions   = ["kms:Decrypt"]
      resources = [var.artifactory_credentials_kms_key_arn]
    }
  }
}

resource "aws_iam_role_policy" "execution_pull_secret" {
  count  = var.artifactory_credentials_secret_arn != null ? 1 : 0
  name   = "artifactory-pull-credentials"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_pull_secret[0].json
}

# ---------------------------------------------------------------------------
# Task role: the identity the Python app itself runs as.
# Attach app permissions (S3, DynamoDB, ...) here when needed.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "task" {
  name               = "${var.service_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
}

data "aws_iam_policy_document" "task_ecs_exec" {
  statement {
    sid = "EcsExec"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task_ecs_exec" {
  count  = var.enable_execute_command ? 1 : 0
  name   = "ecs-exec"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_ecs_exec.json
}
