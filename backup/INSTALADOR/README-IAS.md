# IAS — instalador limpio para Windows

IAS mantiene actualizadas las Skills que ya están dentro de tus plugins locales. **No instala plugins en Claude Code ni Cursor**: la instalación y actualización de plugins continúa haciéndose manualmente desde Claude Code.

## Archivos

- `Install-IAS.ps1`: crea desde cero el comando `ias`, su motor PowerShell y la configuración.
- `README-IAS.md`: esta guía.

## Requisitos y rutas predeterminadas

- Windows PowerShell 5.1.
- Plugins locales en `%USERPROFILE%\.ias\plugins`.
- Fuentes buscadas por defecto:
  - `%USERPROFILE%\.claude\skills`
  - `%USERPROFILE%\.agents\skills`
  - `%USERPROFILE%\.mobiai\cache\catalog\skills`

El script de instalación exige que exista la carpeta de plugins. No borra ni modifica su contenido.

## Instalación desde cero

1. Descomprime el paquete.
2. Abre PowerShell en la carpeta descomprimida.
3. Ejecuta:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Install-IAS.ps1
```

Si tus plugins están en otra ruta:

```powershell
.\Install-IAS.ps1 -PluginsPath "D:\ruta\plugins"
```

El instalador crea:

```text
%USERPROFILE%\.ias\
├── bin\
│   ├── ias.cmd
│   └── ias-core.ps1
└── config.json
```

Añade `%USERPROFILE%\.ias\bin` al PATH de usuario. Cierra y vuelve a abrir PowerShell.

Si ya existía un motor anterior, el instalador crea una copia `.bak-fecha-hora`. La configuración existente se conserva salvo que uses `-Force`. **No uses `-Force` si quieres conservar tu configuración anterior.**

## Uso

```powershell
ias help
ias status
ias update
```

`ias update`:
1. Comprueba el estado de packs globales de MobiAI. Si hay packs registrados o no puede leer el estado, se detiene antes de ejecutar `mobiai update`.
2. Ejecuta los actualizadores configurados en `config.json`, si sus comandos están disponibles.
3. Busca directorios con `SKILL.md` en las rutas fuente.
4. Sincroniza únicamente Skills que ya existen en `plugins\<plugin>\skills\<skill>`.
5. No incorpora Skills nuevas automáticamente.

Si un comando de origen falla, la sincronización se cancela.

## Configuración

Edita `%USERPROFILE%\.ias\config.json`.

- `pluginsPath`: carpeta raíz que contiene los plugins.
- `sourcePaths`: rutas donde buscar Skills fuente. Se recorren de forma recursiva.
- `ignoreFile`: archivo con Skills que no se deben sobrescribir.
- `updateCommands`: comandos para actualizar cada origen.
- `skipOriginUpdates`: si es `true`, solo sincroniza; no ejecuta comandos de actualización.
- `dryRun`: si es `true`, muestra lo que sincronizaría, sin copiar.

Ajusta `sourcePaths` a las ubicaciones reales donde cada herramienta deja sus Skills. Si hay Skills con el mismo nombre en varias fuentes, gana la primera ruta de `sourcePaths`.

### Exclusiones

El archivo indicado por `ignoreFile` contiene un nombre de Skill por línea. Las líneas que empiezan por `#` son comentarios. Por ejemplo:

```text
# Skills personalizadas
spec-driven-development
mobiai-update
```

La exclusión se aplica por nombre en todos los plugins.

## Publicar y actualizar plugins

Después de `ias update`:

1. Revisa los cambios en `plugins/`.
2. Actualiza las versiones de los plugins modificados en sus `plugin.json` y en el manifiesto del marketplace.
3. Valida y publica el repositorio.
4. En Claude Code, actualiza el marketplace y los plugins manualmente:

```text
/plugin marketplace update ia-skills
/plugin update general-mobile@ia-skills
/plugin update android@ia-skills
/plugin update android-video@ia-skills
/plugin update kmp@ia-skills
/plugin update ios@ia-skills
/plugin update supabase@ia-skills
```

## Límites de seguridad

IAS no modifica:
- Instalaciones globales de Claude Code o Cursor.
- Hooks, scripts, agentes ni archivos MCP de los plugins.
- `.mobiai/brain/` ni `.mobiai/graph/` de tus proyectos.
- `~\.mobiai\state\installed.json`.
- Los plugins manualmente instalados en Claude Code.

El hook `SessionStart` de `general-mobile` y su inicialización de Brain/Graph siguen funcionando cuando instalas ese plugin desde Claude Code. IAS no sustituye ese mecanismo.
