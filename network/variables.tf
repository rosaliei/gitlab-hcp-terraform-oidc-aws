################################################################################
# VPC
################################################################################
variable "vpc_name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "(Optional) The IPv4 CIDR block for the VPC. CIDR can be explicitly set or it can be derived from IPAM using `ipv4_netmask_length` & `ipv4_ipam_pool_id`"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "vpc_public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "vpc_private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "SINGLE NAT GATEWAY FOR ALL PRIVATE SUBNETS / ALL AZ"
  type        = bool
  default     = true
}
