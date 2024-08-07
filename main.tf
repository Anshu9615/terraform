provider "aws" {
  region = "us-east-1" # Specify your AWS region
}

# Generate SSH key pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "instance_key.pem"
}

resource "aws_key_pair" "key" {
  key_name   = "example_key"
  public_key = tls_private_key.example.public_key_openssh
}

# Create an IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "ec2_instance_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}

# Attach a policy to the IAM Role
resource "aws_iam_role_policy" "ec2_policy" {
  name   = "ec2_policy"
  role   = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:ListBucket", # Example action for S3
          "s3:GetObject"   # Example action for S3
          # Add other permissions as needed
        ],
        Effect   = "Allow",
        Resource = "*"
      },
    ],
  })
}

# Create an instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the first subnet ID from the list of default subnets
data "aws_subnet" "default" {
  id = data.aws_subnets.default.ids[0]
}

resource "aws_security_group" "allow_ssh" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting this to trusted IP ranges
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_instance" "ubuntu" {
  ami           = "ami-04a81a99f5ec58529" # Replace with a valid AMI ID
  instance_type = "t2.large"
  subnet_id     = data.aws_subnet.default.id

  # Use security group ID instead of group name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
  key_name = aws_key_pair.key.key_name
  
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "UbuntuInstance"
  }
}

variable "environment" {
  description = "The environment for which this bucket is created (e.g., dev, prod)"
  type        = string
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "example_bucket" {
  bucket = "mybucket12345-${random_string.suffix.result}"
  acl    = "private"                    # Set the access control list

  # Enable versioning
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "mybucket12345-${random_string.suffix.result}"
    Environment = var.environment
  }
}

# Create an IAM Role for the Lambda functions
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

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
      },
    ]
  })
}

# Attach a basic execution role for Lambda
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Define the first Lambda function
resource "aws_lambda_function" "lambda_function_1" {
  function_name = "lambda_function_1"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda1.zip" # Ensure this file exists in the correct path

  environment {
    variables = {
      EXAMPLE_ENV_VAR = "example_value"
    }
  }
}

# Define the second Lambda function
resource "aws_lambda_function" "lambda_function_2" {
  function_name = "lambda_function_2"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda2.zip" # Ensure this file exists in the correct path

  environment {
    variables = {
      EXAMPLE_ENV_VAR = "example_value"
    }
  }
}

# Define the third Lambda function
resource "aws_lambda_function" "lambda_function_3" {
  function_name = "lambda_function_3"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda3.zip" # Ensure this file exists in the correct path

  environment {
    variables = {
      EXAMPLE_ENV_VAR = "example_value"
    }
  }
}

# Define the fourth Lambda function
resource "aws_lambda_function" "lambda_function_4" {
  function_name = "lambda_function_4"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = "lambda4.zip" # Ensure this file exists in the correct path

  environment {
    variables = {
      EXAMPLE_ENV_VAR = "example_value"
    }
  }
}

# Create an API Gateway
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my_api"
  description = "API for my Lambda functions"
}

# Create resources and methods for each Lambda function in the API Gateway
resource "aws_api_gateway_resource" "api_resource_1" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "resource1"
}

resource "aws_api_gateway_resource" "api_resource_2" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "resource2"
}

resource "aws_api_gateway_resource" "api_resource_3" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "resource3"
}

resource "aws_api_gateway_resource" "api_resource_4" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "resource4"
}

# Create a GET method for each resource
resource "aws_api_gateway_method" "api_method_1" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource_1.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "api_method_2" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource_2.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "api_method_3" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource_3.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "api_method_4" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.api_resource_4.id
  http_method   = "GET"
  authorization = "NONE"
}

# Create an integration between API Gateway and each Lambda function
resource "aws_api_gateway_integration" "api_integration_1" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.api_resource_1.id
  http_method             = aws_api_gateway_method.api_method_1.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function_1.invoke_arn
}

resource "aws_api_gateway_integration" "api_integration_2" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.api_resource_2.id
  http_method             = aws_api_gateway_method.api_method_2.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function_2.invoke_arn
}

resource "aws_api_gateway_integration" "api_integration_3" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.api_resource_3.id
  http_method             = aws_api_gateway_method.api_method_3.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function_3.invoke_arn
}

resource "aws_api_gateway_integration" "api_integration_4" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.api_resource_4.id
  http_method             = aws_api_gateway_method.api_method_4.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function_4.invoke_arn
}

# Grant API Gateway permission to invoke each Lambda function
resource "aws_lambda_permission" "api_gateway_permission_1" {
  statement_id  = "AllowAPIGatewayInvoke1"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_2" {
  statement_id  = "AllowAPIGatewayInvoke2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_3" {
  statement_id  = "AllowAPIGatewayInvoke3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_3.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_permission_4" {
  statement_id  = "AllowAPIGatewayInvoke4"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_4.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "my_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.api_integration_1,
    aws_api_gateway_integration.api_integration_2,
    aws_api_gateway_integration.api_integration_3,
    aws_api_gateway_integration.api_integration_4
  ]
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "dev"
}

# Output the API Gateway URLs
output "api_gateway_url_1" {
  value = "${aws_api_gateway_deployment.my_api_deployment.invoke_url}/dev/resource1"
}

output "api_gateway_url_2" {
  value = "${aws_api_gateway_deployment.my_api_deployment.invoke_url}/dev/resource2"
}

output "api_gateway_url_3" {
  value = "${aws_api_gateway_deployment.my_api_deployment.invoke_url}/dev/resource3"
}

output "api_gateway_url_4" {
  value = "${aws_api_gateway_deployment.my_api_deployment.invoke_url}/dev/resource4"
}

output "bucket_name" {
  value = aws_s3_bucket.example_bucket.bucket
}
