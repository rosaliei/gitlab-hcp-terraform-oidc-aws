################################################################################
# customer_profile_sg
################################################################################

variable "customer_profile_sg_name" {
  description = "Name of security group"
  type        = string
  default     = ""
}

variable "customer_profile_sg_description" {
  description = "Description of security group"
  type        = string
  default     = null
}

variable "customer_profile_sg_vpc_id" {
  description = "ID of the VPC where the security group is created"
  type        = string
  default     = null
}

variable "customer_profile_ingress_rules" {
  description = "Map of ingress rules to add to the security group"
  type = map(object({
    name = optional(string)

    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    source_sg                    = optional(string) # key in local.security_group_ids, e.g. "customer_profile_jump"
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.customer_profile_ingress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id, v.source_sg])) == 1
    ])
    error_message = "Each ingress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, referenced_security_group_id, or source_sg."
  }
}

variable "customer_profile_egress_rules" {
  description = "Map of egress rules to add to the security group"
  type = map(object({
    name = optional(string)

    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.customer_profile_egress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id])) == 1
    ])
    error_message = "Each egress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}

################################################################################
# JUMP MACHINE SECURITY GROUP
################################################################################

variable "customer_profile_jump_sg_name" {
  description = "Name of security group"
  type        = string
  default     = ""
}

variable "customer_profile_jump_sg_description" {
  description = "Description of security group"
  type        = string
  default     = null
}

variable "customer_profile_jump_sg_vpc_id" {
  description = "ID of the VPC where the security group is created"
  type        = string
  default     = null
}

variable "customer_profile_jump_ingress_rules" {
  description = "Map of ingress rules to add to the security group"
  type = map(object({
    name = optional(string)

    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.customer_profile_jump_ingress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id])) == 1
    ])
    error_message = "Each ingress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}

variable "customer_profile_jump_egress_rules" {
  description = "Map of egress rules to add to the security group"
  type = map(object({
    name = optional(string)

    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.customer_profile_jump_egress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id])) == 1
    ])
    error_message = "Each egress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}


################################################################################
# ACCOUNT SECURITY GROUP (Tokyo)
################################################################################

variable "account_sg_name" {
  description = "Name of security group"
  type        = string
  default     = ""
}

variable "account_sg_description" {
  description = "Description of security group"
  type        = string
  default     = null
}

variable "account_ingress_rules" {
  description = "Map of ingress rules to add to the security group"
  type = map(object({
    name = optional(string)

    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.account_ingress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id])) == 1
    ])
    error_message = "Each ingress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}

variable "account_egress_rules" {
  description = "Map of egress rules to add to the security group"
  type = map(object({
    name = optional(string)

    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    description                  = optional(string)
    from_port                    = optional(number)
    ip_protocol                  = optional(string, "tcp")
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.account_egress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id])) == 1
    ])
    error_message = "Each egress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}
