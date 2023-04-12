locals {
  all = setunion(var.leafs, var.spines)
  loopback_map = { for device in local.all : "${device}/${var.loopback_id}" => {
    device         = device
    interface      = var.loopback_id
    interface_name = "lo${var.loopback_id}"
    }
  }
  pim_loopback_map = { for device in var.spines : "${device}/${var.pim_loopback_id}" => {
    device         = device
    interface      = var.pim_loopback_id
    interface_name = "lo${var.pim_loopback_id}"
    }
  }
  vtep_loopback_map = { for device in var.leafs : "${device}/${var.vtep_loopback_id}" => {
    device         = device
    interface      = var.vtep_loopback_id
    interface_name = "lo${var.vtep_loopback_id}"
    }
  }
  leaf_fabric_interface_map = merge([
    for device in var.leafs : {
      for i in range(length(var.spines)) : "${device}/${var.leaf_fabric_interface_prefix}${var.leaf_fabric_interface_offset + i}" => {
        device         = device
        interface      = "${var.leaf_fabric_interface_prefix}${var.leaf_fabric_interface_offset + i}"
        interface_name = "eth${var.leaf_fabric_interface_prefix}${var.leaf_fabric_interface_offset + i}"
      }
    }
  ]...)
  spine_fabric_interface_map = merge([
    for device in var.spines : {
      for i in range(length(var.leafs)) : "${device}/${var.spine_fabric_interface_prefix}${var.spine_fabric_interface_offset + i}" => {
        device         = device
        interface      = "${var.spine_fabric_interface_prefix}${var.spine_fabric_interface_offset + i}"
        interface_name = "eth${var.spine_fabric_interface_prefix}${var.spine_fabric_interface_offset + i}"
      }
    }
  ]...)
  all_interface_map = merge(local.loopback_map, local.pim_loopback_map, local.vtep_loopback_map, local.leaf_fabric_interface_map, local.spine_fabric_interface_map)
}

resource "nxos_system" "system" {
  for_each = local.all

  device = each.value
  name   = each.value
}

resource "nxos_ethernet" "ethernet" {
  for_each = local.all

  device = each.value
  mtu    = 9216
}

module "nxos_features" {
  source  = "netascode/features/nxos"
  version = ">= 0.1.0"

  for_each = local.all

  device            = each.value
  bfd               = true
  bgp               = true
  evpn              = true
  fabric_forwarding = true
  interface_vlan    = true
  nv_overlay        = true
  ospf              = true
  pim               = true
  vn_segment        = true
}

module "nxos_vrf" {
  source  = "netascode/vrf/nxos"
  version = ">= 0.2.0"

  for_each = local.all

  device = each.value
  name   = "default"
}

module "loopback" {
  source  = "netascode/interface-loopback/nxos"
  version = ">= 0.1.2"

  for_each = local.all

  device       = each.value
  id           = var.loopback_id
  admin_state  = true
  ipv4_address = "${[for l in var.loopbacks : l.ipv4_address if l.device == each.value][0]}/32"

  depends_on = [module.nxos_vrf]
}

module "pim_loopback" {
  source  = "netascode/interface-loopback/nxos"
  version = ">= 0.1.2"

  for_each = var.spines

  device       = each.value
  id           = var.pim_loopback_id
  admin_state  = true
  ipv4_address = "${var.anycast_rp_ipv4_address}/32"

  depends_on = [module.nxos_vrf]
}

module "vtep_loopback" {
  source  = "netascode/interface-loopback/nxos"
  version = ">= 0.1.2"

  for_each = var.leafs

  device       = each.value
  id           = var.vtep_loopback_id
  admin_state  = true
  ipv4_address = "${[for l in var.vtep_loopbacks : l.ipv4_address if l.device == each.value][0]}/32"

  depends_on = [module.nxos_vrf]
}

module "leaf_fabric_interface" {
  source  = "netascode/interface-ethernet/nxos"
  version = ">= 0.1.1"

  for_each = local.leaf_fabric_interface_map

  device        = each.value.device
  id            = each.value.interface
  layer3        = true
  medium        = "p2p"
  ip_unnumbered = "lo${var.loopback_id}"

  depends_on = [module.nxos_vrf]
}

module "spine_fabric_interface" {
  source  = "netascode/interface-ethernet/nxos"
  version = ">= 0.1.1"

  for_each = local.spine_fabric_interface_map

  device        = each.value.device
  id            = each.value.interface
  layer3        = true
  medium        = "p2p"
  ip_unnumbered = "lo${var.loopback_id}"

  depends_on = [module.nxos_vrf]
}

module "nxos_ospf" {
  source  = "netascode/ospf/nxos"
  version = ">= 0.2.0"

  for_each = local.all

  device = each.value
  name   = "1"
  vrfs = [
    {
      vrf       = "default"
      router_id = [for l in var.loopbacks : l.ipv4_address if l.device == each.value][0]
      areas = [
        {
          area = "0.0.0.0"
        }
      ]
      interfaces = [for int in local.all_interface_map :
        {
          interface    = int.interface_name
          area         = "0.0.0.0"
          network_type = "p2p"
        } if int.device == each.value
      ]
    }
  ]

  depends_on = [module.nxos_features, module.nxos_vrf]
}

module "nxos_pim" {
  source  = "netascode/pim/nxos"
  version = ">= 0.2.0"

  for_each = local.all

  device = each.value
  vrfs = [
    {
      name = "default"
      rps = [
        {
          address = var.anycast_rp_ipv4_address
        }
      ]
      anycast_rp_local_interface  = "lo${var.loopback_id}"
      anycast_rp_source_interface = "lo${var.loopback_id}"
      anycast_rps = [for spine in var.spines :
        {
          address     = var.anycast_rp_ipv4_address
          set_address = [for l in var.loopbacks : l.ipv4_address if l.device == spine][0]
        } if spine != each.value
      ]
      interfaces = [for int in local.all_interface_map :
        {
          interface   = int.interface_name
          sparse_mode = true
        } if int.device == each.value
      ]
    }
  ]

  depends_on = [module.nxos_features, module.nxos_vrf]
}
