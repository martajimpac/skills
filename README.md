# IA-SKILLS · Marketplace de plugins para Claude Code

Marketplace personal con Skills y agentes agrupados en plugins por plataforma. Este repositorio es la **fuente de mantenimiento** de los plugins; para seleccionar e instalar Skills por proyecto en Windows se utiliza **IAS 2.0**.

## Estructura

```text
.
├── .claude-plugin/
│   └── marketplace.json        # Catálogo del marketplace de Claude Code
├── plugins/
│   ├── general-mobile/          # Flujo mobile multiplataforma + hook MobiAI
│   │   ├── .claude-plugin/plugin.json
│   │   ├── hooks/hooks.json
│   │   ├── scripts/mobiai-init.sh
│   │   └── skills/
│   ├── android/                 # Skills + agentes Android
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/
│   │   └── agents/
│   ├── android-video/           # Vídeo: Media3, TV y coche
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   ├── kmp/                     # Kotlin Multiplatform
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   ├── ios/                     # Skills iOS
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   └── supabase/                # Skills Supabase + MCP
│       ├── .claude-plugin/plugin.json
│       ├── .mcp.json
│       └── skills/
├── scripts/sync-skills.sh      # Sincroniza Skills desde sus orígenes
├── .sync-ignore                # Skills que sync-skills.sh no debe sobrescribir
├── RULES.md                    # Reglas SDD para CLAUDE.md / AGENTS.md
└── README.md
```

## Plugins

| Plugin | Contenido |
|---|---|
| `general-mobile` | **Flujo de trabajo:** `spec-driven-development`, `using-mobiai`, `mobiai-mobile-tdd`, `mobiai-mobile-debugging`, `mobiai-mobile-verification`, `mobiai-mobile-worktrees`, `mobiai-review-code`, `mobiai-write-tests`, `mobiai-create-pr`, `mobiai-fix-issue`<br>**Bugs y crashes:** `mobiai-analyze-crash`, `mobiai-crashlytics`, `mobiai-reproduce-bug`<br>**MobiAI:** `mobiai-brain`, `mobiai-graph`, `mobiai-update`, `mobiai-writing-skills`<br>**Otros frameworks:** `mobiai-flutter`, `mobiai-react-native`<br>**Hook `SessionStart`:** ejecuta `mobiai brain init` y `mobiai graph init` (ver abajo). |
| `android` | **UI y Compose:** `android-jetpack-compose`, `jetpack-compose-performance`, `adaptive`, `edge-to-edge`, `styles`, `migrate-xml-views-to-jetpack-compose`, `one-shot-ui-events`, `glance-canonical-layouts`<br>**Navegación:** `navigation-3`, `navigation-event`<br>**Arquitectura, build y tests:** `mobiai-android-architecture`, `mobiai-android-build`, `mobiai-android-testing`, `mobiai-android-device`, `android-kotlin-coroutines`, `agp-9-upgrade`, `android-cli`, `testing-setup`<br>**Rendimiento:** `android-profiler`, `anr-audit-and-fix`<br>**Seguridad e identidad:** `android-intent-security`, `android-permissions-security`, `restore-credentials`, `verified-email`<br>**Google Play:** `play-billing-library-version-upgrade`, `play-policy-insights`, `engage-sdk-integration`<br>**Hardware:** `camerax`<br>**Wear OS y XR:** `wear-compose-m3`, `wear-widgets`, `display-glasses-with-jetpack-compose-glimmer`, `projected-hardware`<br>**IA on-device:** `litert-lm`, `litert-runtime`, `ml-kit-genai-prompt-api`<br>**Agentes:** `android-architect`, `android-developer`, `code-reviewer`, `requirements-analyst`, `test-reviewer`. |
| `android-video` | `media3-cast-integration` (ExoPlayer/Media3 + Google Cast), `leanback-to-compose-tv-migration` (Android TV), `android-for-cars-parked-apps` (vídeo en Android Auto/Automotive). |
| `kmp` | `mobiai-kmp`. |
| `ios` | `mobiai-ios-architecture`, `mobiai-ios-build`, `mobiai-ios-device`, `mobiai-ios-testing`. |
| `supabase` | Skills: `supabase`, `supabase-postgres-best-practices`.<br>MCP: `supabase` (`https://mcp.supabase.com/mcp`, autenticación OAuth la primera vez vía `/mcp`). |

---

# Usar IAS 2.0 en Windows

IAS permite mantener una selección de Skills distinta para cada repositorio. Lee los plugins personalizados instalados localmente en:

```text
%USERPROFILE%\.ias\plugins
```

No utiliza el catálogo global de MobiAI como fuente de Skills. La selección del proyecto se guarda en `.ias\project.json`, y las copias que IAS administra se registran en `.ias\managed.json`.

> **Regla principal:** ejecuta los comandos de proyecto desde la raíz del repositorio que quieras configurar. No ejecutes `ias select`, `ias install` o `ias update` desde `C:\Users\<usuario>` ni desde la carpeta de instalación de IAS.

## Requisitos

- Windows PowerShell 5.1.
- IAS 2.0 instalado y disponible en el `PATH`.
- Los plugins personalizados dentro de `%USERPROFILE%\.ias\plugins`.
- MobiAI instalado para utilizar `ias update`.

Comprueba que el lanzador está disponible:

```powershell
Get-Command ias -All
```

Debe aparecer como `Application` y apuntar a:

```text
%USERPROFILE%\.ias\bin\ias.cmd
```

## 1. Comprobar plugins y catálogo

Ver los plugins locales y el número de Skills:

```powershell
ias plugins
```

Reconstruir el índice local a partir de los plugins instalados:

```powershell
ias catalog update
```

Este comando **solo indexa las carpetas locales**. No descarga ni actualiza plugins.

Listar todas las Skills:

```powershell
ias list
```

Filtrar por plugin:

```powershell
ias list android
ias list general-mobile
ias list ios
ias list supabase
```

Los identificadores de Skill tienen el formato `plugin/skill`, por ejemplo:

```text
android/adaptive
general-mobile/mobiai-brain
general-mobile/mobiai-graph
supabase/supabase
```

## 2. Configurar un repositorio nuevo

Entra en la raíz del repositorio:

```powershell
cd "C:\ruta\de\tu\repositorio"
Get-Location
```

Consulta las Skills disponibles:

```powershell
ias list
```

Abre el selector interactivo:

```powershell
ias select
```

Selecciona los números separados por comas, por ejemplo:

```text
1,3,7,12
```

Opciones del selector:

- `all`: selecciona todas las Skills mostradas.
- `q`: cancela sin guardar.
- Los elementos marcados con `[x]` ya están seleccionados.

También puedes limitar el selector a un plugin:

```powershell
ias select android
```

Al seleccionar un plugin concreto, IAS conserva la selección de los demás plugins y reemplaza la selección de ese plugin.

**Atención:** `ias select` sin filtro reemplaza la selección completa del repositorio por los elementos que marques en esa operación. Revisa las marcas antes de guardar.

La selección queda guardada en:

```text
.ias\project.json
```

## 3. Instalar las Skills seleccionadas

Desde la raíz del repositorio:

```powershell
ias install
```

IAS instala las Skills seleccionadas y no ignoradas en las carpetas locales del proyecto:

```text
.claude\skills\<skill>\
.cursor\skills\<skill>\
```

No instala Skills que no hayas seleccionado.

IAS registra las copias que administra en:

```text
.ias\managed.json
```

### Si ya existe una carpeta de Skill

Si el destino ya existe y no está registrado como gestionado por IAS, IAS lo protege y no lo sobrescribe. Esto evita reemplazar contenido que pueda pertenecer al usuario o a otra herramienta.

Si quieres registrar una Skill existente, consulta **Adoptar Skills existentes**.

## 4. Adoptar Skills existentes

Si ya tenías Skills instaladas en el repositorio antes de empezar a usar IAS, ejecuta:

```powershell
ias adopt
```

IAS solo debe adoptar una carpeta si su contenido coincide exactamente con la Skill de origen. Si no coincide, la deja intacta y no la registra.

La adopción no debe borrar ni sobrescribir las carpetas existentes. Después, comprueba el resultado:

```powershell
ias status
```

## 5. Comprobar el estado del proyecto

```powershell
ias status
```

Muestra las Skills seleccionadas y su estado de gestión/instalación en Claude y Cursor.

También puedes consultar la selección y el catálogo:

```powershell
ias list
```

## 6. Actualizar un proyecto

Cuando las Skills ya estén instaladas y gestionadas por IAS, ejecuta desde la raíz del repositorio:

```powershell
ias update
```

IAS realiza estas operaciones en orden:

1. Comprueba que existe `~\.mobiai\state\installed.json` y que no hay packs globales registrados.
2. Ejecuta `mobiai update`. Si falla la comprobación o el comando devuelve un error, IAS detiene la operación.
3. Actualiza exclusivamente las Skills seleccionadas en el repositorio actual, que no estén ignoradas y que IAS ya tenga registradas como gestionadas.

**`ias update` no es el comando para instalar una Skill por primera vez.** Para una primera instalación o para incorporar una selección nueva, utiliza `ias install`.

Antes de reemplazar una Skill gestionada, IAS guarda una copia de seguridad bajo:

```text
.ias\backups\
```

Flujo habitual:

```powershell
ias update
ias status
```

> `mobiai update` actualiza MobiAI y su catálogo. No actualiza automáticamente los plugins personalizados de `%USERPROFILE%\.ias\plugins`; esos plugins deben actualizarse por su propio procedimiento.

## 7. Ignorar y restaurar Skills

Las exclusiones son globales para IAS: se aplican a todos los repositorios gestionados por el usuario.

Listar las Skills ignoradas:

```powershell
ias ignore
```

Ignorar una Skill usando su identificador completo:

```powershell
ias ignore android/adaptive
```

Dejar de ignorarla:

```powershell
ias unignore android/adaptive
```

Ignorar una Skill evita que IAS la ofrezca/instale o actualice en las operaciones correspondientes. **No elimina las copias ya instaladas** en los repositorios.

## 8. Archivos que IAS crea en cada repositorio

```text
tu-repositorio\
├── .ias\
│   ├── project.json    # Selección de Skills del proyecto
│   ├── managed.json    # Registro de copias gestionadas por IAS
│   └── backups\        # Copias de seguridad de actualizaciones
├── .claude\
│   └── skills\         # Skills locales para Claude Code
└── .cursor\
    └── skills\         # Skills locales para Cursor
```

La fuente de plugins personalizados permanece en `%USERPROFILE%\.ias\plugins`. IAS no debe modificarla al instalar o actualizar Skills en un repositorio.

Si el repositorio está versionado con Git, decide con el equipo si queréis compartir `.ias\project.json`, `.ias\managed.json` y las carpetas `.claude` / `.cursor`. No incluyas copias de seguridad salvo que exista un motivo concreto.

## 9. Flujo rápido para un repositorio nuevo

```powershell
# Entrar en el repositorio
cd "C:\ruta\de\tu\repositorio"

# Consultar Skills
ias list

# Seleccionar las Skills para este proyecto
ias select

# Instalar en Claude y Cursor
ias install

# Verificar
ias status
```

Para el mantenimiento habitual:

```powershell
cd "C:\ruta\de\tu\repositorio"
ias update
ias status
```

## 10. Referencia de comandos IAS

| Comando | Función |
|---|---|
| `ias` | Muestra la ayuda |
| `ias plugins` | Lista plugins locales y número de Skills |
| `ias list` | Lista Skills disponibles y estados |
| `ias list <plugin>` | Filtra por plugin |
| `ias catalog update` | Reconstruye el índice de plugins locales |
| `ias select` | Selecciona Skills para el repositorio actual |
| `ias select <plugin>` | Selecciona Skills de un plugin conservando las demás selecciones |
| `ias install` | Instala la selección en Claude y Cursor del repositorio |
| `ias adopt` | Registra instalaciones existentes cuyo contenido coincide con el origen |
| `ias update` | Actualiza MobiAI y las Skills seleccionadas que IAS ya gestiona |
| `ias status` | Muestra el estado del proyecto |
| `ias ignore` | Lista Skills ignoradas globalmente |
| `ias ignore <plugin/skill>` | Ignora una Skill globalmente |
| `ias unignore <plugin/skill>` | Quita una exclusión global |

---

# Marketplace de Claude Code (instalación alternativa)

El marketplace también se puede utilizar directamente desde Claude Code, de forma independiente de IAS.

Añadir el marketplace:

```text
/plugin marketplace add martajimpac/skills
```

Instalar los plugins que necesites:

```text
/plugin install general-mobile@ia-skills
/plugin install android@ia-skills
/plugin install android-video@ia-skills
/plugin install kmp@ia-skills
/plugin install ios@ia-skills
/plugin install supabase@ia-skills
```

Esta vía instala plugins mediante el sistema de marketplace de Claude Code. **No es el flujo de selección por proyecto de IAS** y no debe confundirse con la instalación local en `.claude\skills` y `.cursor\skills` que realiza IAS.

## Inicialización automática de MobiAI (plugin `general-mobile`)

Los plugins de Claude Code no tienen un hook "al instalar", así que el plugin `general-mobile` usa un hook `SessionStart`. Al abrir una sesión nueva, `scripts/mobiai-init.sh`:

- Solo actúa si `mobiai` está en el `PATH` y la carpeta es un proyecto móvil (tenga Git o no):
  `settings.gradle(.kts)` (Android/KMP), `*.xcodeproj`, `*.xcworkspace` o `Package.swift` (iOS), `pubspec.yaml` (Flutter) o un `package.json` con `react-native`.
- Ejecuta `mobiai brain init` si no existe `.mobiai/brain/`.
- Ejecuta `mobiai graph init` si no existe `.mobiai/graph/index.json`.

Así se ejecuta una vez por proyecto. Para desactivarlo, define la variable de entorno `MOBIAI_AUTO_INIT=0`.

---

# Mantener y publicar los plugins de este repositorio

Las Skills de este repositorio son copias de otras fuentes. Para incorporar versiones nuevas al marketplace:

## 1. Actualizar las Skills en su origen

| Origen | Skills | Comando |
|---|---|---|
| [MobiAI](https://github.com/ArisGuimera/MobiAI-Core) | `mobiai-*`, `using-mobiai` | `mobiai update` |
| Android CLI (Google) | Skills de autor *Google LLC*: `adaptive`, `edge-to-edge`, `navigation-3`, `camerax`, `testing-setup`, `media3-cast-integration`, `wear-*`, etc. | `android skills update` |
| Supabase | `supabase`, `supabase-postgres-best-practices` | `npx skills update` o `npx skills add supabase/agent-skills` |
| skills.sh | `android-jetpack-compose`, `android-kotlin-coroutines` | `npx skills update` |
| Propias | `spec-driven-development`, `one-shot-ui-events` | Se editan directamente en este repositorio |

Cada herramienta deja las Skills en su carpeta de instalación, normalmente `~/.claude/skills`, `~/.agents/skills` o `.claude/skills` dentro de un proyecto.

## 2. Copiar los cambios a los plugins

Primero simula los cambios:

```bash
scripts/sync-skills.sh --dry-run ~/.claude/skills ~/.agents/skills
```

Después aplica la sincronización:

```bash
scripts/sync-skills.sh ~/.claude/skills ~/.agents/skills
```

El script:

- Reemplaza cada Skill existente en `plugins/*/skills/<nombre>` por la versión del origen.
- Lista como **NUEVA** cualquier Skill que no esté en ningún plugin, para que la muevas manualmente a `plugins/<plugin>/skills/`.
- No toca las Skills listadas en `.sync-ignore` (por ejemplo, `spec-driven-development` y `mobiai-update`).

## 3. Publicar una nueva versión

1. Incrementa la `version` de cada plugin modificado en `plugins/<plugin>/.claude-plugin/plugin.json` y en `.claude-plugin/marketplace.json`. Claude Code solo detecta actualizaciones si cambia la versión.
2. Valida: `claude plugin validate .`
3. Haz commit y push.

## 4. Recoger la actualización en cada equipo

```text
/plugin marketplace update ia-skills
/plugin update <plugin>@ia-skills
```

---

# Añadir una Skill nueva

1. Crea `plugins/<plugin>/skills/<nombre-skill>/SKILL.md` con frontmatter:

   ```markdown
   ---
   name: nombre-skill
   description: Cuándo debe usarse esta Skill.
   ---
   ```

2. Los agentes van en `plugins/<plugin>/agents/<nombre>.md`.
3. Incrementa la versión del plugin y valida como se indica en **Publicar una nueva versión**.
4. Para que IAS la detecte, actualiza el contenido del plugin en `%USERPROFILE%\.ias\plugins` y ejecuta:

   ```powershell
   ias catalog update
   ```

   Después, selecciónala en cada repositorio donde quieras utilizarla y ejecuta `ias install`.
