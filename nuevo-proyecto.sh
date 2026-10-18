#!/usr/bin/env bash
# Uso: ./nuevo-proyecto.sh <nombre>  -> crea repo en Gitea, proyecto en SonarQube y secretos del CI
set -euo pipefail
N="$1"; cd "$(dirname "$0")"
g() { grep "^$1=" credenciales.txt | cut -d= -f2-; }
GT=$(g gitea_api_token); SP=$(g sonar_password); ST=$(g sonar_token_ci)
curl -sf -H "Authorization: token $GT" -X POST localhost:3030/api/v1/user/repos -H 'Content-Type: application/json' -d "{\"name\":\"$N\",\"private\":true}" >/dev/null || echo "(repo ya existía)"
curl -s -u "admin:$SP" -X POST localhost:9000/api/projects/create -d project="$N" -d name="$N" >/dev/null
for kv in "SONAR_TOKEN:$ST" "SONAR_HOST_URL:http://sonarqube:9000"; do
  curl -sf -o /dev/null -H "Authorization: token $GT" -X PUT "localhost:3030/api/v1/repos/isaac/$N/actions/secrets/${kv%%:*}" -H 'Content-Type: application/json' -d "{\"data\":\"${kv#*:}\"}"
done
echo "Listo. Push: git push http://isaac:<token>@localhost:3030/isaac/$N.git <rama>"
