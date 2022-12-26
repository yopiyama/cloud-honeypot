resource "aws_iam_role_policy" "honeypot-log-policy" {
  name = "allow-s3-put-object-to-honeypot-log-bucket"
  role = aws_iam_role.ecs-service-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${aws_s3_bucket.log-bucket.bucket}/*"
      },
    ]
  })
}

resource "aws_iam_role" "ecs-service-role" {
  name = "ecs-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "task-execution-policy" {
  role = aws_iam_role.task-execution-role.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:CreateLogGroup",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    }
  )
}

resource "aws_iam_role" "task-execution-role" {
  name = "honeypot-ecs-TaskExecution"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
          Effect = "Allow"
          Sid    = ""
        }
      ]
    }
  )
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
            "aoss:CreateCollectionItems",
            "aoss:CreateIndex",
            "aoss:DeleteIndex",
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:WriteDocument"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    }
  )
}


resource "aws_iam_role" "ecs-service-automation-role" {
  name = "ecs-service-automation-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach-ssm-automation" {
  role       = aws_iam_role.ecs-service-automation-role.name
  policy_arn = data.aws_iam_policy.ssm-automation-basic-role.arn
}

data "aws_iam_policy" "ssm-automation-basic-role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRolee"
}



resource "aws_iam_role_policy" "ecs-service-automation--policy" {
  role = aws_iam_role.ecs-service-automation-role.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [

          ]
          Effect   = "ecs:UpdateService"
          Resource = "arn:aws:ecs:${var.region}:094940149171:service/${aws_ecs_cluster.honeypot-cluster}/*"
        }
      ]
    }
  )
}
