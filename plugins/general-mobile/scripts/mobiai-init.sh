#!/usr/bin/env bash
# Inicializa MobiAI Brain y Graph en el proyecto la primera vez que se abre una sesión.
# Idempotente: solo actúa si falta .mobiai/brain o .mobiai/graph/index.json.
# Desactivar: exportar MOBIAI_AUTO_INIT=0.

[ "${MOBIAI_AUTO_INIT:-1}" = "0" ] && exit 0
command -v mobiai >/dev/null 2>&1 || exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$root" || exit 0

# Solo en proyectos móviles, para no crear .mobiai en carpetas cualquiera.
is_mobile_project() {
  # Android / KMP
  [ -f settings.gradle ] || [ -f settings.gradle.kts ] && return 0
  # iOS
  compgen -G "*.xcodeproj" >/dev/null || compgen -G "*.xcworkspace" >/dev/null && return 0
  [ -f Package.swift ] && return 0
  # Flutter
  [ -f pubspec.yaml ] && return 0
  # React Native
  [ -f package.json ] && grep -q '"react-native"' package.json && return 0
  return 1
}
is_mobile_project || exit 0

done_items=()
if [ ! -d ".mobiai/brain" ]; then
  mobiai brain init -y --root "$root" >&2 && done_items+=("brain")
fi
if [ ! -f ".mobiai/graph/index.json" ]; then
  mobiai graph init -y --root "$root" >&2 && done_items+=("graph")
fi

if [ ${#done_items[@]} -gt 0 ]; then
  echo "MobiAI inicializado en este proyecto: ${done_items[*]} (.mobiai/)."
fi
exit 0
