resource "aws_s3_bucket" "log-bucket" {
  bucket = "honeypot-log-bucket"
}

resource "aws_s3_bucket_public_access_block" "log-bucket-public-access-block" {
  bucket                  = aws_s3_bucket.log-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "log-bucket-versioning" {
  bucket = aws_s3_bucket.log-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log-bucket-encryption-conf" {
  bucket = aws_s3_bucket.log-bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "log-bucket-acl" {
  bucket = aws_s3_bucket.log-bucket.id
  acl    = "private"
}

resource "aws_cloudwatch_log_group" "honeypot-log-cowrie" {
  name = "/ecs/honeypot-cluster/cowrie"
}

resource "aws_cloudwatch_log_group" "honeypot-log-mysql-honeypotd" {
  name = "/ecs/honeypot-cluster/mysql-honeypotd"
}

resource "aws_cloudwatch_query_definition" "parse-cowrie-query" {
  name = "parse-cowrie"

  log_group_names = [
    aws_cloudwatch_log_group.honeypot-log-cowrie.name
  ]

  query_string = <<EOF
  fields @timestamp, @message
  | sort @timestamp desc
  | parse @message "*-*-*T*:*:*+* [*] *" as year, month, day, hour, minute, sec, zone, location, log
  | display month, day, hour, minute, sec, location, log
EOF
}
