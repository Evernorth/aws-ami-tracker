module "ami-tracker" {
  source = "git::https://github.com/Evernorth/aws-ami-tracker.git//terraform?ref=main"

  app_name         = "AmiTrackerExample"
  environment      = "dev"
  deploy_alarms    = true
  deploy_alarm_sns = true
  region           = var.region
}