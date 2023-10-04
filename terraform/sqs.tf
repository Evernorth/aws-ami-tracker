locals {
  ami_tracker_sqs_key_alias = "alias/ami-tracker-sqs-key"
}

resource "aws_sqs_queue" "ami_tracker_lookup_queue" {
  name                       = "ami-tracker-lookup-queue"
  delay_seconds              = 90
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 180
  kms_master_key_id          = aws_kms_alias.ami_tracker_sqs_key_alias.target_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ami_tracker_lookup_dlq.arn
    maxReceiveCount     = 10
  })

}

resource "aws_sqs_queue" "ami_tracker_lookup_dlq" {
  name                       = "ami-tracker-lookup-dlq"
  delay_seconds              = 90
  max_message_size           = 2048
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 180
  kms_master_key_id          = aws_kms_alias.ami_tracker_sqs_key_alias.target_key_arn
}

resource "aws_kms_key" "ami_tracker_sqs_key" {
  description         = "KMS key for the ami tracker table"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "${data.aws_caller_identity.current.arn}"
          ]
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "ami_tracker_sqs_key_alias" {
  name          = local.ami_tracker_sqs_key_alias
  target_key_id = aws_kms_key.ami_tracker_sqs_key.key_id
}