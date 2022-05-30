output "loopback_id" {
  description = "Loopback ID used for OSPF and PIM."
  value       = length([for lo in module.loopback : lo.id]) > 0 ? [for lo in module.loopback : lo.id][0] : null
}

output "pim_loopback_id" {
  description = "Loopback ID used for PIM Anycast RP."
  value       = length([for lo in module.pim_loopback : lo.id]) > 0 ? [for lo in module.pim_loopback : lo.id][0] : null
}

output "vtep_loopback_id" {
  description = "Loopback ID used for VTEP loopbacks."
  value       = length([for lo in module.vtep_loopback : lo.id]) > 0 ? [for lo in module.vtep_loopback : lo.id][0] : null
}

output "loopbacks" {
  description = "List of loopback interfaces, one per device."
  value = [for lo in module.loopback : {
    device       = lo.device
    ipv4_address = lo.ipv4_address
  }]
}

output "vtep_loopbacks" {
  description = "List of vtep loopback interfaces, one per leaf."
  value = [for lo in module.vtep_loopback : {
    device       = lo.device
    ipv4_address = lo.ipv4_address
  }]
}
