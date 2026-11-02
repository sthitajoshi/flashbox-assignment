#!/usr/bin/env bash
set -Eeuo pipefail
ENV_NAME="${1:?Usage: rollback.sh prod|staging}"
cd /opt/flashbox
ENV_FILE=".env.${ENV_NAME}"
BACKUP_FILE=".previous.${ENV_NAME}"
[[ -f "$BACKUP_FILE" ]] || { echo "No previous version found"; exit 1; }
cp "$BACKUP_FILE" "$ENV_FILE"
# The previous images are already on the droplet, so a failed pull (no GHCR login) is fine.
docker compose --project-name "flashbox-${ENV_NAME}" --env-file "$ENV_FILE" -f docker-compose.yml pull || true
docker compose --project-name "flashbox-${ENV_NAME}" --env-file "$ENV_FILE" -f docker-compose.yml up -d --remove-orphans
