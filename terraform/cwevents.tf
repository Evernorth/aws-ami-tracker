resource "aws_cloudwatch_event_rule" "ami_tracker_queuer_event_rule" {
  name                = "ami_tracker_queuer_event_rule"
  schedule_expression = var.ami_tracker_queuer_event_rule
}

resource "aws_cloudwatch_event_target" "ami_tracker_queuer_event_rule_target" {
  rule = aws_cloudwatch_event_rule.ami_tracker_queuer_event_rule.name
  arn  = aws_lambda_function.ami_tracker_queuer.arn
}