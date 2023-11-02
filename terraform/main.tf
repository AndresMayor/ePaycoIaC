resource "aws_lambda_function" "lambda" {
  count       = 2 
  function_name = "lambda${count.index}"
  handler = "index.handler"
  runtime = "nodejs14.x"
  role         = aws_iam_role.lambda_role.arn
  filename = "../src/lambda_function.zip"
  source_code_hash = filebase64sha256("../src/lambda_function.zip")
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
# Creamos recuso para las confirmaciones
resource "aws_api_gateway_resource" "resource-confirmaciones" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  parent_id   = aws_api_gateway_rest_api.api-gateway.root_resource_id
  path_part   = "confirmaciones"
}
resource "aws_api_gateway_resource" "resource-transacciones" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  parent_id   = aws_api_gateway_rest_api.api-gateway.root_resource_id
  path_part   = "transaciones"
}

resource "aws_api_gateway_method" "confirm_method" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  resource_id = aws_api_gateway_resource.resource-confirmaciones.id
  http_method = "ANY"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "transa_method" {
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  resource_id = aws_api_gateway_resource.resource-transacciones.id
  http_method = "ANY"
  authorization = "NONE"
}
# Define el permiso para que la función Lambda sea invocada por el API Gateway
resource "aws_lambda_permission" "lambda_permission" {
  depends_on = [aws_api_gateway_deployment.api_deployment]
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[0].arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.api-gateway.execution_arn
}
resource "aws_lambda_permission" "lambda_permission2" {
  depends_on = [aws_api_gateway_deployment.api_deployment]
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[1].arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.api-gateway.execution_arn
}

resource "aws_api_gateway_integration" "lambda_integration" {
  depends_on = [aws_lambda_function.lambda,
                aws_api_gateway_rest_api.api-gateway]
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  resource_id = aws_api_gateway_resource.resource-confirmaciones.id
  http_method = aws_api_gateway_method.confirm_method.http_method
  integration_http_method = "ANY"
  type                    = "AWS"
  uri                     = aws_lambda_function.lambda[0].invoke_arn
}

resource "aws_api_gateway_integration" "lambda_integration2" {
  depends_on = [aws_lambda_function.lambda,
                aws_api_gateway_rest_api.api-gateway]
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  resource_id = aws_api_gateway_resource.resource-transacciones.id
  http_method = aws_api_gateway_method.transa_method.http_method
  integration_http_method = "ANY"
  type                    = "AWS"
  uri                     = aws_lambda_function.lambda[1].invoke_arn
}

#Despliegue ApiGateway
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration,
                aws_api_gateway_rest_api.api-gateway]
  rest_api_id = aws_api_gateway_rest_api.api-gateway.id
  stage_name = "prod"
}

# Define la regla de eventos en CloudWatch
resource "aws_cloudwatch_event_rule" "cron_job_rule" {
  name        = "regla-de-evento"
  description = "Regla de evento para el cron job"
  schedule_expression = "rate(1 minute)"  
}

#BaseDeDatos
resource "aws_db_instance" "dbDatabase" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "password"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

