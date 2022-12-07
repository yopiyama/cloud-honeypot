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

