provider "aws" {
  region = "us-east-1"
}

locals {
  lambda_function_name = "apollo-graphql-lambda"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_dir  = "${path.module}/../../dist"
}

resource "aws_iam_role" "lambda_role" {
  name = "apollo_graphql_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "apollo_graphql" {
  function_name = local.lambda_function_name
  handler       = "bundle.default"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "nodejs14.x"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      NODE_ENV = "production"
    }
  }
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apollo_graphql.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_deployment.apollo_graphql_deployment.execution_arn}/*/*"
}

resource "aws_api_gateway_rest_api" "apollo_graphql_api" {
  name        = "ApolloGraphQLAPI"
  description = "API Gateway for the Apollo GraphQL server"
}

resource "aws_api_gateway_resource" "graphql_resource" {
  rest_api_id = aws_api_gateway_rest_api.apollo_graphql_api.id
  parent_id   = aws_api_gateway_rest_api.apollo_graphql_api.root_resource_id
  path_part   = "graphql"
}

resource "aws_api_gateway_method" "graphql_method" {
  rest_api_id   = aws_api_gateway_rest_api.apollo_graphql_api.id
  resource_id   = aws_api_gateway_resource.graphql_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.apollo_graphql_api.id
  resource_id = aws_api_gateway_resource.graphql_resource.id
  http_method = aws_api_gateway_method.graphql_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.apollo_graphql.invoke_arn
}

resource "aws_api_gateway_deployment" "apollo_graphql_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.apollo_graphql_api.id
  stage_name  = "prod"
}
