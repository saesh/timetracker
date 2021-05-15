resource "aws_api_gateway_rest_api" "timetracker-tf" {
  name = "timetracker-tf"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.timetracker-tf.id
  parent_id   = aws_api_gateway_rest_api.timetracker-tf.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.timetracker-tf.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "timetracker_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.timetracker-tf.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.timetracker_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "timetracker-tf" {
  rest_api_id = aws_api_gateway_rest_api.timetracker-tf.id
  stage_name = "timetracker"

  depends_on = [
    aws_api_gateway_integration.timetracker_lambda,
  ]

  triggers = {
    redeployment = sha1(jsonencode([
        aws_api_gateway_resource.proxy.id,
        aws_api_gateway_method.proxy.id,
        aws_api_gateway_integration.timetracker_lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "base_url" {
  value = aws_api_gateway_deployment.timetracker-tf.invoke_url
}