# IA-SKILLS · Marketplace de plugins para Claude Code

Marketplace personal con skills y agentes agrupados en plugins por plataforma.

## Estructura

```
.
├── .claude-plugin/
│   └── marketplace.json        # Catálogo del marketplace
├── plugins/
│   ├── general-mobile/         # Skills transversales + hook MobiAI
│   │   ├── .claude-plugin/plugin.json
│   │   ├── hooks/hooks.json
│   │   ├── scripts/mobiai-init.sh
│   │   └── skills/
│   ├── supabase/               # Skills Supabase + MCP de Supabase
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .mcp.json
│   │   └── skills/
│   ├── android/                # Skills + agentes Android
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/
│   │   └── agents/
│   └── ios/                    # Skills iOS (vacío por ahora)
│       ├── .claude-plugin/plugin.json
│       └── skills/
├── RULES.md                    # Reglas SDD para copiar a CLAUDE.md / AGENTS.md
└── README.md
```

## Plugins

| Plugin | Contenido |
|---|---|
| `general-mobile` | Skills: `spec-driven-development`, `mobiai-update`<br>Hook `SessionStart`: ejecuta `mobiai brain init` y `mobiai graph init` (ver abajo) |
| `supabase` | Skills: `supabase`, `supabase-postgres-best-practices`<br>MCP: `supabase` (`https://mcp.supabase.com/mcp`, se autentica con OAuth la primera vez vía `/mcp`) |
| `android` | Skills: `android-jetpack-compose`, `android-kotlin-coroutines`, `one-shot-ui-events`<br>Agentes: `android-architect`, `android-developer`, `code-reviewer`, `requirements-analyst`, `test-reviewer` |
| `ios` | Pendiente de añadir skills |

## Instalación

Desde Claude Code, añade el marketplace (ruta local o repositorio de GitHub):

```
/plugin marketplace add C:\Users\marta\Documents\IA-SKILLS
# o bien: /plugin marketplace add <usuario>/<repo>
```

Instala los plugins que necesites:

```
/plugin install general-mobile@ia-skills
/plugin install supabase@ia-skills
/plugin install android@ia-skills
/plugin install ios@ia-skills
```

### Inicialización automática de MobiAI (plugin `general-mobile`)

Los plugins de Claude Code no tienen un hook "al instalar", así que el plugin `general-mobile` usa un
hook `SessionStart`. Al abrir una sesión nueva, `scripts/mobiai-init.sh`:

- solo actúa si el directorio del proyecto es la raíz de un repositorio git y `mobiai` está en el `PATH`;
- ejecuta `mobiai brain init` si no existe `.mobiai/brain/`;
- ejecuta `mobiai graph init` si no existe `.mobiai/graph/index.json`.

Así se ejecuta una vez por proyecto. Para desactivarlo, define la variable de entorno `MOBIAI_AUTO_INIT=0`.

Para recoger cambios del repositorio: `/plugin marketplace update ia-skills`.

## Añadir una skill nueva

1. Crea `plugins/<plugin>/skills/<nombre-skill>/SKILL.md` con frontmatter:
   ```markdown
   ---
   name: nombre-skill
   description: Cuándo debe usarse esta skill.
   ---
   ```
2. Los agentes van en `plugins/<plugin>/agents/<nombre>.md`.
3. Sube la `version` en `plugins/<plugin>/.claude-plugin/plugin.json` y en `.claude-plugin/marketplace.json`.
4. Ejecuta `claude plugin validate .` para comprobar los manifiestos.
