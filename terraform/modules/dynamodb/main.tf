# ─────────────────────────────────────────
# DynamoDB Table — Sessions / Checkout
# ─────────────────────────────────────────
resource "aws_dynamodb_table" "sessions" {
  name         = "${var.cluster_name}-${var.table_name}"
  billing_mode = "PAY_PER_REQUEST"  # no capacity planning needed, cost-efficient
  hash_key     = "sessionId"

  attribute {
    name = "sessionId"
    type = "S"   # S = String
  }

  # Auto-delete old sessions after 24 hours
  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  # Encrypt table data at rest
  server_side_encryption {
    enabled = true
  }

  # Protect against accidental deletion
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.cluster_name}-${var.table_name}"
  }
}

# ─────────────────────────────────────────
# IAM Policy — allows EKS pods to access
# the DynamoDB table via IRSA
# ─────────────────────────────────────────
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.cluster_name}-dynamodb-access"
  description = "Allows retail app pods to read/write DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.sessions.arn
      }
    ]
  })
}

