variable "profile" {
  type    = string
  default = "saml"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  description = "Environment of the deployment"
  type        = string
  default     = ""
}

variable "app_name" {
  type    = string
  default = "AmiTracker"
}

variable "lambda_environment" {
  type = map(string)
  default = {
    LOG_LEVEL                   = "INFO" #set to ERROR in PROD
    POWERTOOLS_SERVICE_NAME     = "AmiTracker"
    POWERTOOLS_LOGGER_LOG_EVENT = true #remove or set false for PROD
  }
}

variable "ami_tracker_queuer_event_rule" {
  type    = string
  default = "rate(24 hours)"
}

variable "custom_alarm_sns" {
  type    = string
  default = ""
}

variable "deploy_alarm_sns" {
  type    = bool
  default = false
}

variable "deploy_alarms" {
  type    = bool
  default = false
}