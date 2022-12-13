variable "mysql-honeypod-desired_count" {
  default = "1"
}

resource "aws_ecs_task_definition" "mysql-honeypotd-service-def" {
  container_definitions = jsonencode(
    [
      {
        cpu   = 0
        image = "${aws_ecr_repository.mysql-honeypotd-repo.repository_url}:${var.mysql_honeypotd_image_tag}"
        environment = [
        ]
        logConfiguration = {
          logDriver = "awsfirelens"
          options = {
          }
          secretOptions = []
        }
        name = "mysql-honeypotd-service"
        portMappings = [
          {
            containerPort = 27017
            hostPort      = 27017
            protocol      = "tcp"
          }
        ]
        essential = true
      },
      {
        name      = "log-router"
        image     = "${aws_ecr_repository.log-router-repo.repository_url}:latest"
        essential = true
        firelensConfiguration = {
          type = "fluentbit"
          options = {
            config-file-type  = "file"
            config-file-value = "/log_destinations.conf"
          }
        }
        environment = [
          {
            name  = "S3_BUCKET"
            value = aws_s3_bucket.log-bucket.bucket
          },
          {
            name  = "LOG_SOURCE"
            value = "mysql-honeypotd"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = aws_cloudwatch_log_group.firelens-log.name
            awslogs-region        = var.region
            awslogs-stream-prefix = "firelens-mysql-honeypotd-sidecar"
          }
        }
      }
    ]
  )
  family                   = "mysql-honeypotd-service"
  execution_role_arn       = aws_iam_role.task-execution-role.arn
  task_role_arn            = aws_iam_role.ecs-service-role.arn
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "mysql-honeypotd-service" {
  name            = "mysql-honeypotd-service"
  cluster         = aws_ecs_cluster.honeypot-cluster.name
  task_definition = aws_ecs_task_definition.mysql-honeypotd-service-def.arn

  launch_type         = "FARGATE"
  platform_version    = "LATEST"
  propagate_tags      = "NONE"
  scheduling_strategy = "REPLICA"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = var.mysql-honeypod-desired_count
  enable_ecs_managed_tags            = true
  enable_execute_command             = false
  health_check_grace_period_seconds  = 0

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  network_configuration {
    assign_public_ip = true
    security_groups = [
      aws_security_group.allow-mysql.id,
      aws_security_group.allow-ping.id
    ]
    subnets = [
      aws_subnet.subnet-public-1a.id,
      aws_subnet.subnet-public-1c.id,
      aws_subnet.subnet-public-1d.id
    ]
  }
}
