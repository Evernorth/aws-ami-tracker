
resource "aws_iam_role" "ami_tracker_queuer_role" {
  name                  = "${var.app_name}-queuer"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ami_tracker_queuer_policy" {
  name = "${var.app_name}-queuer-policy"
  role = aws_iam_role.ami_tracker_queuer_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
        ]
        Resource = aws_dynamodb_table.ami_tracker.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
        ]
        Resource = aws_sqs_queue.ami_tracker_lookup_queue.arn
      },
      {
        Action = [
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:Describe*",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect = "Allow"
        Resource = [
          aws_kms_key.ami_tracker_table_key.arn,
          aws_kms_key.ami_tracker_sqs_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ami_tracker_lookup_role" {
  name                  = "${var.app_name}-lookup"
  force_detach_policies = true
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ami_tracker_lookup_policy" {
  name = "${var.app_name}-lookup-policy"
  role = aws_iam_role.ami_tracker_lookup_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem",
        ]
        Resource = aws_dynamodb_table.ami_tracker.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeImages",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.ami_tracker_lookup_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeImages",
          "sns:ListTopics",
          "ssm:GetParameter"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.ami_tracker_ami_notification.arn
      },
      {
        Action = [
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:Describe*",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect = "Allow"
        Resource = [
          aws_kms_key.ami_tracker_table_key.arn,
          aws_kms_key.ami_tracker_sns_key.arn,
          aws_kms_key.ami_tracker_sqs_key.arn
        ]
      }
    ]
  })
}