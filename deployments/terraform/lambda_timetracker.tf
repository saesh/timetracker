locals {
  release_file = "../../target/${var.project_name}.zip"
  function_name = "TimeTracker-TF"
}

resource "aws_iam_role" "iam_for_lambda_timetracker" {
  name = "iam_for_lambda_timetracker"

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

resource "aws_lambda_function" "timetracker_lambda" {
  function_name    = local.function_name
  role             = aws_iam_role.iam_for_lambda_timetracker.arn
  runtime          = "go1.x"
  filename         = local.release_file
  source_code_hash = filebase64sha256(local.release_file)
  handler          = "timetracker"
  
  environment {
    variables = {
      aws_region = var.aws_region
      s3_bucket  = module.timetracker_s3_bucket.s3_bucket_id
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.timetracker,
    aws_iam_role_policy_attachment.AmazonS3FullAccess,
  ]
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "timetracker" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda_timetracker.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role       = aws_iam_role.iam_for_lambda_timetracker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}