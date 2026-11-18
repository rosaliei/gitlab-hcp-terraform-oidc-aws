################################################################################
# customer_profile_ec2
################################################################################

variable "customer_profile_ec2_instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro"
}

variable "customer_profile_ec2_ami_ssm_parameter" {
  description = "SSM parameter name for the AMI ID. For Amazon Linux AMI SSM parameters see [reference](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html)"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

variable "customer_profile_ec2_associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = null
}

variable "customer_profile_ec2_key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
  default     = null
}

variable "customer_profile_ec2_monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = null
}

variable "customer_profile_ec2_name" {
  description = "Names of EC2 instances to create"
  type        = set(string)
  default     = [""]
}

# OPTIONAL
# variable "customer_profile_ec2_availability_zone" {
#   description = "AZ to start the instance in"
#   type        = string
#   default     = null
# }

# variable "customer_profile_ec2_subnet_id" {
#   description = "The VPC Subnet ID to launch in"
#   type        = string
#   default     = null
# }

################################################################################
# account_ec2
################################################################################

variable "account_ec2_instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro"
}

variable "account_ec2_ami_ssm_parameter" {
  description = "SSM parameter name for the AMI ID. For Amazon Linux AMI SSM parameters see [reference](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html)"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

variable "account_ec2_associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = null
}

variable "account_ec2_key_name" {
  description = "Key name of the Key Pair to use for the instance; which can be managed using the `aws_key_pair` resource"
  type        = string
  default     = null
}

variable "account_ec2_monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = null
}

variable "account_ec2_name" {
  description = "Names of EC2 instances to create"
  type        = set(string)
  default     = [""]
}
################################################################################
# Security groups per EC2 (EC2 name => output name from the security workspace)
################################################################################

variable "customer_profile_ec2_security_groups" {
  description = "Map of customer profile EC2 name to security workspace output name"
  type        = map(string)
  default     = {}
}

variable "account_ec2_security_groups" {
  description = "Map of account EC2 name to security workspace output name"
  type        = map(string)
  default     = {}
}
