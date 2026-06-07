# ─────────────────────────────────────────
# IAM User — bedrock-dev-view
# ─────────────────────────────────────────
resource "aws_iam_user" "dev" {
  name = var.dev_username
  path = "/"

  # If you delete this user via Terraform,
  # force-remove all attached policies first
  force_destroy = true

  tags = {
    Name    = var.dev_username
    Purpose = "Developer read-only access for grading"
  }
}

# ─────────────────────────────────────────
# Console Login Profile
# Allows the user to log into AWS Console
# ─────────────────────────────────────────
resource "aws_iam_user_login_profile" "dev" {
  user = aws_iam_user.dev.name

  # The console password — stored in variables
  # never hardcoded here

  # Force password change on first login
  # Set to false so grader can log in immediately
  password_reset_required = false

  depends_on = [aws_iam_user.dev]
}

# ─────────────────────────────────────────
# Attach ReadOnlyAccess
# Grants view access to ALL AWS services
# in the console (EC2, EKS, CloudWatch etc.)
# ─────────────────────────────────────────
resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.dev.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ─────────────────────────────────────────
# Custom Policy — S3 PutObject on assets bucket
# Grader uploads test file to verify Lambda trigger
# ─────────────────────────────────────────
resource "aws_iam_user_policy" "s3_put" {
  name = "${var.dev_username}-s3-put-policy"
  user = aws_iam_user.dev.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPutObjectOnAssetsBucket"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        # Scope to your specific bucket only
        # least-privilege — cannot touch other buckets
        Resource = "${var.assets_bucket_arn}/*"
      },
      {
        Sid    = "AllowListBucket"
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = var.assets_bucket_arn
      }
    ]
  })
}

# ─────────────────────────────────────────
# EKS Access Entry
# Registers the IAM user with the EKS cluster
# Replaces the legacy aws-auth ConfigMap approach
# ─────────────────────────────────────────
resource "aws_eks_access_entry" "dev" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_user.dev.arn
  type          = "STANDARD"

  tags = {
    Name = "${var.dev_username}-eks-access"
  }
}

# ─────────────────────────────────────────
# EKS Access Policy Association
# Binds the built-in AmazonEKSViewPolicy
# to this user — grants read-only kubectl access
# across all namespaces including retail-app
# ─────────────────────────────────────────
resource "aws_eks_access_policy_association" "dev_view" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_user.dev.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    # "cluster" means access applies to all namespaces
    # including retail-app where the grader will check pods
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.dev]
}

# ─────────────────────────────────────────
# Access Keys
# Grader uses these to configure AWS CLI
# and run kubectl commands
# ─────────────────────────────────────────
resource "aws_iam_access_key" "dev" {
  user = aws_iam_user.dev.name

  depends_on = [aws_iam_user.dev]
}

