#!/usr/bin/env bash
# Prepara un proyecto mobile la primera vez que se abre una sesión (Claude Code o Cursor):
#   1. Copia los agentes SDD del plugin a .claude/agents (Claude Code) o .cursor/agents (Cursor).
#   2. Inicializa MobiAI Brain (init + scan) y Graph si MobiAI está instalado.
#   3. Pone las reglas de RULES.md del plugin al principio de AGENTS.md (lo crea si no existe).
# Idempotente: nunca sobrescribe agentes existentes ni reinicializa MobiAI; en
# AGENTS.md solo toca el bloque de reglas entre marcadores.
# En Claude Code se lanza en SessionStart y también en UserPromptSubmit (una vez
# por sesión), para que funcione aunque el plugin se instale con la sesión abierta.
# Uso: project-init.sh [claude|cursor]
# Desactivar: SDD_AGENTS_AUTO_COPY=0 (agentes) / MOBIAI_AUTO_INIT=0 (MobiAI) /
#             AGENTS_MD_AUTO_RULES=0 (AGENTS.md).

client="${1:-claude}"
plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cr="$(printf '\r')"

# El hook recibe JSON por stdin (Claude Code y Cursor).
stdin_json=""
if [ ! -t 0 ]; then
  stdin_json="$(cat)"
fi
json_field() {
  printf '%s' "$stdin_json" | tr -d '\n' \
    | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

# En UserPromptSubmit basta con ejecutarse una vez por sesión.
event="$(json_field hook_event_name)"
session_id="$(json_field session_id)"
if [ -n "$session_id" ]; then
  stamp="${TMPDIR:-/tmp}/general-mobile-init-$(printf '%s' "$session_id" | tr -cd 'A-Za-z0-9_-')"
  if [ "$event" = "UserPromptSubmit" ] && [ -e "$stamp" ]; then
    exit 0
  fi
  : > "$stamp" 2>/dev/null
fi

# Cursor espera JSON por stdout; los mensajes van a stderr.
say() {
  if [ "$client" = "cursor" ]; then echo "$*" >&2; else echo "$*"; fi
}
finish() {
  [ "$client" = "cursor" ] && echo '{}'
  exit 0
}

root="${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-}}"
if [ -z "$root" ] && [ -n "$stdin_json" ]; then
  # Primer elemento de "workspace_roots": [...]
  root="$(printf '%s' "$stdin_json" | tr -d '\n' \
    | sed -n 's/.*"workspace_roots"[[:space:]]*:[[:space:]]*\[[[:space:]]*"\([^"]*\)".*/\1/p' \
    | sed 's/\\\\/\\/g')"
  # Rutas tipo /c:/Users/... -> c:/Users/...
  case "$root" in /[A-Za-z]:*) root="${root#/}" ;; esac
fi
[ -z "$root" ] && [ "$client" != "cursor" ] && root="$(json_field cwd | sed 's/\\\\/\\/g')"
[ -z "$root" ] && [ "$client" != "cursor" ] && root="$PWD"
[ -n "$root" ] || finish
cd "$root" 2>/dev/null || finish

# Solo en proyectos móviles, para no tocar carpetas cualquiera.
is_mobile_project() {
  # Android / KMP
  { [ -f settings.gradle ] || [ -f settings.gradle.kts ]; } && return 0
  # iOS
  { compgen -G "*.xcodeproj" >/dev/null || compgen -G "*.xcworkspace" >/dev/null; } && return 0
  [ -f Package.swift ] && return 0
  # Flutter
  [ -f pubspec.yaml ] && return 0
  # React Native
  [ -f package.json ] && grep -q '"react-native"' package.json && return 0
  return 1
}
is_mobile_project || finish

done_items=()

# 1. Agentes SDD
if [ "${SDD_AGENTS_AUTO_COPY:-1}" != "0" ] && [ -d "$plugin_root/agents" ]; then
  if [ "$client" = "cursor" ]; then agents_dir=".cursor/agents"; else agents_dir=".claude/agents"; fi
  copied=()
  for src in "$plugin_root"/agents/*.md; do
    [ -f "$src" ] || continue
    dest="$agents_dir/$(basename "$src")"
    if [ ! -e "$dest" ]; then
      mkdir -p "$agents_dir" && cp "$src" "$dest" && copied+=("$(basename "$src" .md)")
    fi
  done
  [ ${#copied[@]} -gt 0 ] && done_items+=("agentes en $agents_dir: ${copied[*]}")
fi

# 2. MobiAI Brain y Graph
# Si mobiai no está en el PATH del hook, se busca en su ruta de instalación.
mobiai_bin="$(command -v mobiai 2>/dev/null)"
if [ -z "$mobiai_bin" ]; then
  for c in "$HOME/.mobiai/bin/mobiai" "$HOME/.mobiai/bin/mobiai.exe" \
           "${USERPROFILE:-}/.mobiai/bin/mobiai.exe"; do
    [ -x "$c" ] && { mobiai_bin="$c"; break; }
  done
fi
if [ "${MOBIAI_AUTO_INIT:-1}" != "0" ] && [ -n "$mobiai_bin" ]; then
  if [ ! -f ".mobiai/brain/config.json" ]; then
    "$mobiai_bin" brain init -y --root "$root" >&2 && done_items+=("MobiAI brain init")
  fi
  if [ -f ".mobiai/brain/config.json" ] && [ ! -f ".mobiai/brain/scan.json" ]; then
    "$mobiai_bin" brain scan -y --root "$root" >&2 && done_items+=("MobiAI brain scan")
  fi
  if [ ! -f ".mobiai/graph/index.json" ]; then
    "$mobiai_bin" graph init -y --root "$root" >&2 && done_items+=("MobiAI graph init")
  fi
elif [ "${MOBIAI_AUTO_INIT:-1}" != "0" ]; then
  say "general-mobile: no se encontró el CLI mobiai; MobiAI Brain y Graph no se han inicializado."
fi

# 3. AGENTS.md con las reglas de RULES.md
# Las reglas van al principio de AGENTS.md, entre marcadores: si AGENTS.md no
# existe se crea; si existe, el bloque se coloca (o se mueve) arriba del todo y
# se actualiza con el contenido actual de RULES.md, conservando el resto.
rules_file="$plugin_root/RULES.md"
if [ "${AGENTS_MD_AUTO_RULES:-1}" != "0" ] && [ -f "$rules_file" ]; then
  begin_mark="<!-- general-mobile:rules:begin -->"
  end_mark="<!-- general-mobile:rules:end -->"
  had_file=0; had_block=0
  [ -e AGENTS.md ] && had_file=1
  [ $had_file = 1 ] && grep -qF "$begin_mark" AGENTS.md && had_block=1
  tmp="$(mktemp)"
  {
    echo "$begin_mark"
    tr -d "$cr" < "$rules_file"
    echo
    echo "$end_mark"
    if [ $had_file = 1 ]; then
      # Resto de AGENTS.md sin el bloque anterior ni las líneas en blanco iniciales.
      rest="$(tr -d "$cr" < AGENTS.md | awk -v b="$begin_mark" -v e="$end_mark" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        skip { next }
        !started && $0 ~ /^[[:space:]]*$/ { next }
        { started = 1; print }
      ')"
      [ -n "$rest" ] && { echo; printf '%s\n' "$rest"; }
    fi
  } > "$tmp"
  if [ $had_file = 0 ]; then
    cat "$tmp" > AGENTS.md && done_items+=("AGENTS.md creado con las reglas de RULES.md")
  elif ! cmp -s "$tmp" AGENTS.md; then
    if [ $had_block = 1 ]; then msg="reglas de RULES.md actualizadas al principio de AGENTS.md"
    else msg="reglas de RULES.md añadidas al principio de AGENTS.md"; fi
    cat "$tmp" > AGENTS.md && done_items+=("$msg")
  fi
  rm -f "$tmp"
fi

if [ ${#done_items[@]} -gt 0 ]; then
  say "Proyecto inicializado por general-mobile:"
  for item in "${done_items[@]}"; do say "  - $item"; done
fi
finish
