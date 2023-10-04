locals {
  ami_tracker_queuer_package = "ami_tracker_queuer.zip"
  ami_tracker_lookup_package = "ami_tracker_lookup.zip"
  queuer_env = merge(
    { for key, value in var.lambda_environment : key => value },
    { "QUEUE_URL" : aws_sqs_queue.ami_tracker_lookup_queue.url },
    { "DYNAMODB_TABLE_NAME" : aws_dynamodb_table.ami_tracker.name },
  { "REGION" : var.region })
  lookup_env = merge(
    { for key, value in var.lambda_environment : key => value },
    { "SNS_TOPIC_ARN" : aws_sns_topic.ami_tracker_ami_notification.arn },
    { "DYNAMODB_TABLE_NAME" : aws_dynamodb_table.ami_tracker.name },
  { "REGION" : var.region })
}

data "archive_file" "ami_tracker_queuer_lambda" {
  type        = "zip"
  source_file = "../lambdas/ami_tracker_queuer/main.py"
  output_path = local.ami_tracker_queuer_package
}

data "archive_file" "ami_tracker_lookup_lambda" {
  type        = "zip"
  source_file = "../lambdas/ami_tracker_lookup/main.py"
  output_path = local.ami_tracker_lookup_package
}

resource "aws_lambda_function" "ami_tracker_queuer" {
  filename         = local.ami_tracker_queuer_package
  function_name    = "ami-tracker-queuer"
  role             = aws_iam_role.ami_tracker_queuer_role.arn
  handler          = "main.handler"
  timeout          = 180
  memory_size      = 150
  source_code_hash = data.archive_file.ami_tracker_queuer_lambda.output_base64sha256
  layers           = ["arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:45"]
  runtime          = "python3.9"

  dynamic "environment" {
    for_each = length(keys(local.queuer_env)) == 0 ? [] : [true]
    content {
      variables = local.queuer_env
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_trigger_ami_tracker_queuer" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ami_tracker_queuer.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ami_tracker_queuer_event_rule.arn
}

resource "aws_lambda_event_source_mapping" "ami_tracker_lookup_sqs_trigger" {
  event_source_arn = aws_sqs_queue.ami_tracker_lookup_queue.arn
  function_name    = aws_lambda_function.ami_tracker_lookup.arn
  batch_size       = 1
}

resource "aws_lambda_function" "ami_tracker_lookup" {
  filename         = local.ami_tracker_lookup_package
  function_name    = "ami-tracker-lookup"
  role             = aws_iam_role.ami_tracker_lookup_role.arn
  handler          = "main.handler"
  timeout          = 180
  memory_size      = 150
  source_code_hash = data.archive_file.ami_tracker_lookup_lambda.output_base64sha256
  layers           = ["arn:aws:lambda:${var.region}:017000801446:layer:AWSLambdaPowertoolsPythonV2:45"]
  runtime          = "python3.9"
  dynamic "environment" {
    for_each = length(keys(local.lookup_env)) == 0 ? [] : [true]
    content {
      variables = local.lookup_env
    }
  }
}