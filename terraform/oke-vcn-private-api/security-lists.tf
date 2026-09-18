resource "oci_core_security_list" "api_endpoint" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-sl-api-endpoint-private"
  freeform_tags  = local.common_tags

  ingress_security_rules {
    protocol    = "6"
    source      = local.worker_nodes_cidr
    source_type = "CIDR_BLOCK"
    description = "Worker nodes to Kubernetes API"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.worker_nodes_cidr
    source_type = "CIDR_BLOCK"
    description = "Worker nodes to OKE control plane"
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    protocol    = "1"
    source      = local.worker_nodes_cidr
    source_type = "CIDR_BLOCK"
    description = "Worker node path MTU discovery"
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.pods_cidr
    source_type = "CIDR_BLOCK"
    description = "Pods to Kubernetes API"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.pods_cidr
    source_type = "CIDR_BLOCK"
    description = "Pods to OKE control plane"
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.bastion_cidr
    source_type = "CIDR_BLOCK"
    description = "Public bastion subnet to private Kubernetes API"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    description      = "Kubernetes API endpoint to OCI services"
  }

  egress_security_rules {
    protocol         = "1"
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    description      = "Kubernetes API endpoint path MTU discovery to OCI services"
    icmp_options {
      type = 3
      code = 4
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.worker_nodes_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Kubernetes API endpoint to kubelet"
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  egress_security_rules {
    protocol         = "1"
    destination      = local.worker_nodes_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Kubernetes API endpoint path MTU discovery to workers"
    icmp_options {
      type = 3
      code = 4
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = local.pods_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Kubernetes API endpoint to VCN-native pods"
  }
}

resource "oci_core_security_list" "worker_nodes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-sl-workers-private"
  freeform_tags  = local.common_tags

  ingress_security_rules {
    protocol    = "all"
    source      = local.worker_nodes_cidr
    source_type = "CIDR_BLOCK"
    description = "Worker node to worker node communication"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = local.pods_cidr
    source_type = "CIDR_BLOCK"
    description = "VCN-native pods to worker nodes"
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.api_endpoint_cidr
    source_type = "CIDR_BLOCK"
    description = "Kubernetes API endpoint to kubelet"
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  ingress_security_rules {
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "Path MTU discovery"
    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.bastion_cidr
    source_type = "CIDR_BLOCK"
    description = "Bastion SSH to managed worker nodes"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.load_balancers_cidr
    source_type = "CIDR_BLOCK"
    description = "Load balancers to TCP NodePorts"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = local.load_balancers_cidr
    source_type = "CIDR_BLOCK"
    description = "Load balancers to UDP NodePorts"
    udp_options {
      min = 30000
      max = 32767
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = local.load_balancers_cidr
    source_type = "CIDR_BLOCK"
    description = "Load balancers to kube-proxy health port"
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = local.worker_nodes_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Worker node to worker node communication"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = local.pods_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Worker nodes to VCN-native pods"
  }

  egress_security_rules {
    protocol         = "1"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Path MTU discovery"
    icmp_options {
      type = 3
      code = 4
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    description      = "Worker nodes to OCI services and OKE"
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.api_endpoint_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Worker nodes to Kubernetes API"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.api_endpoint_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Worker nodes to OKE control plane"
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Worker node internet egress through NAT gateway"
  }

  egress_security_rules {
    protocol         = "17"
    destination      = "169.254.169.254/32"
    destination_type = "CIDR_BLOCK"
    description      = "Worker node DNS queries to OCI VCN resolver"
    udp_options {
      min = 53
      max = 53
    }
  }
}

resource "oci_core_security_list" "pods" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-sl-pods-private"
  freeform_tags  = local.common_tags

  ingress_security_rules {
    protocol    = "all"
    source      = local.worker_nodes_cidr
    source_type = "CIDR_BLOCK"
    description = "Worker nodes to VCN-native pods"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = local.api_endpoint_cidr
    source_type = "CIDR_BLOCK"
    description = "Kubernetes API endpoint to VCN-native pods"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = local.pods_cidr
    source_type = "CIDR_BLOCK"
    description = "Pod to pod communication"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = local.pods_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Pod to pod communication"
  }

  egress_security_rules {
    protocol         = "1"
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    description      = "Pod path MTU discovery to OCI services"
    icmp_options {
      type = 3
      code = 4
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    description      = "Pods to OCI services"
  }

  egress_security_rules {
    protocol         = "17"
    destination      = "169.254.169.254/32"
    destination_type = "CIDR_BLOCK"
    description      = "Pod DNS queries to OCI VCN resolver"
    udp_options {
      min = 53
      max = 53
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "169.254.169.254/32"
    destination_type = "CIDR_BLOCK"
    description      = "Pod TCP DNS fallback to OCI VCN resolver"
    tcp_options {
      min = 53
      max = 53
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "169.254.169.254/32"
    destination_type = "CIDR_BLOCK"
    description      = "Pod access to instance metadata for instance principal authentication"
    tcp_options {
      min = 80
      max = 80
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Pod HTTPS internet egress through NAT gateway"
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.api_endpoint_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Pods to Kubernetes API"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.api_endpoint_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Pods to OKE control plane"
    tcp_options {
      min = 12250
      max = 12250
    }
  }
}

resource "oci_core_security_list" "load_balancers" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-sl-load-balancers-public"
  freeform_tags  = local.common_tags

  ingress_security_rules {
    protocol    = "6"
    source      = var.load_balancer_ingress_cidr
    source_type = "CIDR_BLOCK"
    description = "Public HTTP listeners"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.load_balancer_ingress_cidr
    source_type = "CIDR_BLOCK"
    description = "Public HTTPS listeners"
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.worker_nodes_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Load balancers to TCP NodePorts"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  egress_security_rules {
    protocol         = "17"
    destination      = local.worker_nodes_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Load balancers to UDP NodePorts"
    udp_options {
      min = 30000
      max = 32767
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.worker_nodes_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Load balancers to kube-proxy health port"
    tcp_options {
      min = 10256
      max = 10256
    }
  }
}

resource "oci_core_security_list" "bastion" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.name_prefix}-sl-bastion-public"
  freeform_tags  = local.common_tags

  ingress_security_rules {
    protocol    = "6"
    source      = var.bastion_ssh_ingress_cidr
    source_type = "CIDR_BLOCK"
    description = "Administrative SSH to bastion VM"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "Path MTU discovery"
    icmp_options {
      type = 3
      code = 4
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.api_endpoint_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Bastion VM to private Kubernetes API"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = local.worker_nodes_cidr
    destination_type = "CIDR_BLOCK"
    description      = "Bastion VM SSH to managed worker nodes"
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol         = "17"
    destination      = "169.254.169.254/32"
    destination_type = "CIDR_BLOCK"
    description      = "Bastion VM DNS queries to OCI VCN resolver"
    udp_options {
      min = 53
      max = 53
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "169.254.169.254/32"
    destination_type = "CIDR_BLOCK"
    description      = "Bastion VM TCP DNS fallback to OCI VCN resolver"
    tcp_options {
      min = 53
      max = 53
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Bastion VM HTTP egress for operating system updates"
    tcp_options {
      min = 80
      max = 80
    }
  }

  egress_security_rules {
    protocol         = "6"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Bastion VM HTTPS egress for operating system updates"
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol         = "1"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Bastion VM path MTU discovery"
    icmp_options {
      type = 3
      code = 4
    }
  }
}
