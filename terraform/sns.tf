locals {
  ami_tracker_sns_key_alias = "alias/ami-tracker-sns-key"
}

resource "aws_kms_key" "ami_tracker_sns_key" {
  description         = "KMS key for the sns topic"
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

resource "aws_kms_alias" "ami_tracker_sns_key_alias" {
  name          = local.ami_tracker_sns_key_alias
  target_key_id = aws_kms_key.ami_tracker_sns_key.key_id
}

resource "aws_sns_topic" "ami_tracker_ami_notification" {
  name              = "ami-tracker-ami-notification"
  kms_master_key_id = aws_kms_key.ami_tracker_sns_key.arn
}

resource "aws_sns_topic" "ami_tracker_ami_alarm" {
  count             = var.deploy_alarm_sns ? 1 : 0
  name              = "ami-tracker-ami-alarm"
  kms_master_key_id = aws_kms_key.ami_tracker_sns_key.arn
}

resource "aws_ssm_parameter" "ami_tracker_sns_param" {
  name  = "ami-tracker-sns-topic-arn"
  type  = "String"
  value = aws_sns_topic.ami_tracker_ami_notification.arn
}