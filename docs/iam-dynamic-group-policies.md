# IAM, Dynamic Group y Policies

Este workshop cambia el backend de API Key a instance principal. En OKE con managed nodes, el principal efectivo es la instancia Compute del worker node donde corre el pod. Por eso la autorizacion se da con un dynamic group sobre los worker nodes y una policy para OCI Generative AI.

Referencias oficiales:

- OCI SDK authentication methods: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdk_authentication_methods.htm
- Calling services from an instance: https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/callingservicesfrominstances.htm
- IAM policies for OCI Generative AI: https://docs.oracle.com/en-us/iaas/Content/generative-ai/iam-policies.htm
- OKE policy configuration: https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengpolicyconfig.htm
- OCIR repository access policies: https://docs.oracle.com/en-us/iaas/Content/Registry/Concepts/registrypolicyrepoaccess.htm

## 1. Grupo para operadores del workshop

Si los participantes no son Administrators, crear un grupo, por ejemplo:

```text
DevOps-OKE-Admins
```

Policies minimas para crear OKE con Quick Create, crear repositorios en OCIR y desplegar la app:

```text
Allow group DevOps-OKE-Admins to manage cluster-family in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage instance-family in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage virtual-network-family in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage volume-family in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to use subnets in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to use vnics in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to use private-ips in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage public-ips in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to inspect compartments in tenancy
Allow group DevOps-OKE-Admins to use cloud-shell in tenancy
Allow group DevOps-OKE-Admins to manage repos in compartment <workshop-compartment>
```

Para Quick Create, OCI documenta permisos adicionales de red cuando el wizard crea VCN, subnets, gateways, route tables y security lists automaticamente. Si la tenancy usa politicas muy restrictivas, agregar:

```text
Allow group DevOps-OKE-Admins to manage vcns in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage subnets in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage internet-gateways in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage nat-gateways in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage route-tables in compartment <workshop-compartment>
Allow group DevOps-OKE-Admins to manage security-lists in compartment <workshop-compartment>
```

## 2. Dynamic group para worker nodes OKE

Nombre sugerido:

```text
dg-devops-oke-workers
```

Regla simple para un compartimento dedicado al workshop:

```text
ALL {instance.compartment.id = '<worker-node-compartment-ocid>'}
```

Si el compartimento es compartido, usar una regla mas precisa. Dos opciones practicas:

```text
ANY {instance.id = '<worker-node-1-ocid>', instance.id = '<worker-node-2-ocid>'}
```

O separar los worker nodes del workshop en un compartimento dedicado.

## 3. Policy para OCI Generative AI por instance principal

Crear esta policy en la tenancy o en el compartimento del servicio de Generative AI:

```text
Allow dynamic-group dg-devops-oke-workers to use generative-ai-family in compartment <genai-compartment>
```

Para un entorno de laboratorio, `generative-ai-family` simplifica el ejercicio. En produccion, revisar permisos por recurso individual, por ejemplo `generative-ai-chat`, segun el modelo y el servicio utilizado.

## 4. Consideraciones de seguridad

- No subir archivos `*.pem`, `oci/config` ni auth tokens al repositorio.
- El backend ya no necesita `user`, `fingerprint`, `key_file` ni `tenancy` en disco.
- Cualquier usuario con acceso al worker node hereda los permisos del instance principal; limitar SSH y acceso administrativo al node pool.
- Destruir el cluster al terminar el workshop si no se requiere persistencia.