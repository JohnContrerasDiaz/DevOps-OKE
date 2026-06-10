# Repositorio Git DevOps-OKE

Este directorio esta preparado para funcionar como repositorio Git independiente.

## Estado de credenciales en esta sesion

La maquina tiene `credential.helper=manager` configurado globalmente en Git, pero `cmdkey /list` no mostro credenciales guardadas y `gh` no esta disponible en PATH. Por eso el repositorio local puede inicializarse, pero la creacion automatica del remoto requiere una de estas opciones:

1. Instalar e iniciar sesion con GitHub CLI (`gh auth login`) y ejecutar `gh repo create DevOps-OKE --private --source . --remote origin --push`.
2. Crear el repositorio remoto manualmente en GitHub/Azure DevOps y luego ejecutar `git remote add origin <remote-url>`.
3. Agregar credenciales al Windows Credential Manager para el host remoto y hacer `git push -u origin main`.

No almacenar tokens ni passwords dentro del repositorio.