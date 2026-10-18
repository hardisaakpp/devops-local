# devops-local (Fases 1 a 4)
Gitea :3030 (ssh :2222) · SonarQube :9000 · act_runner. Credenciales en `credenciales.txt` (no versionado).
- Levantar: `docker compose up -d`   · Bajar: `docker compose down` (los datos persisten en volúmenes)
- Pipeline de ejemplo: rama `ci/gitea-local` de web-scnexus (`.gitea/workflows/ci.yml`).
- Nuevo proyecto: crear repo en Gitea, crear proyecto en Sonar, definir secrets SONAR_TOKEN / SONAR_HOST_URL (=http://sonarqube:9000).
- Fase 2 (Grafana/Loki): el puerto 3100 del host está ocupado; mapear Loki a otro.
- Fase 4: Alertmanager envía las alertas por SMTP a Mailpit (buzón local, UI http://localhost:8025). Tempo recibe trazas OTLP en :4317 (gRPC) / :4318 (HTTP) y está como datasource en Grafana (Explore → Tempo). Verificado con una traza sintética; ninguna app envía trazas todavía.
- Proyecto nuevo: `./nuevo-proyecto.sh <nombre>` crea el repo en Gitea, el proyecto en Sonar y los secretos. Pipelines hechos: `web-scnexus` (Vue, rama `ci/gitea-local`) y `api-stockline` (.NET, rama `ci/gitea-local`: 432 tests, 92.9 % cobertura).
- Pipelines en verde (rama local `ci/gitea-local` de cada repo, `.gitea/workflows/ci.yml`): web-scnexus, api-stockline (432 tests, 92.9 %), api-core-scnexus (30, 5.9 %), api-middleware-sap (83 unitarios, 16.2 %), api-odc-mba3 (923, 39.4 %, con servicio Redis). Notas: .NET con Sonar va sin warnaserror; core compila su proyecto de tests dentro de dotnet test; middleware usa un .sln temporal (el .slnx no lo lee el SDK 8); odc usa `ENV_FILE=deploy/env/prod.env.example`.
- Trazas: api-stockline tiene OpenTelemetry opcional en la rama local `feat/opentelemetry` (activa solo con OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318); verificado en Tempo.
