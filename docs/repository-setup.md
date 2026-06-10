# Repositorio Git DevOps-OKE

Repositorio remoto:

```text
https://github.com/JohnContrerasDiaz/DevOps-OKE.git
```

## Uso desde OCI Cloud Shell

Cloud Shell trae Git y OCI CLI preautenticado. Para trabajar el workshop desde Cloud Shell:

```bash
git clone https://github.com/JohnContrerasDiaz/DevOps-OKE.git
cd DevOps-OKE
git status --short
```

Si el repositorio es privado, autenticar GitHub con el mecanismo aprobado para el workshop. No poner tokens en la URL versionada ni dentro de archivos del repositorio.

## Publicar cambios futuros

```bash
git status --short
git add .
git commit -m "Update workshop"
git push origin main
```

No almacenar tokens, auth tokens OCI, archivos PEM ni passwords dentro del repositorio.