variable "compartment_ocid" {
  description = "OCID del compartimento donde se crean los recursos de red."
  type        = string
}

variable "region" {
  description = "Region OCI donde se despliega la VCN."
  type        = string
}

variable "name_prefix" {
  description = "Prefijo para los nombres de los recursos."
  type        = string
  default     = "devops-oke"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{1,29}$", var.name_prefix))
    error_message = "name_prefix debe iniciar con una letra y contener entre 2 y 30 caracteres alfanumericos o guiones."
  }
}

variable "vcn_dns_label" {
  description = "DNS label de la VCN. Debe ser unico en la region para el tenancy."
  type        = string
  default     = "devopsoke"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,14}$", var.vcn_dns_label))
    error_message = "vcn_dns_label debe iniciar con una letra minuscula y tener maximo 15 caracteres alfanumericos."
  }
}

variable "bastion_ssh_ingress_cidr" {
  description = "CIDR publico autorizado para SSH a una futura VM bastion. Use una IP /32 siempre que sea posible."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.bastion_ssh_ingress_cidr))
    error_message = "bastion_ssh_ingress_cidr debe ser un CIDR IPv4 valido, por ejemplo 203.0.113.10/32."
  }
}

variable "load_balancer_ingress_cidr" {
  description = "CIDR autorizado para acceder a los listeners HTTP/HTTPS de los load balancers publicos."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrnetmask(var.load_balancer_ingress_cidr))
    error_message = "load_balancer_ingress_cidr debe ser un CIDR IPv4 valido."
  }
}
