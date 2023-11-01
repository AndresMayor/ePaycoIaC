# Creación del API Gateway
resource "aws_api_gateway_rest_api" "api-gateway" {
  name = "api-gateway"
  description = "API Gateway"
}

resource "aws_lambda_function" "lambda" {
  count       = 4 
  function_name = "lambda-${count.index}"
  handler = "src/index.handler"
  runtime = "nodejs14.x"
  role = aws_iam_role.lambda_role.arn
  filename = "lambda_function.zip"
  	  # Asegúrate de tener el archivo ZIP con el código de tu función Lambda
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_iam_role" "lambda_role" {
  name = "route53-lambda-role"
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

