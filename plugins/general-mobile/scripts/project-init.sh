#!/usr/bin/env bash
# Prepara un proyecto mobile cuando se instala o se actualiza el plugin general-mobile
# (Claude Code o Cursor):
#   1. Copia los agentes SDD del plugin a .claude/agents (Claude Code) o .cursor/agents (Cursor).
#   2. Inicializa MobiAI Brain (init + scan) y Graph si MobiAI está instalado.
#   3. Pone las reglas de RULES.md del plugin al principio de AGENTS.md (lo crea si no existe).
#
# No existe un evento de "plugin instalado/actualizado". En Claude Code lo lanza un
# monitor del plugin (monitors/monitors.json), que arranca al iniciar la sesión y al
# instalar, actualizar o recargar plugins, y como respaldo el hook UserPromptSubmit.
# Este script decide comparando la versión
# del plugin con la marca guardada en el proyecto (.claude/general-mobile.version o
# .cursor/general-mobile.version):
#   - sin marca        -> instalación: hace los tres pasos.
#   - otra versión     -> actualización: actualiza agentes y AGENTS.md, y completa MobiAI
#                         si falta algo (nunca lo reinicializa).
#   - misma versión    -> no hace nada.
# Al actualizar, un agente solo se sobrescribe si no se ha modificado a mano desde que
# lo copió el plugin (se comprueba con el hash guardado en la marca).
#
# Uso: project-init.sh [claude|cursor] [ruta-del-proyecto]
#   Con ruta (monitor) no se lee stdin; sin ruta (hooks) la ruta sale del JSON del hook.
# Forzar de nuevo: borrar la marca. Desactivar: SDD_AGENTS_AUTO_COPY=0 (agentes) /
#   MOBIAI_AUTO_INIT=0 (MobiAI) / AGENTS_MD_AUTO_RULES=0 (AGENTS.md).

client="${1:-claude}"
plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cr="$(printf '\r')"

arg_root="${2:-}"

# Los hooks reciben JSON por stdin (Claude Code y Cursor). El monitor pasa la ruta
# como argumento y no se lee stdin, que podría quedarse abierto.
stdin_json=""
if [ -z "$arg_root" ] && [ ! -t 0 ]; then
  stdin_json="$(cat)"
fi
json_field() {
  printf '%s' "$stdin_json" | tr -d '\n' \
    | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

# Cursor espera JSON por stdout; los mensajes van a stderr.
say() {
  if [ "$client" = "cursor" ]; then echo "$*" >&2; else echo "$*"; fi
}
finish() {
  [ "$client" = "cursor" ] && echo '{}'
  exit 0
}

root="${arg_root:-${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-}}}"
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

# Versión del plugin y marca del proyecto.
if [ "$client" = "cursor" ]; then
  client_dir=".cursor"; manifest="$plugin_root/.cursor-plugin/plugin.json"
else
  client_dir=".claude"; manifest="$plugin_root/.claude-plugin/plugin.json"
fi
plugin_version="$(tr -d '\n' < "$manifest" 2>/dev/null \
  | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -n "$plugin_version" ] || plugin_version="desconocida"
marker="$client_dir/general-mobile.version"
installed_version=""
[ -f "$marker" ] && installed_version="$(sed -n 's/^version=//p' "$marker" | tr -d "$cr")"

[ -n "$installed_version" ] && [ "$installed_version" = "$plugin_version" ] && finish

# Bloqueo para que el monitor y el hook no preparen el proyecto a la vez. Un
# bloqueo de más de 15 minutos se considera abandonado.
lock="$client_dir/.general-mobile.lock"
mkdir -p "$client_dir"
if ! mkdir "$lock" 2>/dev/null; then
  if [ -n "$(find "$lock" -maxdepth 0 -mmin +15 2>/dev/null)" ]; then
    rm -rf "$lock" && mkdir "$lock" 2>/dev/null || finish
  else
    finish
  fi
fi
trap 'rm -rf "$lock"' EXIT
# Otro proceso pudo terminar justo antes de tomar el bloqueo.
[ -f "$marker" ] && installed_version="$(sed -n 's/^version=//p' "$marker" | tr -d "$cr")"
[ "$installed_version" = "$plugin_version" ] && finish

if [ -z "$installed_version" ]; then mode="install"; else mode="update"; fi

hash_of() { cksum < "$1" | cut -d' ' -f1-2; }
recorded_hash() { sed -n "s/^agent $1 //p" "$marker" 2>/dev/null | tr -d "$cr"; }

done_items=()
new_marker=("version=$plugin_version")

# 1. Agentes SDD
if [ "${SDD_AGENTS_AUTO_COPY:-1}" != "0" ] && [ -d "$plugin_root/agents" ]; then
  agents_dir="$client_dir/agents"
  copied=(); updated=(); kept=()
  for src in "$plugin_root"/agents/*.md; do
    [ -f "$src" ] || continue
    name="$(basename "$src")"
    dest="$agents_dir/$name"
    if [ ! -e "$dest" ]; then
      mkdir -p "$agents_dir" && cp "$src" "$dest" && copied+=("${name%.md}")
    elif cmp -s "$src" "$dest"; then
      :  # ya está al día
    elif [ "$mode" = "update" ] && [ "$(recorded_hash "$name")" = "$(hash_of "$dest")" ]; then
      # Sin cambios manuales desde que lo copió el plugin: se actualiza.
      cp "$src" "$dest" && updated+=("${name%.md}")
    else
      kept+=("${name%.md}")
    fi
    # Solo se registran los agentes que coinciden con los del plugin; los modificados
    # a mano quedan sin registrar y no se sobrescriben en futuras actualizaciones.
    [ -f "$dest" ] && cmp -s "$src" "$dest" && new_marker+=("agent $name $(hash_of "$dest")")
  done
  [ ${#copied[@]} -gt 0 ] && done_items+=("agentes copiados a $agents_dir: ${copied[*]}")
  [ ${#updated[@]} -gt 0 ] && done_items+=("agentes actualizados en $agents_dir: ${updated[*]}")
  [ "$mode" = "update" ] && [ ${#kept[@]} -gt 0 ] && \
    done_items+=("agentes con cambios propios, no sobrescritos: ${kept[*]}")
fi

# 2. MobiAI Brain y Graph (solo los pasos que falten; nunca se reinicializa).
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

# Marca con la versión aplicada.
mkdir -p "$client_dir" && printf '%s\n' "${new_marker[@]}" > "$marker"

if [ "$mode" = "install" ]; then
  say "general-mobile $plugin_version instalado en el proyecto:"
else
  say "general-mobile actualizado de $installed_version a $plugin_version en el proyecto:"
fi
if [ ${#done_items[@]} -gt 0 ]; then
  for item in "${done_items[@]}"; do say "  - $item"; done
else
  say "  - todo estaba ya al día"
fi
finish
