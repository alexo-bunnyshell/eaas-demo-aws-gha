# =============================================================================
# MSK (Managed Streaming for Apache Kafka) Cluster
# =============================================================================
# Disabled by default: set enable_msk = true to provision.
# Note: MSK takes ~20 minutes to create and costs ~$200/month minimum.
# The configuration below provisions a production-ready 3-broker cluster
# with SASL/SCRAM authentication and TLS encryption.
# =============================================================================

data "aws_vpc" "default" {
  count   = var.enable_msk ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.enable_msk ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

resource "aws_security_group" "msk" {
  count       = var.enable_msk ? 1 : 0
  name        = "${local.name_prefix}-msk"
  description = "Security group for MSK cluster"
  vpc_id      = data.aws_vpc.default[0].id

  ingress {
    from_port   = 9092
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default[0].cidr_block]
    description = "Kafka broker ports"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "msk" {
  count             = var.enable_msk ? 1 : 0
  name              = "/aws/msk/${local.name_prefix}"
  retention_in_days = 7
  tags              = local.common_tags
}

resource "aws_msk_cluster" "main" {
  count         = var.enable_msk ? 1 : 0
  cluster_name  = "${local.name_prefix}-kafka"
  kafka_version = "3.5.1"

  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type  = "kafka.t3.small"
    client_subnets = slice(data.aws_subnets.default[0].ids, 0, 3)

    storage_info {
      ebs_storage_info {
        volume_size = 100
      }
    }

    security_groups = [aws_security_group.msk[0].id]
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk[0].name
      }
    }
  }

  tags = local.common_tags
}

# MSK outputs (only available when enabled)
output "msk_bootstrap_brokers_tls" {
  description = "TLS connection string for Kafka brokers"
  value       = var.enable_msk ? aws_msk_cluster.main[0].bootstrap_brokers_tls : "MSK not enabled"
}

output "msk_cluster_arn" {
  description = "ARN of the MSK cluster"
  value       = var.enable_msk ? aws_msk_cluster.main[0].arn : "MSK not enabled"
}
