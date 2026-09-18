output "vcn_id" {
  description = "VCN para seleccionar en OKE Custom Create."
  value       = oci_core_vcn.oke.id
}

output "kubernetes_api_subnet_id" {
  description = "Subnet privada para el Kubernetes API endpoint."
  value       = oci_core_subnet.api_endpoint.id
}

output "worker_nodes_subnet_id" {
  description = "Subnet privada para managed worker nodes."
  value       = oci_core_subnet.worker_nodes.id
}

output "pods_subnet_id" {
  description = "Subnet privada para OCI VCN-Native Pod Networking CNI."
  value       = oci_core_subnet.pods.id
}

output "load_balancers_subnet_id" {
  description = "Subnet publica para Services de tipo LoadBalancer."
  value       = oci_core_subnet.load_balancers.id
}

output "bastion_subnet_id" {
  description = "Subnet publica llamada bastion para una VM jump host."
  value       = oci_core_subnet.bastion.id
}

output "network_cidrs" {
  description = "Mapa de CIDR creados por el stack."
  value = {
    vcn            = local.vcn_cidr
    api_endpoint   = local.api_endpoint_cidr
    worker_nodes   = local.worker_nodes_cidr
    pods           = local.pods_cidr
    load_balancers = local.load_balancers_cidr
    bastion        = local.bastion_cidr
  }
}

output "custom_create_selection" {
  description = "Resumen de recursos para el wizard OKE Custom Create."
  value = {
    vcn                      = oci_core_vcn.oke.id
    kubernetes_api_endpoint  = oci_core_subnet.api_endpoint.id
    worker_nodes             = oci_core_subnet.worker_nodes.id
    pods_oci_vcn_native_cni  = oci_core_subnet.pods.id
    public_load_balancers    = oci_core_subnet.load_balancers.id
    public_bastion_jump_host = oci_core_subnet.bastion.id
  }
}
