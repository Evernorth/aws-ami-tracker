module "ami-tracker" {
  source = "../terraform"

  app_name         = "AmiTrackerExample"
  environment      = "dev"
  deploy_alarms    = true
  deploy_alarm_sns = true
  region           = var.region
}