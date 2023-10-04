# Installation / Usage Instructions

## Machine / Container Image Prequisites

The following packages should be installed on your development machine or CI/CD runner.

- Amazon Web Services Account (with CLI access)
- Terraform version 1.3 or later
- Python 3.9 or later (aliased to python3)
- Python Packages
    - boto3
    - pyyaml

## Example

Please see the [example/main.tf](example terraform file) in the examples directory for an easy set-up.  Once you have your local terraform and provider configured properly, you can simply run `terraform init` followed by `terraform apply` to deploy this solution to your AWS account.