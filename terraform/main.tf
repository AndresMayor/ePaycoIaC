resource "aws_lambda_function" "lambda" {
  count       = 4 
  function_name = "lambda${count.index}"
  handler = "src/index.handler"
  runtime = "nodejs14.x"
  role         = aws_iam_role.lambda_role.arn
  filename = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}
# Define el rol IAM para la función Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
# Creación del API Gateway
resource "aws_api_gateway_rest_api" "api-gateway" {
  name = "api-gateway"
  description = "API Gateway"
}
# Creamos recuso para el cronjob
resource "aws_api_gateway_resource" "resource-cronjob" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  parent_id   = aws_api_gateway_rest_api.api-gateway.root_resource_id
  path_part   = "cronjob"
}

resource "aws_api_gateway_method" "cronjob_method" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  resource_id = aws_api_gateway_resource.resource-cronjob.id
  http_method = "POST"
  authorization = "NONE"
}
# Define el permiso para que la función Lambda sea invocada por el API Gateway
resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[0].arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.api-gateway.execution_arn
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  resource_id = aws_api_gateway_resource.resource-cronjob.id
  http_method = aws_api_gateway_method.cronjob_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda[0].invoke_arn
}

# Define la regla de eventos en CloudWatch
resource "aws_cloudwatch_event_rule" "cron_job_rule" {
  name        = "regla-de-evento"
  description = "Regla de evento para el cron job"
  schedule_expression = "rate(1 minute)"  
}

# Asocia la regla de eventos con el bus de eventos predeterminado
resource "aws_cloudwatch_event_target" "cron_job_target" {
  rule      = aws_cloudwatch_event_rule.cron_job_rule.name
  target_id = "TargetId"
  arn       = aws_api_gateway_rest_api.api-gateway.execution_arn
}




