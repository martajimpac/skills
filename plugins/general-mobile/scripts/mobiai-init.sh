#!/usr/bin/env bash
# Inicializa MobiAI Brain y Graph en el proyecto la primera vez que se abre una sesión.
# Idempotente: solo actúa si falta .mobiai/brain o .mobiai/graph/index.json.
# Desactivar: exportar MOBIAI_AUTO_INIT=0.

[ "${MOBIAI_AUTO_INIT:-1}" = "0" ] && exit 0
command -v mobiai >/dev/null 2>&1 || exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
# Solo en la raíz de un repositorio git, para no crear .mobiai en carpetas cualquiera.
[ -e "$root/.git" ] || exit 0
cd "$root" || exit 0

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
