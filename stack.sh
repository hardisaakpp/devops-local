#!/usr/bin/env bash
# Levanta/baja grupos de servicios locales sin tocar los compose de cada repo.
# Uso: ./stack.sh <up|down|status> <grupo>...      grupos: trabajo ia legado infra obs todo
set -euo pipefail

D=~/Documents
# El compose del directorio (Samba AD de desarrollo) exige esta clave; el mismo valor por defecto que su up.sh.
export DIRECTORY_ADMIN_PASSWORD="${DIRECTORY_ADMIN_PASSWORD:-Dir-Admin-2026!}"

# grupo -> lista "directorio|archivo-compose" (o "container|nombre" para contenedores sueltos,
# o "systemd|servicio" para un servicio de usuario de systemd)
grupo_trabajo() { # lo que se está desarrollando ahora (portfolio)
  echo "$D/api-careers|docker-compose.yml"
  echo "$D/api-stockline-directory|docker-compose.yml"
  echo "$D/api-stockline-directory/dev/directory|docker-compose.yml"
  echo "systemd|careers-ai"  # CV (PDF, traducción, importación): arranca solo con el equipo; ver careers-ai/systemd
}
grupo_ia() { # agentes de IA
  echo "$D/xia|docker-compose.yml"
  echo "container|stockline-web-xia-1"  # su compose exige XIA_JWT_SECRET en .env; se maneja como contenedor suelto
  echo "container|open-webui"
}
grupo_legado() { # ecosistema scnexus / mba3 / SAP
  echo "$D/api-core-scnexus|docker-compose.local.yml"
  echo "$D/api-odc-mba3|docker-compose.yml|--profile app"
  echo "$D/sap-simulator|docker-compose.yml"
}
grupo_infra() { # CI y calidad (sin observabilidad)
  echo "$HOME/devops-local|docker-compose.yml"
}
grupo_obs() { # observabilidad (profile obs)
  echo "$HOME/devops-local|docker-compose.yml|--profile obs|loki alloy grafana prometheus cadvisor node-exporter alertmanager mailpit tempo"
}

accion_grupo() { # $1=up|down  $2=grupo
  local dir file extra svcs
  while IFS='|' read -r dir file extra svcs; do
    if [ "$dir" = systemd ]; then
      if [ "$1" = up ]; then systemctl --user start "$file"; else systemctl --user stop "$file"; fi
      echo "  $1 servicio $file"
    elif [ "$dir" = container ]; then
      if [ "$1" = up ]; then docker start "$file" >/dev/null; else docker stop "$file" >/dev/null; fi
      echo "  $1 contenedor $file"
    else
      # shellcheck disable=SC2086
      local args=(stop); [ "$1" = up ] && args=(up -d)
      (cd "$dir" && docker compose -f "$file" ${extra:-} "${args[@]}" ${svcs:-} >/dev/null 2>&1) \
        && echo "  $1 $(basename "$dir")/$file" || echo "  FALLÓ $1 $dir/$file"
    fi
  done < <("grupo_$2")
}

cmd=${1:-status}; shift || true
case "$cmd" in
  status) docker ps --format 'table {{.Names}}\t{{.Status}}' ;;
  up|down)
    [ $# -gt 0 ] || { echo "indica grupo(s): trabajo ia legado infra obs todo"; exit 1; }
    gs=("$@"); [ "${gs[0]}" = todo ] && gs=(infra trabajo ia legado obs)
    for g in "${gs[@]}"; do echo "[$g]"; accion_grupo "$cmd" "$g"; done ;;
  *) echo "uso: $0 <up|down|status> <grupo>..."; exit 1 ;;
esac
