data "archive_file" "parser-lambda-source" {
  type        = "zip"
  source_dir  = "../lambda/src/"
  output_path = "../lambda/uploads/function.zip"
}

resource "null_resource" "pip_install" {
  provisioner "local-exec" {
    command = "pip3 install -r ../lambda/src/requirements.txt -t ../lambda/python"
  }
}

data "archive_file" "lambda-layer-source" {
  type        = "zip"
  source_dir  = "../lambda/python/"
  output_path = "../lambda/uploads/layer.zip"
}

resource "aws_lambda_layer_version" "lambda-layer" {
  layer_name          = "parser-layer"
  filename            = data.archive_file.lambda-layer-source.output_path
  compatible_runtimes = ["python3.9"]
  source_code_hash    = data.archive_file.lambda-layer-source.output_base64sha256
  skip_destroy        = true
}

resource "aws_lambda_function" "parser-lambda" {
  filename         = data.archive_file.parser-lambda-source.output_path
  function_name    = "log-parser"
  role             = aws_iam_role.parser-lambda-role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.parser-lambda-source.output_base64sha256
  runtime          = "python3.9"
  layers           = [aws_lambda_layer_version.lambda-layer.arn]
  memory_size      = 128
  timeout          = 60
  environment {
    variables = {
      OS_ENDPOINT = var.os_endpoint
    }
  }
}

resource "aws_iam_role" "parser-lambda-role" {
  name = "parser-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach-lambda_basic_execution" {
  role       = aws_iam_role.parser-lambda-role.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution.arn
}

data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3-put-get-policy" {
  role = aws_iam_role.parser-lambda-role.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:ListObject",
            "s3:PutObject"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:s3:::${aws_s3_bucket.log-bucket.bucket}/*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy" "opensearch-put-policy" {
  role = aws_iam_role.parser-lambda-role.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            # "aoss:*",
            "es:ESHttpPut"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    }
  )
}
