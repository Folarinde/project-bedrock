# ─────────────────────────────────────────
# Zip the Lambda function code
# Terraform does this automatically from
# the local file — no manual zipping needed
# ─────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../lambda/asset_processor.py"
  output_path = "${path.module}/asset_processor.zip"
}

# ─────────────────────────────────────────
# IAM Role — Lambda Execution Role
# ─────────────────────────────────────────
resource "aws_iam_role" "lambda" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.lambda_function_name}-role"
  }
}

# Attach the basic Lambda execution policy
# This grants permission to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

# Additional policy to allow Lambda to read from S3
# (in case you want to process the actual file content later)
resource "aws_iam_role_policy" "lambda_s3_read" {
  name = "${var.lambda_function_name}-s3-read"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectAttributes"
        ]
        Resource = "arn:aws:s3:::bedrock-assets-${var.student_id}/*"
      }
    ]
  })
}

# ─────────────────────────────────────────
# S3 Bucket — bedrock-assets-[student-id]
# ─────────────────────────────────────────
resource "aws_s3_bucket" "assets" {
  # This exact naming format is required by the project spec
  bucket = "bedrock-assets-${var.student_id}"

  tags = {
    Name = "bedrock-assets-${var.student_id}"
  }
}

# Block all public access — this bucket is private
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for file history
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt all objects at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ─────────────────────────────────────────
# S3 Bucket Policy
# Allows bedrock-dev-view to upload files
# (required for grader to test Lambda trigger)
# ─────────────────────────────────────────
resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDevUserPutObject"
        Effect = "Allow"
        Principal = {
          AWS = var.dev_user_arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })

  # Bucket policy can only be applied after
  # public access block is in place
  depends_on = [aws_s3_bucket_public_access_block.assets]
}

# ─────────────────────────────────────────
# Lambda Function — bedrock-asset-processor
# ─────────────────────────────────────────
resource "aws_lambda_function" "asset_processor" {
  function_name = var.lambda_function_name
  description   = "Processes uploaded product images from S3"

  # Point to the zipped code
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Python runtime — matches our asset_processor.py
  runtime = "python3.12"

  # "handler" = filename.function_name
  # asset_processor.py → handler function
  handler = "asset_processor.handler"

  # Attach the IAM execution role
  role = aws_iam_role.lambda.arn

  # Resource limits — keep minimal for this project
  memory_size = 128   # MB
  timeout     = 30    # seconds

  # Environment variables (optional but useful for debugging)
  environment {
    variables = {
      LOG_LEVEL    = "INFO"
      PROJECT_NAME = "karatu-2025-capstone"
    }
  }

  tags = {
    Name = var.lambda_function_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    data.archive_file.lambda_zip
  ]
}

# ─────────────────────────────────────────
# CloudWatch Log Group for Lambda
# Pre-create it so we control retention
# (otherwise AWS creates it with no expiry)
# ─────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 7   # keep logs for 7 days — enough for grading

  tags = {
    Name = "${var.lambda_function_name}-logs"
  }
}

# ─────────────────────────────────────────
# Lambda Permission
# Grants S3 permission to invoke Lambda
# (without this S3 cannot trigger Lambda)
# ─────────────────────────────────────────
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asset_processor.function_name
  principal     = "s3.amazonaws.com"

  # Restrict to only your specific bucket — security best practice
  source_arn = aws_s3_bucket.assets.arn
}

# ─────────────────────────────────────────
# S3 Event Notification
# Triggers Lambda on ANY file upload
# to ANY folder in the bucket
# ─────────────────────────────────────────
resource "aws_s3_bucket_notification" "lambda_trigger" {
  bucket = aws_s3_bucket.assets.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.asset_processor.arn

    # Trigger on all object creation events
    # (covers uploads via console, CLI, SDK)
    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:Post",
      "s3:ObjectCreated:Copy",
      "s3:ObjectCreated:CompleteMultipartUpload"
    ]

    # Optional: only trigger for specific file types
    # filter_suffix = ".jpg"
    # Leaving this commented out so ALL file types trigger Lambda
    # which is safer for grading
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}