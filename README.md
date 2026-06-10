# DevOps-OKE Workshop

Workshop para desplegar dos microservicios en Oracle Kubernetes Engine (OKE) usando OCI Cloud Shell como terminal principal:

- `backend-ai`: API FastAPI que invoca OCI Generative AI usando instance principal.
- `frontend-ai`: interfaz Streamlit que consume el backend dentro del cluster.

El flujo completo cubre clone del repositorio en Cloud Shell, build de imagenes con `docker`/`podman`, push a OCIR, creacion del cluster OKE con wizard de consola, IAM con dynamic group y policies, despliegue en Kubernetes y validacion.

## Referencias oficiales usadas

- OCI Cloud Shell: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cloudshellintro.htm
- Using Cloud Shell with OKE: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/devcloudshellgettingstarted.htm
- OCI SDK authentication methods: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdk_authentication_methods.htm
- Calling services from an instance: https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/callingservicesfrominstances.htm
- Creating Kubernetes clusters using Console workflows: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm
- Setting up cluster access: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengdownloadkubeconfigfile.htm
- Creating an OCIR repository: https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrycreatingarepository.htm
- Pushing images to OCIR with Docker CLI: https://docs.oracle.com/en-us/iaas/Content/Registry/Tasks/registrypushingimagesusingthedockercli.htm
- Pulling images from OCIR during OKE deployment: https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengpullingimagesfromocir.htm
- IAM policies for OCI Generative AI: https://docs.oracle.com/en-us/iaas/Content/generative-ai/iam-policies.htm

## Estructura del repositorio

```text
DevOps-OKE/
  APP-DEMO/
    app/backend/        # FastAPI + OCI SDK con instance principal
    app/frontend/       # Streamlit UI
    k8s/                # Template Kubernetes
  docs/
    iam-dynamic-group-policies.md
    repository-setup.md
  scripts/
    build-and-push.sh
    create-ocir-repositories.sh
    render-k8s-manifest.sh
```

## Prerrequisitos

- Acceso a OCI Console y permiso para usar Cloud Shell: `allow group <group-name> to use cloud-shell in tenancy`.
- Usuario OCI con permisos para crear OKE, OCIR, dynamic groups y policies.
- Auth token OCI para `docker login` contra OCIR.
- Compartimento dedicado recomendado para el workshop.
- Cloud Shell con acceso a internet si el repositorio se clonara desde GitHub.

Cloud Shell ya trae OCI CLI preautenticado, Git, Python, `kubectl`, `helm`, `podman` y un alias `docker` compatible con `podman`. No se requiere configurar OCI CLI localmente.

## Paso 0 - Abrir Cloud Shell y clonar el repositorio

1. En OCI Console, seleccionar la region del workshop.
2. Abrir Cloud Shell desde el icono superior de la consola.
3. Verificar acceso OCI:

```bash
oci os ns get
oci iam region-subscription list --query 'data[]."region-name"'
```

4. Clonar el repositorio:

```bash
git clone https://github.com/JohnContrerasDiaz/DevOps-OKE.git
cd DevOps-OKE
```

Si el repositorio es privado, usar el mecanismo de autenticacion GitHub aprobado para el workshop. No poner tokens dentro del repositorio ni dentro de URLs versionadas.

## Variables del workshop

Definir estos valores en Cloud Shell antes de ejecutar comandos:

```bash
export OCI_REGION="us-chicago-1"
export OCIR_REGION_KEY="ord"                         # ejemplo: iad, phx, gru, bog, ord
export TENANCY_NAMESPACE="$(oci os ns get --query data --raw-output)"
export WORKSHOP_COMPARTMENT_OCID="<compartment-ocid>"
export WORKSHOP_COMPARTMENT_NAME="<compartment-name>"
export OCI_USERNAME="<identity-domain>/<user-email>" # ejemplo: oracleidentitycloudservice/user@company.com
export OCI_GENAI_MODEL_ID="meta.llama-4-maverick-17b-128e-instruct-fp8"
export REPOSITORY_PREFIX="devops-oke"
export TAG="1.0.0"
```

No exportar el auth token en archivos. Para la sesion interactiva, leerlo de forma oculta:

```bash
read -rsp "OCI Auth Token: " OCI_AUTH_TOKEN; echo
```

## Paso 1 - IAM base para operadores

En Console:

1. Abrir `Identity & Security`.
2. Crear o reutilizar el grupo `DevOps-OKE-Admins`.
3. Crear una policy en la tenancy o compartimento del workshop.
4. Copiar las policies de `docs/iam-dynamic-group-policies.md` y reemplazar los placeholders.

Estas policies permiten que los participantes creen OKE, usen Cloud Shell, creen repositorios OCIR y administren recursos de red necesarios por el wizard Quick Create.

## Paso 2 - Crear repositorios OCIR

Opcion por wizard:

1. Abrir `Developer Services` > `Containers & Artifacts` > `Container Registry`.
2. Seleccionar el compartimento del workshop.
3. Crear repositorio privado `devops-oke/backend`.
4. Crear repositorio privado `devops-oke/frontend`.

Opcion por OCI CLI desde Cloud Shell:

```bash
bash scripts/create-ocir-repositories.sh
```

## Paso 3 - Login a OCIR desde Cloud Shell

El usuario de Docker contra OCIR usa el formato `<namespace>/<username>`. En usuarios federados, incluir el identity domain, por ejemplo `<namespace>/oracleidentitycloudservice/user@company.com`.

```bash
printf '%s' "$OCI_AUTH_TOKEN" | docker login "${OCIR_REGION_KEY}.ocir.io" \
  --username "${TENANCY_NAMESPACE}/${OCI_USERNAME}" \
  --password-stdin
```

En Cloud Shell, `docker` es un wrapper compatible sobre `podman`. Si se prefiere usar `podman` directamente:

```bash
printf '%s' "$OCI_AUTH_TOKEN" | podman login "${OCIR_REGION_KEY}.ocir.io" \
  --username "${TENANCY_NAMESPACE}/${OCI_USERNAME}" \
  --password-stdin
```

## Paso 4 - Construir y publicar imagenes

```bash
bash scripts/build-and-push.sh
```

El script publica:

```text
<region-key>.ocir.io/<namespace>/devops-oke/backend:1.0.0
<region-key>.ocir.io/<namespace>/devops-oke/frontend:1.0.0
```

Definir las imagenes para el despliegue:

```bash
export BACKEND_IMAGE="${OCIR_REGION_KEY}.ocir.io/${TENANCY_NAMESPACE}/${REPOSITORY_PREFIX}/backend:${TAG}"
export FRONTEND_IMAGE="${OCIR_REGION_KEY}.ocir.io/${TENANCY_NAMESPACE}/${REPOSITORY_PREFIX}/frontend:${TAG}"
```

## Paso 5 - Crear cluster OKE con wizard

Ruta en Console:

1. Abrir `Developer Services` > `Kubernetes Clusters (OKE)`.
2. Seleccionar `Create cluster`.
3. Elegir `Quick Create` para el workshop.
4. Nombre: `oke-devops-workshop`.
5. Compartimento: el compartimento del workshop.
6. Kubernetes version: usar la version default recomendada por OCI.
7. Visibilidad de API endpoint: publica para laboratorio simple; privada si se usara Bastion/VPN.
8. Worker nodes: managed nodes, 2 nodos, shape economico disponible para el tenancy.
9. Crear el cluster y esperar a que el node pool quede `Active`.

Quick Create crea automaticamente recursos de red regionales para API endpoint, worker nodes y load balancers. Para escenarios corporativos, usar `Custom Create` y seleccionar VCN/subnets existentes.

## Paso 6 - Crear dynamic group para instance principal

Cuando los worker nodes existan, crear el dynamic group en `Identity & Security` > `Domains` > dominio usado > `Dynamic groups`.

Nombre sugerido:

```text
dg-devops-oke-workers
```

Para compartimento dedicado:

```text
ALL {instance.compartment.id = '<worker-node-compartment-ocid>'}
```

Luego crear la policy:

```text
Allow dynamic-group dg-devops-oke-workers to use generative-ai-family in compartment <genai-compartment>
```

Esperar unos minutos a que IAM propague los cambios.

## Paso 7 - Descargar kubeconfig en Cloud Shell

1. Abrir el cluster en OKE.
2. Acciones > `Access cluster`.
3. Elegir `Cloud Shell Access`.
4. Ejecutar en Cloud Shell el comando `oci ce cluster create-kubeconfig` que muestra el wizard.
5. Validar:

```bash
kubectl get nodes
```

## Paso 8 - Crear secret de OCIR en Kubernetes

```bash
kubectl create namespace app-demo --dry-run=client -o yaml | kubectl apply -f -

kubectl -n app-demo create secret docker-registry ocir-secret \
  --docker-server="${OCIR_REGION_KEY}.ocir.io" \
  --docker-username="${TENANCY_NAMESPACE}/${OCI_USERNAME}" \
  --docker-password="${OCI_AUTH_TOKEN}" \
  --docker-email="workshop@example.com" \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Paso 9 - Renderizar manifest Kubernetes

```bash
bash scripts/render-k8s-manifest.sh
```

El archivo renderizado queda en:

```text
APP-DEMO/k8s/aplicaciones-demo.rendered.yaml
```

## Paso 10 - Desplegar microservicios

```bash
kubectl apply -f APP-DEMO/k8s/aplicaciones-demo.rendered.yaml
kubectl -n app-demo rollout status deployment/backend-ai
kubectl -n app-demo rollout status deployment/frontend-ai
kubectl -n app-demo get pods
kubectl -n app-demo get svc frontend-ai-svc
```

Cuando el servicio `frontend-ai-svc` tenga `EXTERNAL-IP`, abrir:

```text
http://<EXTERNAL-IP>
```

Tambien se puede obtener la URL con:

```bash
export FRONTEND_IP="$(kubectl -n app-demo get svc frontend-ai-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "http://${FRONTEND_IP}"
```

## Paso 11 - Validaciones

Backend:

```bash
kubectl -n app-demo logs deployment/backend-ai
kubectl -n app-demo port-forward svc/backend-ai-svc 8000:8000
curl http://localhost:8000/health
```

Frontend:

```bash
kubectl -n app-demo logs deployment/frontend-ai
```

Prueba funcional:

1. Abrir el Load Balancer del frontend.
2. Enviar un prompt corto.
3. Confirmar que el backend responde y que los logs no muestran errores `NotAuthenticated` o `NotAuthorizedOrNotFound`.

## Troubleshooting rapido

- `NotAuthenticated`: revisar dynamic group, policy y que el pod corre sobre managed nodes OCI.
- `NotAuthorizedOrNotFound`: revisar compartimento de Generative AI, region y modelo.
- `ImagePullBackOff`: revisar `ocir-secret`, auth token, region key y namespace.
- `LoadBalancer` sin IP: revisar cuota/policy de load balancer y subnets publicas.
- `OCI_COMPARTMENT_ID is required`: revisar ConfigMap renderizado.
- `docker: command not found`: usar `podman` directamente con `export CONTAINER_CLI=podman` y repetir `bash scripts/build-and-push.sh`.

## Limpieza

```bash
kubectl delete namespace app-demo
```

Luego eliminar el Load Balancer residual si queda en OCI y destruir el cluster OKE desde Console cuando termine el laboratorio.