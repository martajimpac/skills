# IA-SKILLS · Marketplace de plugins para Claude Code

Marketplace personal con skills y agentes agrupados en plugins por plataforma.

## Estructura

```
.
├── .claude-plugin/
│   └── marketplace.json        # Catálogo del marketplace
├── plugins/
│   ├── general-mobile/         # Flujo mobile multiplataforma + hook MobiAI
│   │   ├── .claude-plugin/plugin.json
│   │   ├── hooks/hooks.json
│   │   ├── scripts/mobiai-init.sh
│   │   └── skills/
│   ├── android/                # Skills + agentes Android
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/
│   │   └── agents/
│   ├── android-video/          # Apps con vídeo: ExoPlayer/Media3, TV, coche
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   ├── kmp/                    # Kotlin Multiplatform
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   ├── ios/                    # Skills iOS
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/
│   └── supabase/               # Skills Supabase + MCP de Supabase
│       ├── .claude-plugin/plugin.json
│       ├── .mcp.json
│       └── skills/
├── scripts/sync-skills.sh      # Actualiza las skills desde su origen
├── .sync-ignore                # Skills que el script no debe sobrescribir
├── RULES.md                    # Reglas SDD para copiar a CLAUDE.md / AGENTS.md
└── README.md
```

## Plugins

| Plugin | Contenido |
|---|---|
| `general-mobile` | **Flujo de trabajo:** `spec-driven-development`, `using-mobiai`, `mobiai-mobile-tdd`, `mobiai-mobile-debugging`, `mobiai-mobile-verification`, `mobiai-mobile-worktrees`, `mobiai-review-code`, `mobiai-write-tests`, `mobiai-create-pr`, `mobiai-fix-issue`<br>**Bugs y crashes:** `mobiai-analyze-crash`, `mobiai-crashlytics`, `mobiai-reproduce-bug`<br>**MobiAI:** `mobiai-brain`, `mobiai-graph`, `mobiai-update`, `mobiai-writing-skills`<br>**Otros frameworks:** `mobiai-flutter`, `mobiai-react-native`<br>**Hook `SessionStart`:** ejecuta `mobiai brain init` y `mobiai graph init` (ver abajo) |
| `android` | **UI y Compose:** `android-jetpack-compose`, `jetpack-compose-performance`, `adaptive`, `edge-to-edge`, `styles`, `migrate-xml-views-to-jetpack-compose`, `one-shot-ui-events`, `glance-canonical-layouts`<br>**Navegación:** `navigation-3`, `navigation-event`<br>**Arquitectura, build y tests:** `mobiai-android-architecture`, `mobiai-android-build`, `mobiai-android-testing`, `mobiai-android-device`, `android-kotlin-coroutines`, `agp-9-upgrade`, `android-cli`, `testing-setup`<br>**Rendimiento:** `android-profiler`, `anr-audit-and-fix`<br>**Seguridad e identidad:** `android-intent-security`, `android-permissions-security`, `restore-credentials`, `verified-email`<br>**Google Play:** `play-billing-library-version-upgrade`, `play-policy-insights`, `engage-sdk-integration`<br>**Hardware:** `camerax`<br>**Wear OS y XR:** `wear-compose-m3`, `wear-widgets`, `display-glasses-with-jetpack-compose-glimmer`, `projected-hardware`<br>**IA on-device:** `litert-lm`, `litert-runtime`, `ml-kit-genai-prompt-api`<br>**Agentes:** `android-architect`, `android-developer`, `code-reviewer`, `requirements-analyst`, `test-reviewer` |
| `android-video` | `media3-cast-integration` (ExoPlayer/Media3 + Google Cast), `leanback-to-compose-tv-migration` (Android TV), `android-for-cars-parked-apps` (vídeo en Android Auto/Automotive) |
| `kmp` | `mobiai-kmp` |
| `ios` | `mobiai-ios-architecture`, `mobiai-ios-build`, `mobiai-ios-device`, `mobiai-ios-testing` |
| `supabase` | Skills: `supabase`, `supabase-postgres-best-practices`<br>MCP: `supabase` (`https://mcp.supabase.com/mcp`, se autentica con OAuth la primera vez vía `/mcp`) |

## Instalación

Desde Claude Code, añade el marketplace:

```
/plugin marketplace add martajimpac/skills
```

Instala los plugins que necesites:

```
/plugin install general-mobile@ia-skills
/plugin install android@ia-skills
/plugin install android-video@ia-skills
/plugin install kmp@ia-skills
/plugin install ios@ia-skills
/plugin install supabase@ia-skills
```

### Inicialización automática de MobiAI (plugin `general-mobile`)

Los plugins de Claude Code no tienen un hook "al instalar", así que el plugin `general-mobile` usa un
hook `SessionStart`. Al abrir una sesión nueva, `scripts/mobiai-init.sh`:

- solo actúa si `mobiai` está en el `PATH` y la carpeta es un proyecto móvil (tenga git o no):
  `settings.gradle(.kts)` (Android/KMP), `*.xcodeproj`, `*.xcworkspace` o `Package.swift` (iOS),
  `pubspec.yaml` (Flutter) o un `package.json` con `react-native`;
- ejecuta `mobiai brain init` si no existe `.mobiai/brain/`;
- ejecuta `mobiai graph init` si no existe `.mobiai/graph/index.json`.

Así se ejecuta una vez por proyecto. Para desactivarlo, define la variable de entorno `MOBIAI_AUTO_INIT=0`.

## Actualizar las skills

Las skills de este repositorio son copias de otras fuentes. Para traer sus versiones nuevas:

### 1. Actualiza las skills en su origen

| Origen | Skills | Comando |
|---|---|---|
| [MobiAI](https://github.com/ArisGuimera/MobiAI-Core) | `mobiai-*`, `using-mobiai` | `mobiai update` |
| Android CLI (Google) | Todas las de autor *Google LLC*: `adaptive`, `edge-to-edge`, `navigation-3`, `camerax`, `testing-setup`, `media3-cast-integration`, `wear-*`… | `android skills update` |
| Supabase | `supabase`, `supabase-postgres-best-practices` | `npx skills update` (o `npx skills add supabase/agent-skills`) |
| skills.sh | `android-jetpack-compose`, `android-kotlin-coroutines` | `npx skills update` |
| Propias | `spec-driven-development`, `one-shot-ui-events` | Se editan directamente aquí |

Cada herramienta deja las skills en su carpeta de instalación, normalmente `~/.claude/skills`,
`~/.agents/skills` o `.claude/skills` dentro de un proyecto.

### 2. Copia los cambios a los plugins

```bash
# Ver qué cambiaría, sin tocar nada
scripts/sync-skills.sh --dry-run ~/.claude/skills ~/.agents/skills

# Aplicar
scripts/sync-skills.sh ~/.claude/skills ~/.agents/skills
```

El script:
- reemplaza cada skill que ya existe en `plugins/*/skills/<nombre>` por la versión del origen;
- lista como **NUEVA** cualquier skill que no esté en ningún plugin, para que la muevas a mano a
  `plugins/<plugin>/skills/`;
- no toca las skills listadas en `.sync-ignore` (las que tienen cambios propios, como
  `spec-driven-development` y `mobiai-update`).

### 3. Publica la nueva versión

1. Sube la `version` de cada plugin modificado en `plugins/<plugin>/.claude-plugin/plugin.json` y
   en `.claude-plugin/marketplace.json`. Claude Code solo detecta actualizaciones si cambia la versión.
2. Valida: `claude plugin validate .`
3. Haz commit y push.

### 4. Recoge la actualización en cada equipo

```
/plugin marketplace update ia-skills
/plugin update <plugin>@ia-skills
```

## Añadir una skill nueva

1. Crea `plugins/<plugin>/skills/<nombre-skill>/SKILL.md` con frontmatter:
   ```markdown
   ---
   name: nombre-skill
   description: Cuándo debe usarse esta skill.
   ---
   ```
2. Los agentes van en `plugins/<plugin>/agents/<nombre>.md`.
3. Sube la `version` del plugin y valida, como en el paso 3 de arriba.
