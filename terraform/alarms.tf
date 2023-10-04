locals {
  alarm_action = length(var.custom_alarm_sns) > 0 ? var.custom_alarm_sns : aws_sns_topic.ami_tracker_ami_alarm[0].arn
}

resource "aws_cloudwatch_metric_alarm" "ami-tracker-queuer-lambda-failures" {
  count               = var.deploy_alarms ? 1 : 0
  alarm_name          = "ami-tracker-queuer-lambda-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  alarm_description   = "${var.environment} | INFO | ${var.app_name} | AMI Tracker Queuer Lambda - Failed"
  alarm_actions       = [local.alarm_action]
  treat_missing_data  = "notBreaching"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Maximum"
  dimensions = {
    FunctionName = aws_lambda_function.ami_tracker_queuer.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "ami-tracker-lookup-lambda-failures" {
  count               = var.deploy_alarms ? 1 : 0
  alarm_name          = "ami-tracker-lookup-lambda-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  alarm_description   = "${var.environment} | INFO | ${var.app_name} | AMI Tracker Lookup Lambda - Failed"
  alarm_actions       = [local.alarm_action]
  treat_missing_data  = "notBreaching"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Maximum"
  dimensions = {
    FunctionName = aws_lambda_function.ami_tracker_lookup.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "ami-tracker-dlq-alarm" {
  count               = var.deploy_alarms ? 1 : 0
  alarm_name          = "ami-tracker-dlq-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  alarm_description   = "${var.environment} | INFO | ${var.app_name} | ami-tracker-dlq has messages in the queue!"
  alarm_actions       = [local.alarm_action]
  treat_missing_data  = "notBreaching"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 900
  statistic           = "Sum"
  dimensions = {
    QueueName = aws_sqs_queue.ami_tracker_lookup_dlq.name
  }
}