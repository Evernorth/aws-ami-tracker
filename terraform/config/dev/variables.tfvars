environment = "dev" 
required_tags = {
  CostCenter       = "00004706"
  AssetOwner       = "cloudcoe@cigna.com"
  ServiceNowBA     = "BA15820"
  ServiceNowAS     = "AS031482"
  SecurityReviewID = "RITM5183852"
  AppName          = "AmiTracker"
  AssetName        = "AmiTracker"
  BackupOwner      = "cloudcoe@cigna.com"
  Purpose          = "AmiTracker"
}

data_at_rest_tags = {
  ComplianceDataCategory = "none"
  DataSubjectArea        = "it"
  DataClassification     = "internal"
  LineOfBusiness         = "none"
  BusinessEntity         = "none"
  BackupPlan             = "Custom"    
}

lambda_environment = {
}
