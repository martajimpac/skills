# Guía de uso: IAS + Plugins IA-SKILLS

IAS mantiene actualizadas las Skills de los plugins locales. Los plugins se instalan y actualizan desde el marketplace de IA-SKILLS en Claude Code o Cursor.

## 1. Cómo instalar por primera vez

1. Instala MobiAI:

```powershell
iwr -useb https://mobiai.dev/install.ps1 | iex
```

2. Clona el repositorio IA-SKILLS.
3. Instala IAS ejecutando `TAP-TO-INSTALL.cmd`.
4. Comprueba la instalación:

```powershell
ias status
ias help
```

## 2. Cómo actualizar las Skills de los plugins

Ejecuta:

```powershell
ias update
```

IAS:

- Actualiza MobiAI.
- Sincroniza las Skills existentes.
- Detecta nuevas Skills del catálogo MobiAI y muestra su carpeta de origen.
- Pregunta a qué plugin añadirlas.
- Importa Skills manuales desde `~\.ias\incoming-skills\`.
- Respeta `ignoredSkills` de `config.json`.
- Detecta cambios y actualiza las versiones de los plugins modificados y `marketplace.json`.

Después, publica los cambios en el repositorio cuando corresponda.

## 3. Cómo instalar y actualizar plugins en un repositorio nuevo

Instala siempre `general-mobile` primero si es  una aplicación móvil, y los plugins específicos del proyecto:

| Proyecto | Plugins |
|---|---|
| Android | `general-mobile`, `android` |
| Android vídeo | `general-mobile`, `android`, `android-video` |
| Kotlin Multiplatform | `general-mobile`, `android`, `kmp`, `ios` |
| iOS | `general-mobile`, `ios` |
| Flutter | `general-mobile`, `flutter` |
| React Native | `general-mobile` |

### Qué hace `general-mobile`

Además de las skills (SDD, MobiAI y React Native), la primera vez que se usa en un proyecto mobile (Android/KMP, iOS, Flutter o React Native) prepara el proyecto automáticamente:

- Copia los agentes SDD a `.claude/agents` (o `.cursor/agents` en Cursor), sin sobrescribir los que ya existan.
- Inicializa MobiAI: `mobiai brain init`, `mobiai brain scan` y `mobiai graph init`.
- Pone las reglas de `RULES.md` al principio de `AGENTS.md` (lo crea si no existe).

Solo actúa al instalar o actualizar el plugin: guarda la versión aplicada en `.claude/general-mobile.version` (o `.cursor/…`) y, mientras no cambie, no hace nada. Al actualizar, sobrescribe los agentes que no hayas modificado a mano, actualiza las reglas de `AGENTS.md` y nunca reinicializa MobiAI. Para repetirlo, borra ese fichero.

### Instalar plugins

### Claude Code

Instalar:

```text
/plugin marketplace add martajimpac/skills  #SOLO LA PRIMERA VEZ
/plugin install general-mobile@ia-skills
/plugin install android@ia-skills
```

Actualizar:

```text
/plugin marketplace update ia-skills
/plugin update general-mobile@ia-skills
/plugin update android@ia-skills
```

| Comando | Descripción |
|---|---|
| `/plugin marketplace add <repositorio>` | Añade el marketplace |
| `/plugin marketplace update ia-skills` | Actualiza el catálogo |
| `/plugin install <plugin>@ia-skills` | Instala un plugin |
| `/plugin update <plugin>@ia-skills` | Actualiza un plugin |
| `/plugin` | Abre el gestor de plugins |


### Cursor

Instala y actualiza los plugins desde **Customize → Marketplace**.
Busca `ia-skills` y selecciona los plugins necesarios para el proyecto.



