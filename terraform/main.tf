provider "aws" { region = "ap-northeast-1" }
provider "null" {}

variable "account_id" {}
variable "region" {
  default = "ap-northeast-1"
}

variable "cowrie_image_tag" {
  default = "latest"
}

variable "mysql_honeypotd_image_tag" {
  default = "latest"
}

resource "aws_ecs_cluster" "honeypot-cluster" {
  name = "honeypot-cluster"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "cluster-capacity" {
  capacity_providers = ["FARGATE"]
  cluster_name       = aws_ecs_cluster.honeypot-cluster.name
}

resource "aws_iam_role_policy" "honeypot-log-policy" {
  name = "allow-s3-put-object-to-honeypot-log-bucket"
  role = aws_iam_role.ecs-service-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.log-bucket.bucket}/*"
      },
    ]
  })
}

resource "aws_iam_role" "ecs-service-role" {
  name = "ecs-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "task-execution-policy" {
  role = aws_iam_role.task-execution-role.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    }
  )
}


resource "aws_iam_role" "task-execution-role" {
  name = "honeypot-ecs-TaskExecution"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
          Effect = "Allow"
          Sid    = ""
        }
      ]
    }
  )
}
