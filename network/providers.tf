# AWS credentials come from HCP Terraform dynamic credentials (OIDC).
# Set these as environment variables on the HCP Terraform workspace:
#   TFC_AWS_PROVIDER_AUTH = true
#   TFC_AWS_RUN_ROLE_ARN  = arn:aws:iam::<account-id>:role/<hcp-terraform-role>
# No profile or access keys are needed here.

provider "aws" {
  alias  = "singapore"
  region = "ap-southeast-1"
}

# TEMPORARY: only to delete the old account VPC in Tokyo. Remove after one apply.
provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}
