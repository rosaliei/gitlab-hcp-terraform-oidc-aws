################################################################################
# customer_profile_vpc
################################################################################

customer_profile_vpc_name = "customer_profile_vpc"
customer_profile_vpc_cidr = "10.0.0.0/16"
customer_profile_vpc_azs = [
  "ap-southeast-1a",
  "ap-southeast-1b",
  "ap-southeast-1c",
]

customer_profile_vpc_public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24",
]

customer_profile_vpc_private_subnets = [
  "10.0.201.0/24",
  "10.0.202.0/24",
  "10.0.203.0/24",
]

################################################################################
# account_vpc
################################################################################
account_vpc_name = "account_vpc"

account_vpc_cidr = "172.16.0.0/16"

# Confirm these AZ names are available in your AWS account.
account_vpc_azs = [
  "ap-northeast-1a",
  "ap-northeast-1c",
  "ap-northeast-1d",
]

account_vpc_public_subnets = [
  "172.16.1.0/24",
  "172.16.2.0/24",
  "172.16.3.0/24",
]

account_vpc_private_subnets = [
  "172.16.201.0/24",
  "172.16.202.0/24",
  "172.16.203.0/24",
]