locals {
  vcn_cidr            = "172.16.0.0/16"
  api_endpoint_cidr   = "172.16.0.0/29"
  worker_nodes_cidr   = "172.16.1.0/24"
  load_balancers_cidr = "172.16.2.0/24"
  bastion_cidr        = "172.16.3.0/24"
  pods_cidr           = "172.16.32.0/19"

  common_tags = {
    project = "DevOps-OKE"
    purpose = "OKE custom cluster network"
  }
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_vcn" "oke" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [local.vcn_cidr]
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = var.vcn_dns_label
  freeform_tags  = local.common_tags
}

resource "oci_core_internet_gateway" "oke" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-internet-gateway"
  enabled        = true
  freeform_tags  = local.common_tags
}

resource "oci_core_nat_gateway" "oke" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-nat-gateway"
  block_traffic  = false
  freeform_tags  = local.common_tags
}

resource "oci_core_service_gateway" "oke" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-service-gateway"
  freeform_tags  = local.common_tags

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

resource "oci_core_route_table" "api_endpoint" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-rt-api-endpoint-private"
  freeform_tags  = local.common_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke.id
    description       = "Private API endpoint egress through NAT gateway"
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oke.id
    description       = "Private API endpoint access to OCI services"
  }
}

resource "oci_core_route_table" "worker_nodes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-rt-workers-private"
  freeform_tags  = local.common_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke.id
    description       = "Private worker node egress through NAT gateway"
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oke.id
    description       = "Private worker node access to OCI services"
  }
}

resource "oci_core_route_table" "pods" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-rt-pods-private"
  freeform_tags  = local.common_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke.id
    description       = "Private pod egress through NAT gateway"
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oke.id
    description       = "Private pod access to OCI services"
  }
}

resource "oci_core_route_table" "load_balancers" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-rt-load-balancers-public"
  freeform_tags  = local.common_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke.id
    description       = "Public load balancer internet route"
  }
}

resource "oci_core_route_table" "bastion" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-rt-bastion-public"
  freeform_tags  = local.common_tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke.id
    description       = "Public bastion internet route"
  }
}

resource "oci_core_subnet" "api_endpoint" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke.id
  cidr_block                 = local.api_endpoint_cidr
  display_name               = "${var.name_prefix}-api-endpoint-private"
  dns_label                  = "apiendpoint"
  route_table_id             = oci_core_route_table.api_endpoint.id
  security_list_ids          = [oci_core_security_list.api_endpoint.id]
  dhcp_options_id            = oci_core_vcn.oke.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
  freeform_tags              = local.common_tags
}

resource "oci_core_subnet" "worker_nodes" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke.id
  cidr_block                 = local.worker_nodes_cidr
  display_name               = "${var.name_prefix}-workers-private"
  dns_label                  = "workers"
  route_table_id             = oci_core_route_table.worker_nodes.id
  security_list_ids          = [oci_core_security_list.worker_nodes.id]
  dhcp_options_id            = oci_core_vcn.oke.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
  freeform_tags              = local.common_tags
}

resource "oci_core_subnet" "pods" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke.id
  cidr_block                 = local.pods_cidr
  display_name               = "${var.name_prefix}-pods-private"
  dns_label                  = "pods"
  route_table_id             = oci_core_route_table.pods.id
  security_list_ids          = [oci_core_security_list.pods.id]
  dhcp_options_id            = oci_core_vcn.oke.default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
  freeform_tags              = local.common_tags
}

resource "oci_core_subnet" "load_balancers" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke.id
  cidr_block                 = local.load_balancers_cidr
  display_name               = "${var.name_prefix}-load-balancers-public"
  dns_label                  = "loadbalancers"
  route_table_id             = oci_core_route_table.load_balancers.id
  security_list_ids          = [oci_core_security_list.load_balancers.id]
  dhcp_options_id            = oci_core_vcn.oke.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
  freeform_tags              = local.common_tags
}

resource "oci_core_subnet" "bastion" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.oke.id
  cidr_block                 = local.bastion_cidr
  display_name               = "bastion"
  dns_label                  = "bastion"
  route_table_id             = oci_core_route_table.bastion.id
  security_list_ids          = [oci_core_security_list.bastion.id]
  dhcp_options_id            = oci_core_vcn.oke.default_dhcp_options_id
  prohibit_public_ip_on_vnic = false
  freeform_tags              = local.common_tags
}
