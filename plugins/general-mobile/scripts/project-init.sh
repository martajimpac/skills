#!/usr/bin/env bash
# Prepara un proyecto mobile la primera vez que se abre una sesión (Claude Code o Cursor):
#   1. Copia los agentes SDD del plugin a .claude/agents (Claude Code) o .cursor/agents (Cursor).
#   2. Inicializa MobiAI Brain y Graph si MobiAI está instalado.
# Idempotente: nunca sobrescribe agentes existentes ni reinicializa MobiAI.
# Uso: project-init.sh [claude|cursor]
# Desactivar: SDD_AGENTS_AUTO_COPY=0 (agentes) / MOBIAI_AUTO_INIT=0 (MobiAI).

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

if [ ${#done_items[@]} -gt 0 ]; then
  say "Proyecto inicializado por general-mobile:"
  for item in "${done_items[@]}"; do say "  - $item"; done
fi
finish
