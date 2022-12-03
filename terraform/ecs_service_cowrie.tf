resource "aws_ecs_task_definition" "cowrie-service-def" {
  container_definitions = jsonencode(
    [
      {
        cpu   = 0
        image = "${aws_ecr_repository.cowrie-repo.repository_url}:${var.cowrie_image_tag}"
        environment = [
          # {
          #   name = "COWRIE_TELNET_ENABLED",
          #   value = "yes"
          # },
          # {
          #   name = "COWRIE_OUTPUT_JSONLOG_ENABLED",
          #   value = "true"
          # },
          # {
          #   name = "cowrie_honeypot_auth_class",
          #   value = "UserDB"
          # },
          # {
          #   name = "COWRIE_SSH_LISTEN_ENDPOINTS",
          #   value = "tcp:22:interface=0.0.0.0"
          # },
          # {
          #   name = "COWRIE_TELNET_LISTEN_ENDPOINTS",
          #   value = "tcp:23:interface=0.0.0.0"
          # }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-create-group  = "true"
            awslogs-group         = aws_cloudwatch_log_group.honeypot-log-cowrie.name
            awslogs-region        = "ap-northeast-1"
            awslogs-stream-prefix = "cowrie"
          }
          secretOptions = []
        }
        name = "cowrie-service"
        portMappings = [
          {
            containerPort = 22
            hostPort      = 22
            protocol      = "tcp"
          },
          {
            containerPort = 23
            hostPort      = 23
            protocol      = "tcp"
          },
          {
            containerPort = 2222
            hostPort      = 2222
            protocol      = "tcp"
          },
          {
            containerPort = 2223
            hostPort      = 2223
            protocol      = "tcp"
          },
        ]
      },
    ]
  )
  family                   = "cowrie-service"
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

resource "aws_ecs_service" "cowrie-service" {
  name            = "cowrie-service"
  cluster         = aws_ecs_cluster.honeypot-cluster.name
  task_definition = aws_ecs_task_definition.cowrie-service-def.arn

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
      aws_security_group.allow-ssh.id,
      aws_security_group.allow-ping.id
    ]
    subnets = [
      aws_subnet.subnet-public-1a.id,
      aws_subnet.subnet-public-1c.id,
      aws_subnet.subnet-public-1d.id
    ]
  }
}


