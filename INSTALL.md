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

To reference this project, create a `module` block in your terraform code and refer to this module by setting the source to `"git::https://github.com/Evernorth/aws-ami-tracker.git//terraform?ref=main"`.

Please see the [example/main.tf](example terraform file) in the examples directory for an easy set-up.  Once you have your local terraform and provider configured properly, you can simply run `terraform init` followed by `terraform apply` to deploy this solution to your AWS account.