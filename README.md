# Flashbox DevOps Practical Assignment

Small API, Redis queue, worker, and static web app deployed to DigitalOcean with Terraform and GitHub Actions.

## Architecture
- API: Express; `GET /health` returns 200 and `GET /` publishes a Redis message.
- Worker: blocks on Redis and logs received messages.
- Web: static HTML served by Nginx; `/api/` proxies to API.
- Redis: internal Compose service, not exposed publicly.
- CI/CD: tests and builds first, publishes immutable SHA-tagged images to GHCR, then deploys over SSH.
- Production (`main`) and staging (`staging`) each run on their own droplet, both on port 80.

### Why a second droplet for staging
- Full isolation: a broken or overloaded staging deploy cannot take CPU, memory or disk from production.
- Both environments serve on port 80, so the firewall stays limited to SSH, HTTP and HTTPS.
- Staging is an exact copy of production, so what passes on staging behaves the same on prod.
- The extra cost is one smallest-size droplet, which is small and destroyed after review.

## Prerequisites
Node.js 22, npm, Docker + Compose, Terraform >= 1.5, GitHub account, DigitalOcean account, SSH key.

## Local development
Run the API tests:
```bash
cd api && npm install && npm test && cd ..
```
The Compose file uses prebuilt images (the same file is used on the droplet), so build them first:
```bash
docker build -t flashbox-api:local ./api
docker build -t flashbox-worker:local ./worker
docker build -t flashbox-web:local ./web
```
Create `deploy/.env` (gitignored) with:
```
API_IMAGE=flashbox-api:local
WORKER_IMAGE=flashbox-worker:local
WEB_IMAGE=flashbox-web:local
APP_ENV=local
WEB_PORT=8080
```
Then start the stack and open `http://localhost:8080`:
```bash
docker compose --env-file deploy/.env -f deploy/docker-compose.yml up -d
curl http://localhost:8080/api/health
curl http://localhost:8080/api/
docker compose --env-file deploy/.env -f deploy/docker-compose.yml logs -f worker
```

## Terraform
1. Add your public SSH key in DigitalOcean and copy its fingerprint.
2. `cp terraform/terraform.tfvars.example terraform/terraform.tfvars` and set fingerprint.
3. Set `DIGITALOCEAN_TOKEN` in your shell (never commit it).
4. `cd terraform && terraform init && terraform validate && terraform plan && terraform apply`.
5. `terraform output droplet_ips` prints the `prod` and `staging` IPs.

## GitHub setup
- Add repository Actions secrets:
  - `DO_HOST_PROD`: prod droplet IP
  - `DO_HOST_STAGING`: staging droplet IP
  - `DO_SSH_PRIVATE_KEY`: private key matching the public key added to DigitalOcean
- The workflow uses `GITHUB_TOKEN` to push images to GHCR, and logs the droplet in to GHCR for the pull (token sent over stdin, logged out after deploy), so packages can stay private.
- The first deploy waits for the droplet's cloud-init (Docker install) to finish.
- SSH access in this sample assumes root login with the configured key. Restrict SSH source IPs when practical.

## CI/CD
Push to `main` to deploy production; push to `staging` to deploy staging. Tests and image builds must pass before deployment. Image tags are commit SHAs, not `latest`.

## Rollback
The deployment script stores the previous image environment file and automatically restores it if the post-deploy health check fails. Manual rollback: `ssh root@PROD_IP 'cd /opt/flashbox && ./rollback.sh prod'`, or `ssh root@STAGING_IP 'cd /opt/flashbox && ./rollback.sh staging'`.

## Live URLs
- Production: `http://PROD_IP/`
- Staging: `http://STAGING_IP/`

## What took the longest / what I looked up
Fill this in honestly after completing the assignment.

## What I would change for 50x traffic and sensitive user data
I would run multiple API replicas behind a load balancer and scale them horizontally. I would move Redis to a managed, highly available service with persistence and monitoring. I would use a managed database with encrypted storage, automated backups, and tested recovery. I would serve static assets through a CDN. I would add TLS, a WAF, rate limiting, and request validation. Secrets would move to a cloud secrets manager with least-privilege access. I would encrypt sensitive data in transit and at rest and audit access. I would centralize logs and metrics, add tracing and alerting, and define SLOs. I would use autoscaling and deployment strategies such as rolling or canary releases. I would regularly test disaster recovery and security controls.
