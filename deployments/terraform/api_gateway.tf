resource "aws_api_gateway_rest_api" "timetracker-tf" {
  name = "timetracker-tf"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "start" {
  rest_api_id = aws_api_gateway_rest_api.timetracker-tf.id
  parent_id   = aws_api_gateway_rest_api.timetracker-tf.root_resource_id
  path_part   = "start"
}

resource "aws_api_gateway_resource" "stop" {
  rest_api_id = aws_api_gateway_rest_api.timetracker-tf.id
  parent_id   = aws_api_gateway_rest_api.timetracker-tf.root_resource_id
  path_part   = "stop"
}


resource "aws_api_gateway_method" "start" {
  rest_api_id   = aws_api_gateway_rest_api.timetracker-tf.id
  resource_id   = aws_api_gateway_resource.start.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "stop" {
  rest_api_id   = aws_api_gateway_rest_api.timetracker-tf.id
  resource_id   = aws_api_gateway_resource.stop.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "start_timetracker_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.timetracker-tf.id
  resource_id             = aws_api_gateway_method.start.resource_id
  http_method             = aws_api_gateway_method.start.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.timetracker_lambda.invoke_arn
}

resource "aws_api_gateway_integration" "stop_timetracker_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.timetracker-tf.id
  resource_id             = aws_api_gateway_method.stop.resource_id
  http_method             = aws_api_gateway_method.stop.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.timetracker_lambda.invoke_arn
}

resource "aws_iam_role" "s3_api_gateway_role" {
  name = "s3-api-gateyway-role"

  # Create Trust Policy for API Gateway
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
} 
  EOF
}

resource "aws_iam_role_policy_attachment" "AmazonS3ReadOnlyAccess" {
  role       = aws_iam_role.s3_api_gateway_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_api_gateway_resource" "file" {
  rest_api_id = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  parent_id   = "${aws_api_gateway_rest_api.timetracker-tf.root_resource_id}"
  path_part   = "{file}"
}

resource "aws_api_gateway_method" "file" {
  rest_api_id   = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  resource_id   = "${aws_api_gateway_resource.file.id}"
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.file" = true
  }
}

resource "aws_api_gateway_integration" "S3Integration" {
  rest_api_id = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  resource_id = "${aws_api_gateway_resource.file.id}"
  http_method = "${aws_api_gateway_method.file.http_method}"

  # Included because of this issue: https://github.com/hashicorp/terraform/issues/10501
  integration_http_method = "GET"

  type = "AWS"

  request_parameters = {
    "integration.request.path.bucket" = "'${module.timetracker_s3_bucket.s3_bucket_id}'"
    "integration.request.path.object" = "method.request.path.file"
  }

  # See uri description: https://docs.aws.amazon.com/apigateway/api-reference/resource/integration/
  uri         = "arn:aws:apigateway:${var.aws_region}:s3:path//{bucket}/{object}"
  credentials = "${aws_iam_role.s3_api_gateway_role.arn}"
}

resource "aws_api_gateway_method_response" "OK" {
  rest_api_id = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  resource_id = "${aws_api_gateway_resource.file.id}"
  http_method = "${aws_api_gateway_method.file.http_method}"
  status_code = "200"

  response_parameters = {
    "method.response.header.Timestamp"      = true
    "method.response.header.Content-Length" = true
    "method.response.header.Content-Type"   = true
  }

  response_models = {
    "text/plain" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "BadRequest" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  resource_id = "${aws_api_gateway_resource.file.id}"
  http_method = "${aws_api_gateway_method.file.http_method}"
  status_code = "400"
}

resource "aws_api_gateway_method_response" "InternalServerError" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  resource_id = "${aws_api_gateway_resource.file.id}"
  http_method = "${aws_api_gateway_method.file.http_method}"
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "IntegrationResponse200" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  resource_id = "${aws_api_gateway_resource.file.id}"
  http_method = "${aws_api_gateway_method.file.http_method}"
  status_code = "${aws_api_gateway_method_response.OK.status_code}"

  response_parameters = {
    "method.response.header.Timestamp"      = "integration.response.header.Date"
    "method.response.header.Content-Length" = "integration.response.header.Content-Length"
    "method.response.header.Content-Type"   = "integration.response.header.Content-Type"
  }
}

resource "aws_api_gateway_integration_response" "IntegrationResponse400" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  resource_id = "${aws_api_gateway_resource.file.id}"
  http_method = "${aws_api_gateway_method.file.http_method}"
  status_code = "${aws_api_gateway_method_response.BadRequest.status_code}"

  selection_pattern = "4\\d{2}"
}

resource "aws_api_gateway_integration_response" "IntegrationResponse500" {
  depends_on = [aws_api_gateway_integration.S3Integration]

  rest_api_id = "${aws_api_gateway_rest_api.timetracker-tf.id}"
  resource_id = "${aws_api_gateway_resource.file.id}"
  http_method = "${aws_api_gateway_method.file.http_method}"
  status_code = "${aws_api_gateway_method_response.InternalServerError.status_code}"

  selection_pattern = "5\\d{2}"
}

resource "aws_api_gateway_deployment" "timetracker-tf" {
  rest_api_id = aws_api_gateway_rest_api.timetracker-tf.id
  stage_name = "timetracker"

  depends_on = [
    aws_api_gateway_integration.start_timetracker_lambda,
    aws_api_gateway_integration.stop_timetracker_lambda,
    aws_api_gateway_integration.S3Integration,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
        aws_api_gateway_resource.start.id,
        aws_api_gateway_resource.stop.id,
        aws_api_gateway_resource.file.id,
        aws_api_gateway_method.start.id,
        aws_api_gateway_method.stop.id,
        aws_api_gateway_method.file.id,
        aws_api_gateway_integration.start_timetracker_lambda.id,
        aws_api_gateway_integration.stop_timetracker_lambda.id,
        aws_api_gateway_integration.S3Integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "base_url" {
  value = aws_api_gateway_deployment.timetracker-tf.invoke_url
}