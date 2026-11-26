################################################################################
# nginx_sg
################################################################################

variable "nginx_sg_name" {
  description = "Name of security group"
  type        = string
  default     = ""
}

variable "nginx_sg_description" {
  description = "Description of security group"
  type        = string
  default     = null
}

variable "nginx_sg_vpc_id" {
  description = "ID of the VPC where the security group is created"
  type        = string
  default     = null
}

variable "nginx_ingress_rules" {
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
    source_sg                    = optional(string) # key in local.security_group_ids, e.g. "jump"
    tags                         = optional(map(string), {})
    to_port                      = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.nginx_ingress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id, v.source_sg])) == 1
    ])
    error_message = "Each ingress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, referenced_security_group_id, or source_sg."
  }
}

variable "nginx_egress_rules" {
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
      for k, v in var.nginx_egress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id])) == 1
    ])
    error_message = "Each egress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}

################################################################################
# JUMP MACHINE SECURITY GROUP
################################################################################

variable "jump_sg_name" {
  description = "Name of security group"
  type        = string
  default     = ""
}

variable "jump_sg_description" {
  description = "Description of security group"
  type        = string
  default     = null
}

variable "jump_sg_vpc_id" {
  description = "ID of the VPC where the security group is created"
  type        = string
  default     = null
}

variable "jump_ingress_rules" {
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
      for k, v in var.jump_ingress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id])) == 1
    ])
    error_message = "Each ingress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}

variable "jump_egress_rules" {
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
      for k, v in var.jump_egress_rules :
      length(compact([v.cidr_ipv4, v.cidr_ipv6, v.prefix_list_id, v.referenced_security_group_id])) == 1
    ])
    error_message = "Each egress rule must set exactly one of cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}
