#!/usr/bin/env bash
set -Eeuo pipefail
ENV_NAME="${1:?Usage: deploy.sh prod|staging IMAGE_TAG}"
TAG="${2:?Usage: deploy.sh prod|staging IMAGE_TAG}"
case "$ENV_NAME" in
  prod) WEB_PORT=80; APP_ENV=production ;;
  staging) WEB_PORT=80; APP_ENV=staging ;;
  *) echo "Environment must be prod or staging"; exit 2 ;;
esac

cd /opt/flashbox
ENV_FILE=".env.${ENV_NAME}"
BACKUP_FILE=".previous.${ENV_NAME}"
# Preserve the currently running version for rollback.
if [[ -f "$ENV_FILE" ]]; then cp "$ENV_FILE" "$BACKUP_FILE"; fi

cat > "$ENV_FILE" <<EOF
APP_ENV=${APP_ENV}
WEB_PORT=${WEB_PORT}
API_IMAGE=ghcr.io/${GHCR_OWNER}/flashbox-api:${TAG}
WORKER_IMAGE=ghcr.io/${GHCR_OWNER}/flashbox-worker:${TAG}
WEB_IMAGE=ghcr.io/${GHCR_OWNER}/flashbox-web:${TAG}
EOF

compose() {
  docker compose --project-name "flashbox-${ENV_NAME}" --env-file "$ENV_FILE" -f docker-compose.yml "$@"
}
rollback() {
  echo "Deployment failed; rolling back ${ENV_NAME}..."
  if [[ -f "$BACKUP_FILE" ]]; then
    cp "$BACKUP_FILE" "$ENV_FILE"
    compose pull || true
    compose up -d --remove-orphans
  else
    compose down || true
  fi
}
compose pull
compose up -d --remove-orphans

healthy=false
for attempt in $(seq 1 20); do
  if curl --fail --silent "http://127.0.0.1:${WEB_PORT}/api/health" >/dev/null; then
    healthy=true; break
  fi
  sleep 3
done
if [[ "$healthy" != true ]]; then
  rollback
  exit 1
fi
echo "Deployment ${ENV_NAME} (${TAG}) is healthy."
