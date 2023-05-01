output "function_arn" {
  value = aws_lambda_function.apollo_graphql.arn
}

output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.apollo_graphql_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod/graphql"
}