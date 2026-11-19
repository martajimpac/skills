#!/usr/bin/env bash
# Prepara un proyecto mobile la primera vez que se abre una sesión (Claude Code o Cursor):
#   1. Copia los agentes SDD del plugin a .claude/agents (Claude Code) o .cursor/agents (Cursor).
#   2. Inicializa MobiAI Brain y Graph si MobiAI está instalado.
#   3. Pone las reglas de RULES.md del plugin al principio de AGENTS.md (lo crea si no existe).
# Idempotente: nunca sobrescribe agentes existentes ni reinicializa MobiAI; en
# AGENTS.md solo toca el bloque de reglas entre marcadores.
# Uso: project-init.sh [claude|cursor]
# Desactivar: SDD_AGENTS_AUTO_COPY=0 (agentes) / MOBIAI_AUTO_INIT=0 (MobiAI) /
#             AGENTS_MD_AUTO_RULES=0 (AGENTS.md).

client="${1:-claude}"
plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# En Cursor el hook recibe JSON por stdin; se lee para obtener workspace_roots.
stdin_json=""
if [ "$client" = "cursor" ] && [ ! -t 0 ]; then
  stdin_json="$(cat)"
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
if [ "${MOBIAI_AUTO_INIT:-1}" != "0" ] && command -v mobiai >/dev/null 2>&1; then
  if [ ! -d ".mobiai/brain" ]; then
    mobiai brain init -y --root "$root" >&2 && done_items+=("MobiAI brain")
  fi
  if [ ! -f ".mobiai/graph/index.json" ]; then
    mobiai graph init -y --root "$root" >&2 && done_items+=("MobiAI graph")
  fi
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
    tr -d '' < "$rules_file"
    echo
    echo "$end_mark"
    if [ $had_file = 1 ]; then
      # Resto de AGENTS.md sin el bloque anterior ni las líneas en blanco iniciales.
      rest="$(awk -v b="$begin_mark" -v e="$end_mark" '
        { line = $0; sub(/$/, "", line) }
        line == b { skip = 1; next }
        line == e { skip = 0; next }
        skip { next }
        !started && line ~ /^[[:space:]]*$/ { next }
        { started = 1; print }
      ' AGENTS.md)"
      [ -n "$rest" ] && { echo; printf '%s
' "$rest"; }
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
