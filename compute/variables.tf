################################################################################
# EC2 (settings shared by all servers)
################################################################################

variable "ami_ssm_parameter" {
  description = "SSM parameter name for the AMI ID"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "key_name" {
  description = "Key pair name used by all servers"
  type        = string
  default     = null
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

################################################################################
# Servers to create (name => settings)
################################################################################

variable "ec2s" {
  description = "Servers to create. subnet is public or private, security_group is an output name from the security workspace"
  type = map(object({
    role           = string
    instance_type  = string
    subnet         = string # "public" or "private"
    subnet_index   = number # 0, 1 or 2 (which AZ)
    public_ip      = bool
    security_group = string
    disk_size      = number
  }))
  default = {}
}
