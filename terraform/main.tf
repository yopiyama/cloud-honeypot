terraform {
  required_version = "~> 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.45.0"
    }
  }
  backend "s3" {
  }
}



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

variable "os_endpoint" {}
