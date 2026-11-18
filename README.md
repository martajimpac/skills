# Guía de uso: IAS + plugins IA-SKILLS

Esta guía explica cómo usar tus plugins en un proyecto nuevo y cómo mantenerlos con IAS en Windows. Los plugins funcionan tanto en **Claude Code** como en **Cursor**.

## 1. Flujo para un repositorio nuevo

Sigue estos pasos cada vez que empieces a trabajar en un proyecto (repositorio) nuevo.

### Paso 1. Añadir los marketplaces e instalar los plugins oficiales (solo la primera vez en cada equipo)

#### Marketplace propio `ia-skills`

**Claude Code:**

```text
/plugin marketplace add martajimpac/skills
```

**Cursor:** el repositorio incluye `.cursor-plugin/marketplace.json`. Cursor permite usarlo de dos formas:

- **Planes Teams/Enterprise:** **Dashboard → Plugins & MCPs → Team Marketplaces → Add Marketplace → Import from Repo** y pega `https://github.com/martajimpac/skills`.
- **Uso personal:** clona el repositorio y copia (o enlaza) las carpetas de `plugins/` que quieras en `~/.cursor/plugins/local/`. Después reinicia Cursor o ejecuta **Developer: Reload Window**.

#### Plugins oficiales: Supabase, Figma y AWS

No forman parte de `ia-skills`; se instalan desde los marketplaces oficiales.

**Claude Code** (marketplace oficial `claude-plugins-official`, disponible por defecto):

```text
/plugin install supabase@claude-plugins-official
/plugin install figma@claude-plugins-official
/plugin install aws-core@claude-plugins-official
```

Si el marketplace oficial no aparece, añádelo con `/plugin marketplace add anthropics/claude-plugins-official`.

**Cursor** (Cursor Marketplace): abre **Customize** en la barra lateral, busca el plugin, pulsa **Install** y elige el ámbito (proyecto o usuario). También puedes consultarlos en [cursor.com/marketplace](https://cursor.com/marketplace):

| Plugin | Nombre en Cursor Marketplace |
|---|---|
| Supabase | `Supabase` |
| Figma | `Figma` |
| AWS | `AWS Core` |

Algunos piden autenticación la primera vez que se usan (OAuth de Supabase y Figma, credenciales de AWS).

AWS tiene más plugins especializados (`aws-serverless`, `aws-amplify`, `databases-on-aws`, `deploy-on-aws`, `aws-data-analytics`…). Instálalos solo si el proyecto los necesita.

### Paso 2. Instalar los plugins `ia-skills` que necesite el proyecto

Instala siempre `general-mobile` y, además, los de la plataforma del proyecto:

| Tipo de proyecto | Plugins |
|---|---|
| Android | `general-mobile`, `android` (+ `android-video` si es una app de vídeo) |
| Kotlin Multiplatform | `general-mobile`, `android`, `kmp`, `ios` |
| iOS | `general-mobile`, `ios` |
| Flutter / React Native | `general-mobile` |
| Con backend Supabase | añade el plugin oficial `supabase` (paso 1) |
| Con diseños en Figma | añade el plugin oficial `figma` (paso 1) |
| Con infraestructura en AWS | añade el plugin oficial `aws-core` (paso 1) |

En Claude Code:

```text
/plugin install general-mobile@ia-skills
/plugin install android@ia-skills
```

En Cursor, instálalos desde **Customize** (marketplace de equipo) o déjalos en `~/.cursor/plugins/local/` (uso personal).

### Paso 3. Abrir el proyecto y empezar una sesión

Al abrir una sesión en un proyecto mobile (Android/KMP, iOS, Flutter o React Native), el hook de inicio de `general-mobile` ejecuta `scripts/project-init.sh`, que:

1. **Copia los agentes SDD** (`requirements-analyst`, `android-architect`, `android-developer`, `code-reviewer`, `test-reviewer`) a:
   - `.claude/agents/` en Claude Code.
   - `.cursor/agents/` en Cursor.
2. **Inicializa MobiAI Brain y Graph** (`.mobiai/brain/` y `.mobiai/graph/`) si MobiAI está instalado.

Es idempotente: nunca sobrescribe agentes que ya existan en el proyecto ni reinicializa MobiAI. En carpetas que no son proyectos mobile no hace nada.

Para desactivarlo:

| Variable | Efecto |
|---|---|
| `SDD_AGENTS_AUTO_COPY=0` | No copia los agentes. |
| `MOBIAI_AUTO_INIT=0` | No inicializa MobiAI. |

### Paso 4. Comprobar y versionar

Comprueba que se han creado los agentes y, si quieres compartirlos con el equipo, súbelos al repositorio del proyecto:

```powershell
git status
git add .claude/agents .cursor/agents
git commit -m "chore: añadir agentes SDD"
```

A partir de aquí ya puedes trabajar con la skill `spec-driven-development`, que delega en esos agentes.

## 2. Qué hace cada pieza

IAS y los plugins tienen responsabilidades distintas:

| Herramienta | Responsabilidad |
|---|---|
| **IAS** | Actualiza las Skills desde sus fuentes y sincroniza las versiones nuevas con las copias que ya existen en tus plugins locales. |
| **Repositorio IA-SKILLS** | Contiene los plugins que mantienes y publicas en tu marketplace. |
| **Plugins de Claude Code** | Instalan las Skills y los demás componentes del plugin, como hooks, scripts, agentes y configuración MCP. |
| **Claude Code** | Instala y actualiza los plugins que hayas elegido para tu entorno. |

**Importante:** `ias update` no instala ni actualiza plugins en Claude Code o Cursor. Tampoco copia Skills directamente a sus carpetas globales. Primero actualiza tus plugins locales; después tú publicas y actualizas los plugins mediante Claude Code.

## 3. Dónde están los archivos

Con la configuración predeterminada, IAS se instala en:

```text
%USERPROFILE%\.ias\
├── bin\
│   ├── ias.cmd
│   └── ias-core.ps1
├── config.json
└── .sync-ignore
```

Tus plugins locales están en:

```text
%USERPROFILE%\.ias\plugins\
├── general-mobile\
│   └── skills\
├── android\
│   └── skills\
├── android-video\
│   └── skills\
├── kmp\
│   └── skills\
└── ios\
    └── skills\
```

El repositorio de marketplace que publicas puede estar en otra ubicación. Lo importante es que `pluginsPath` en `config.json` apunte a la carpeta local que contiene los plugins que quieres mantener.

## 4. Comprobar IAS después de instalarlo

Abre una ventana nueva de PowerShell y ejecuta:

```powershell
ias help
ias status
```

`ias status` muestra la carpeta de plugins y las rutas de búsqueda de Skills fuente configuradas.

Antes de actualizar, abre:

```powershell
notepad "$HOME\.ias\config.json"
```

Comprueba especialmente:

- `pluginsPath`: debe apuntar a tu carpeta local de plugins.
- `sourcePaths`: deben ser las carpetas reales donde las herramientas dejan las Skills descargadas o actualizadas.
- `ignoreFile`: apunta al archivo de exclusiones.

Si una herramienta instala sus Skills en otra ubicación, añade esa ruta a `sourcePaths`. IAS busca recursivamente directorios que contengan `SKILL.md`.

## 5. Flujo habitual para actualizar tus plugins

Cuando quieras incorporar las últimas versiones de las Skills a tus plugins:

### Paso 1. Actualizar las fuentes y sincronizar los plugins

En PowerShell, ejecuta:

```powershell
ias update
```

IAS realiza el siguiente proceso:

1. Comprueba el estado de los packs globales registrados por MobiAI. Si detecta packs registrados o no puede verificar el estado, se detiene por seguridad antes de ejecutar `mobiai update`.
2. Ejecuta los comandos de actualización de orígenes configurados en `config.json`, siempre que estén disponibles.
3. Busca las Skills actualizadas en las rutas de `sourcePaths`.
4. Recorre las Skills que ya existen en `plugins\<plugin>\skills\<skill>`.
5. Actualiza la copia local del plugin cuando encuentra una Skill fuente con el mismo nombre.
6. Omite las Skills incluidas en `.sync-ignore`.

IAS no añade automáticamente Skills nuevas a tus plugins. Si encuentra una Skill del plugin sin una fuente correspondiente, la informa y la deja intacta.

Si uno de los comandos de actualización de origen falla, IAS cancela la sincronización para evitar copiar contenido de una actualización incompleta.

### Paso 2. Revisar los cambios

Ve a la carpeta de tu repositorio IA-SKILLS y revisa los cambios con Git:

```powershell
git status
git diff
```

Comprueba que cada Skill se haya actualizado en el plugin correcto. Revisa también cualquier cambio manual que quieras conservar.

### Paso 3. Actualizar las versiones de los plugins

Cuando cambie el contenido de un plugin, incrementa su campo `version` en:

```text
plugins/<nombre-plugin>/.claude-plugin/plugin.json
plugins/<nombre-plugin>/.cursor-plugin/plugin.json
```

Actualiza también la versión correspondiente en:

```text
.claude-plugin/marketplace.json
.cursor-plugin/marketplace.json
```

Hazlo únicamente para los plugins que hayan cambiado.

### Paso 4. Validar y publicar

Desde la raíz del repositorio del marketplace, valida la configuración:

```bash
claude plugin validate .
```

Después revisa los cambios, crea el commit y publícalos en el remoto:

```bash
git add .
git commit -m "chore: update plugin skills"
git push
```

Adapta el mensaje del commit a los cambios reales.

### Paso 5. Actualizar los plugins en Claude Code

En Claude Code, actualiza el marketplace:

```text
/plugin marketplace update ia-skills
```

Después actualiza los plugins que quieras:

```text
/plugin update general-mobile@ia-skills
/plugin update android@ia-skills
/plugin update android-video@ia-skills
/plugin update kmp@ia-skills
/plugin update ios@ia-skills
```

No es necesario actualizar todos si solo has cambiado uno o unos pocos.

Para instalar un plugin por primera vez:

```text
/plugin install general-mobile@ia-skills
```

Sustituye `general-mobile` por el plugin que quieras instalar.

## 6. Qué ocurre con los componentes de los plugins

IAS sincroniza únicamente el contenido de las carpetas `skills/` de tus plugins locales. No gestiona ni modifica los demás componentes.

Por tanto, se conservan en el repositorio y siguen siendo responsabilidad del mecanismo de plugins de Claude Code:

- **Hooks:** por ejemplo, el hook `SessionStart` de `general-mobile`.
- **Scripts:** por ejemplo, `scripts/project-init.sh`.
- **Agentes:** por ejemplo, los agentes de `android/agents/` y de `general-mobile/agents/`.
- **Manifiestos:** `.claude-plugin/plugin.json` y `.cursor-plugin/plugin.json` de cada plugin, y los marketplaces `.claude-plugin/marketplace.json` y `.cursor-plugin/marketplace.json`.

### Agentes de SDD en `general-mobile`

La skill `spec-driven-development` delega en los agentes `requirements-analyst`, `android-architect`, `android-developer`, `code-reviewer` y `test-reviewer`. Por eso `general-mobile` incluye una copia de ellos en `plugins/general-mobile/agents/`:

- **Claude Code:** se instalan con `/plugin install general-mobile@ia-skills` y, además, el hook de inicio los copia a `.claude/agents/` de cada proyecto mobile.
- **Cursor:** el plugin incluye `.cursor-plugin/plugin.json` y el repositorio `.cursor-plugin/marketplace.json`, así que Cursor instala skills y agentes al añadir el marketplace; el hook `sessionStart` los copia a `.cursor/agents/` de cada proyecto mobile.

Si modificas un agente, cambia también su copia en `plugins/android/agents/` para que no diverjan.

### Inicialización de MobiAI Brain y Graph

La inicialización automática sigue dependiendo del plugin `general-mobile` instalado en Claude Code, no de IAS.

Cuando se inicia una sesión de Claude Code, el hook `SessionStart` de ese plugin puede ejecutar `scripts/project-init.sh`. Según las condiciones definidas por el propio script, inicializa Brain o Graph si todavía no existen en el proyecto.

IAS no crea, elimina ni reemplaza los datos de:

```text
.mobiai/brain/
.mobiai/graph/
```

Tampoco modifica el registro global de packs de MobiAI.

## 7. Proteger Skills personalizadas con `.sync-ignore`

Si has modificado una Skill dentro de un plugin y no quieres que IAS la sobrescriba, añade su nombre al archivo indicado por `ignoreFile`.

Ejemplo:

```text
# Skills con cambios propios que deben conservarse
spec-driven-development
mobiai-update
```

Es una exclusión por nombre: si dos plugins contienen una Skill con el mismo nombre, se omitirán ambas.

Para volver a permitir su sincronización, elimina su línea del archivo.

## 8. Añadir una Skill nueva a un plugin

IAS actualiza Skills que ya existen en los plugins, pero no decide dónde colocar Skills nuevas.

Para incorporar una nueva:

1. Localiza la Skill en la carpeta fuente.
2. Copia o crea su directorio dentro del plugin que corresponda:

```text
plugins/<plugin>/skills/<nombre-skill>/SKILL.md
```

3. Revisa su contenido y sus dependencias.
4. Incrementa la versión del plugin y la del marketplace.
5. Valida, publica y actualiza el plugin desde Claude Code.

## 9. Comandos de referencia

| Comando | Uso |
|---|---|
| `ias help` | Muestra los comandos disponibles. |
| `ias status` | Comprueba las rutas configuradas. |
| `ias update` | Actualiza orígenes configurados y sincroniza Skills existentes en los plugins locales. |
| `/plugin marketplace update ia-skills` | Actualiza el índice del marketplace en Claude Code. |
| `/plugin update <plugin>@ia-skills` | Actualiza un plugin instalado. |
| `/plugin install <plugin>@ia-skills` | Instala un plugin. |

## 10. Resumen: el ciclo de mantenimiento

El flujo completo es:

```text
Fuentes originales de Skills
          |
          | ias update
          v
Plugins locales (%USERPROFILE%\.ias\plugins)
          |
          | revisar cambios + subir versiones
          v
Repositorio IA-SKILLS publicado
          |
          | /plugin marketplace update ia-skills
          v
/plugin update <plugin>@ia-skills
          |
          v
Claude Code utiliza la nueva versión del plugin
```

**Regla sencilla:** IAS actualiza las Skills dentro de tus plugins locales; tú publicas los plugins; Claude Code instala o actualiza los plugins y ejecuta sus componentes.
