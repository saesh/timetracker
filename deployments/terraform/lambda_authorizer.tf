locals {
  authorizer_release_file  = "../../target/authorizer.zip"
  authorizer_function_name = "Authorizer"
}

variable "basic_auth_username" {
  description = "The basic auth username"
  type        = string
  sensitive   = true
}

variable "basic_auth_password" {
  description = "The basic auth password"
  type        = string
  sensitive   = true
}

resource "aws_iam_role" "iam_for_lambda_authorizer" {
  name = "iam_for_lambda_authorizer"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "authorizer_lambda" {
  function_name    = local.authorizer_function_name
  role             = aws_iam_role.iam_for_lambda_authorizer.arn
  runtime          = "go1.x"
  filename         = local.authorizer_release_file
  source_code_hash = filebase64sha256(local.authorizer_release_file)
  handler          = "authorizer"
  
  environment {
    variables = {
      USERNAME = var.basic_auth_username
      PASSWORD  = var.basic_auth_password
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.authorizer,
  ]
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "authorizer" {
  name              = "/aws/lambda/${local.authorizer_function_name}"
  retention_in_days = 14
}

resource "aws_iam_role_policy_attachment" "authorizer_lambda_logs" {
  role       = aws_iam_role.iam_for_lambda_authorizer.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}