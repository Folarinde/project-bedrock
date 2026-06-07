# ─────────────────────────────────────────
# CloudWatch Log Groups
# Pre-create with retention policies
# to control costs
# ─────────────────────────────────────────

# Control plane logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  tags = {
    Name = "${var.cluster_name}-control-plane-logs"
  }
}

# Application container logs
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/containerinsights/${var.cluster_name}/application"
  retention_in_days = 7

  tags = {
    Name = "${var.cluster_name}-application-logs"
  }
}

# Host-level logs
resource "aws_cloudwatch_log_group" "host" {
  name              = "/aws/containerinsights/${var.cluster_name}/host"
  retention_in_days = 3

  tags = {
    Name = "${var.cluster_name}-host-logs"
  }
}

# Dataplane logs (kubelet, kube-proxy, containerd)
resource "aws_cloudwatch_log_group" "dataplane" {
  name              = "/aws/containerinsights/${var.cluster_name}/dataplane"
  retention_in_days = 3

  tags = {
    Name = "${var.cluster_name}-dataplane-logs"
  }
}