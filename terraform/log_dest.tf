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

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.parser-lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.log-bucket.arn
}

# resource "aws_s3_bucket_notification" "bucket_notification" {
#   bucket = aws_s3_bucket.log-bucket.bucket

#   lambda_function {
#     lambda_function_arn = aws_lambda_function.parser-lambda.arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_prefix       = "RawLogs/"
#   }
# }

resource "aws_s3_bucket_acl" "log-bucket-acl" {
  bucket = aws_s3_bucket.log-bucket.id
  acl    = "private"
}

resource "aws_cloudwatch_log_group" "firelens-log" {
  name = "/ecs/honeypot-cluster/firelens"
}
