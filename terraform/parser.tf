data "archive_file" "parser-lambda-source" {
  type        = "zip"
  source_dir  = "../lambda/src/log-parser/"
  output_path = "../lambda/uploads/parser-function.zip"
}

resource "null_resource" "pip_install" {
  provisioner "local-exec" {
    command = "pip install -r ../lambda/src/log-parser/requirements.txt -t ../lambda/module/python"
  }
}

data "archive_file" "lambda-layer-source" {
  type        = "zip"
  source_dir  = "../lambda/module/"
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
