variable "leafs" {
  description = "List of leaf device names. This list of devices must also be added to the provider configuration."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "spines" {
  description = "List of spine device names. This list of devices must also be added to the provider configuration."
  type        = set(string)
  default     = []
  nullable    = false
}

variable "loopback_id" {
  description = "Loopback ID used for OSPF and PIM."
  type        = number
  default     = 0
  nullable    = false

  validation {
    condition     = var.loopback_id >= 0 && var.loopback_id <= 2147483647
    error_message = "`Must be a value between `0` and `2147483647`."
  }
}

variable "pim_loopback_id" {
  description = "Loopback ID used for PIM Anycast RP."
  type        = number
  default     = 100
  nullable    = false

  validation {
    condition     = var.pim_loopback_id >= 0 && var.pim_loopback_id <= 2147483647
    error_message = "`Must be a value between `0` and `2147483647`."
  }
}

variable "loopbacks" {
  description = "List of loopback interfaces, one per device."
  type = list(object({
    device       = string
    ipv4_address = string
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for v in var.loopbacks : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", v.ipv4_address))
    ])
    error_message = "`ipv4_address`: Allowed formats are: `192.168.1.1`."
  }
}

variable "vtep_loopback_id" {
  description = "Loopback ID used for VTEP loopbacks."
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.vtep_loopback_id >= 0 && var.vtep_loopback_id <= 2147483647
    error_message = "`Must be a value between `0` and `2147483647`."
  }
}

variable "vtep_loopbacks" {
  description = "List of vtep loopback interfaces, one per leaf."
  type = list(object({
    device       = string
    ipv4_address = string
  }))
  default  = []
  nullable = false

  validation {
    condition = alltrue([
      for v in var.vtep_loopbacks : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", v.ipv4_address))
    ])
    error_message = "`ipv4_address`: Allowed formats are: `192.168.1.1`."
  }
}

variable "leaf_fabric_interface_prefix" {
  description = "Interface prefix for leaf interfaces, eg. `1/`."
  type        = string
  default     = "1/"
  nullable    = false
}

variable "spine_fabric_interface_prefix" {
  description = "Interface prefix for spine interfaces, eg. `1/`."
  type        = string
  default     = "1/"
  nullable    = false
}

variable "leaf_fabric_interface_offset" {
  description = "Leaf interface index offset for fabric interfaces."
  type        = string
  default     = "1"
  nullable    = false

  validation {
    condition     = var.leaf_fabric_interface_offset >= 0
    error_message = "`Interface offset must be greater than or equal to `0`."
  }
}

variable "spine_fabric_interface_offset" {
  description = "Spine interface index offset for fabric interfaces."
  type        = string
  default     = "1"
  nullable    = false

  validation {
    condition     = var.spine_fabric_interface_offset >= 0
    error_message = "`Interface offset must be greater than or equal to `0`."
  }
}

variable "anycast_rp_ipv4_address" {
  description = "IPv4 address of PIM RP loopback interface (Anycast)."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", var.anycast_rp_ipv4_address))
    error_message = "`Allowed formats are: `192.168.1.1`."
  }
}
