locals {
  ami_tracker_key_alias = "alias/ami-tracker-ddb-key"
}

resource "aws_kms_key" "ami_tracker_table_key" {
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

resource "aws_kms_alias" "ami_tracker_table_key_alias" {
  name          = local.ami_tracker_key_alias
  target_key_id = aws_kms_key.ami_tracker_table_key.key_id
}

resource "aws_dynamodb_table" "ami_tracker" {
  name           = var.app_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "AmiName"
  stream_enabled = false
  tags           = var.data_at_rest_tags
  attribute {
    name = "AmiName"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.ami_tracker_table_key.arn
  }
}

resource "null_resource" "syncronize_data" {
  provisioner "local-exec" {
    command = <<-EOT
      python3 -m sync_config.py -r ${var.region} -t ${aws_dynamodb_table.ami_tracker.name}
    EOT
    working_dir = "${path.module}/scripts"
  }
}

