resource "aws_ecs_task_definition" "mysql-honeypotd-service-def" {
  container_definitions = jsonencode(
    [
      {
        cpu   = 0
        image = "${aws_ecr_repository.mysql-honeypotd-repo.repository_url}:${var.mysql_honeypotd_image_tag}"
        environment = [
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = aws_cloudwatch_log_group.honeypot-log-mysql-honeypotd.name
            awslogs-region        = "ap-northeast-1"
            awslogs-stream-prefix = "mysql-honeypotd"
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
      },
    ]
  )
  family                   = "mysql-honeypotd-service"
  execution_role_arn       = "arn:aws:iam::${var.account_id}:role/ecsTaskExecutionRole"
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
  desired_count                      = 1
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
