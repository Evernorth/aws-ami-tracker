module "ami-tracker" {
  source = "../terraform"

  app_name         = "AMI-Tracker-Thingy"
  environment      = "dev"
  deploy_alarms    = true
  deploy_alarm_sns = true
  region           = var.region
}