# Stack Resource Manager - VCN para OKE Custom Create

Este stack crea solamente la red requerida para un cluster OKE con:

- OCI VCN-Native Pod Networking CNI.
- Kubernetes API endpoint privado.
- Managed worker nodes privados.
- Pods privados.
- Load balancers publicos.
- Subred regional publica `bastion` para una VM jump host administrada por el usuario.

No crea el cluster OKE, node pools, una instancia Compute ni el servicio OCI Bastion.

## Direccionamiento

| Recurso | CIDR | Acceso | Ruta de salida |
|---|---:|---|---|
| VCN | `172.16.0.0/16` | - | - |
| Kubernetes API endpoint | `172.16.0.0/29` | Privado | NAT + Service Gateway |
| Worker nodes | `172.16.1.0/24` | Privado | NAT + Service Gateway |
| Load balancers | `172.16.2.0/24` | Publico | Internet Gateway |
| `bastion` | `172.16.3.0/24` | Publico | Internet Gateway |
| Pods | `172.16.32.0/19` | Privado | NAT + Service Gateway |

Las subnets son regionales. El stack usa las DHCP Options predeterminadas de la VCN, con Internet and VCN Resolver.

## Flujo de seguridad del bastion

La security list de `bastion` permite:

- Ingreso TCP/22 solamente desde `bastion_ssh_ingress_cidr`.
- Salida TCP/6443 hacia `172.16.0.0/29`.
- Salida TCP/22 hacia los workers privados.
- Salida HTTP/HTTPS para actualizaciones de la futura VM.
- Consultas DNS UDP/TCP 53 al resolver OCI `169.254.169.254`.

La security list del API endpoint permite el ingreso TCP/6443 desde `172.16.3.0/24`. El API endpoint permanece privado y no recibe una IP publica.

## Policies requeridas

Un administrador debe adaptar el nombre del identity domain y del grupo:

```text
Allow group '<identity-domain>'/'DevOps-OKE-Admins' to manage orm-stacks in compartment <workshop-compartment>
Allow group '<identity-domain>'/'DevOps-OKE-Admins' to manage orm-jobs in compartment <workshop-compartment>
Allow group '<identity-domain>'/'DevOps-OKE-Admins' to manage virtual-network-family in compartment <workshop-compartment>
Allow group '<identity-domain>'/'DevOps-OKE-Admins' to inspect compartments in tenancy
```

Los administradores del tenancy ya tienen estos permisos. Resource Manager evalua los permisos del usuario que crea y ejecuta los jobs; este stack no necesita API keys ni variables de credenciales.

## Crear el ZIP en OCI Cloud Shell

Desde la raiz del repositorio:

```bash
bash scripts/package-orm-stack.sh
unzip -l dist/oke-vcn-private-api-resource-manager.zip
```

Los archivos `.tf`, `.terraform.lock.hcl` y `orm_schema.yaml` quedan en la raiz del ZIP, como requiere Resource Manager. Se carga el ZIP completo; no se debe seleccionar la carpeta `terraform/oke-vcn-private-api` en este flujo.

## Version de Terraform en Resource Manager

El stack exige Terraform `>= 1.5.0, < 1.6.0`. Al crear el stack, seleccionar `1.5.x`; actualmente Resource Manager ejecuta esa opcion con Terraform CLI `1.5.7`. Esto evita la actualizacion automatica y la descontinuacion de versiones anteriores a `1.5.x`.

## Crear el stack con el wizard

1. En OCI Console, abrir `Developer Services` > `Resource Manager` > `Stacks`.
2. Seleccionar `Create stack`.
3. Elegir `My configuration` > `.Zip file` y cargar `dist/oke-vcn-private-api-resource-manager.zip`.
4. Seleccionar el compartimento del workshop.
5. En `Terraform version`, seleccionar `1.5.x`.
6. Verificar el nombre y seleccionar `Next`.
7. En `Bastion SSH ingress CIDR`, escribir la IP publica administrativa con `/32`, por ejemplo `203.0.113.10/32`.
8. Mantener `Load balancer ingress CIDR` en `0.0.0.0/0` para el laboratorio o restringirlo a la red del participante.
9. Seleccionar `Next` y revisar la configuracion.
10. Crear el stack sin ejecutar Apply automaticamente.
11. Abrir el stack y ejecutar un job `Plan`.
12. Revisar que el plan cree una VCN, tres gateways, cinco route tables, cinco security lists y cinco subnets.
13. Ejecutar un job `Apply`.
14. Abrir `Outputs` y copiar los OCID.

## Seleccion en OKE Custom Create

En `Developer Services` > `Kubernetes Clusters (OKE)` > `Create cluster` > `Custom Create`:

| Campo del wizard | Output del stack |
|---|---|
| Virtual cloud network | `vcn_id` |
| Kubernetes API endpoint subnet | `kubernetes_api_subnet_id` |
| Assign a public IP address to the API endpoint | Desactivado |
| CNI type | OCI VCN-Native Pod Networking |
| Worker node subnet | `worker_nodes_subnet_id` |
| Pod subnet | `pods_subnet_id` |
| Load balancer subnet | `load_balancers_subnet_id` |

Las security lists ya estan asociadas con cada subnet. No se deben seleccionar security lists adicionales durante la creacion del cluster salvo que exista un requisito corporativo documentado.

## Crear una VM bastion

Despues de aplicar el stack:

1. Abrir `Compute` > `Instances` > `Create instance`.
2. Seleccionar la VCN del output `vcn_id` y la subnet del output `bastion_subnet_id`.
3. Asignar una IPv4 publica.
4. Usar Oracle Linux y cargar una clave SSH publica.
5. No agregar reglas que expongan el puerto 6443 a Internet.
6. Instalar OCI CLI y `kubectl` si se ejecutaran comandos directamente desde la VM.

Para un tunel SSH desde Cloud Shell o una estacion Linux:

```bash
ssh -i ~/.ssh/id_rsa \
  -N \
  -L 6443:<oke-api-private-ip>:6443 \
  opc@<bastion-public-ip>
```

En otra terminal, generar el kubeconfig privado y cambiar temporalmente su servidor a `https://127.0.0.1:6443` antes de ejecutar `kubectl`.

## Reglas implementadas

Las reglas siguen el ejemplo 4 de Oracle para OCI CNI y agregan los requisitos generales actuales de rutas NAT para subnets privadas:

- API ingress desde workers y pods: TCP/6443 y TCP/12250.
- API ingress desde bastion: TCP/6443.
- API egress hacia workers: TCP/10250; hacia pods: todos los protocolos; hacia OCI Services Network.
- Workers ingress desde API: TCP/10250; desde load balancers: TCP y UDP/30000-32767 y TCP/10256.
- Workers egress hacia API: TCP/6443 y TCP/12250; hacia pods, workers, OCI Services Network e Internet mediante NAT.
- Pods ingress desde API, workers y otros pods; egress hacia API, OCI Services Network e Internet TCP/443 mediante NAT.
- Pods egress al resolver OCI por DNS/53 y al Instance Metadata Service por TCP/80 para soportar la autenticacion instance principal del backend.
- Load balancers ingress TCP/80 y TCP/443; egress TCP y UDP/30000-32767 y TCP/10256 hacia workers.
- ICMP type 3 code 4 donde Oracle lo requiere para Path MTU Discovery.

OCI representa los rangos de puertos solamente para TCP o UDP. Por eso las reglas que la documentacion muestra como `ALL/30000-32767` se materializan como reglas TCP y UDP separadas.

## Validacion en Cloud Shell

Terraform viene disponible en OCI Cloud Shell. Antes de cargar el ZIP tambien se puede validar localmente:

```bash
cd terraform/oke-vcn-private-api
terraform version  # debe mostrar 1.5.x para reproducir Resource Manager
terraform init -backend=false -input=false
terraform fmt -check -recursive
terraform validate
cd ../..
```

No ejecutar `terraform apply` desde Cloud Shell si el estado sera administrado por Resource Manager.

## Fuentes

- Oracle OKE example 4: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm#example-oci-cni-privatek8sapi_privateworkers_publiclb
- Network resource configuration: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm
- Resource Manager schema documents: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/terraformconfigresourcemanager_topic-schema.htm
- Resource Manager supported Terraform versions: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Reference/terraformversions.htm
- Creating a stack from a ZIP file: https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-stack-local.htm
