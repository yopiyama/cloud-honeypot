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
  cluster_name = aws_ecs_cluster.honeypot-cluster.name
}


resource "aws_ecr_repository" "cowrie-repo" {
  name                 = "cowrie"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "mysql-honeypotd-repo" {
  name                 = "mysql-honeypotd"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Images

resource "null_resource" "cowrie-repo-push" {
  triggers = {
    image_tag = var.cowrie_image_tag
  }

  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

      # docker pull --platform linux/amd64 $IMAGE_TAG
      # docker tag $IMAGE_TAG $REPO_URL:latest
      # docker build --platform linux/amd64 -t cowrie:original -f ../pot/Cowrie/cowrie/docker/Dockerfile ../pot/Cowrie/cowrie/

      docker build --platform linux/amd64 -t $REPO_URL:$IMAGE_TAG ../pot/Cowrie/
      docker push $REPO_URL:$IMAGE_TAG
    EOT

    environment = {
      AWS_REGION     = var.region
      AWS_ACCOUNT_ID = var.account_id
      REPO_URL       = aws_ecr_repository.cowrie-repo.repository_url
      IMAGE_TAG = var.cowrie_image_tag
    }
  }
}

resource "null_resource" "mysql-honeypotd-push" {
  triggers = {
    image_tag = var.mysql_honeypotd_image_tag
  }

  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
      docker build --platform linux/amd64 -t $REPO_URL:$IMAGE_TAG ../pot/mysql-honeypotd/
      docker push $REPO_URL:$IMAGE_TAG
    EOT

    environment = {
      AWS_REGION     = var.region
      AWS_ACCOUNT_ID = var.account_id
      REPO_URL       = aws_ecr_repository.mysql-honeypotd-repo.repository_url
      IMAGE_TAG = var.mysql_honeypotd_image_tag
    }
  }
}
