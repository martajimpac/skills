# IAS — Corrección de Skills ignoradas

1. Extrae el ZIP completo.
2. Haz doble clic en `Install-IAS.cmd`.
3. Abre una nueva ventana de PowerShell y ejecuta `ias update`.

Al seleccionar **Ignorar** para una Skill nueva, IAS añadirá su nombre a `ignoredSkills` en `%USERPROFILE%\.ias\config.json`, guardará la configuración y confirmará el cambio. No duplicará entradas existentes. En modo `dryRun`, mostrará la operación sin guardar.
