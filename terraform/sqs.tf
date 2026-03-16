resource "aws_sqs_queue" "messages_dlq" {
  name = "${local.name_prefix}-messages-dlq"
  tags = local.common_tags
}

resource "aws_sqs_queue" "messages" {
  name                       = "${local.name_prefix}-messages"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 20    # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.messages_dlq.arn
    maxReceiveCount     = 3
  })

  tags = local.common_tags
}
