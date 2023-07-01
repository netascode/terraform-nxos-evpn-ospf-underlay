terraform {
  required_version = ">= 1.1.0"

  required_providers {
    iosxe = {
      source  = "CiscoDevNet/nxos"
      version = ">= 0.5.0"
    }
  }
}
