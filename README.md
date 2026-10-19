# Laboratório Docker

API ASP.NET Core (.NET 10) containerizada com Docker, versionada por tags e implantada em staging/production.

## Construção
docker build -t devops-webapi:1.0.0 .

## Execução
docker run -d --name devops-api -p 8080:8080 devops-webapi:1.0.0

## Staging
docker run -d --name devops-api-staging -p 8081:8080 -e APP_ENVIRONMENT=staging -e APP_VERSION=1.0.0 devops-webapi:1.0.0

## Production
docker run -d --name devops-api-prod -p 8082:8080 -e APP_ENVIRONMENT=production -e APP_VERSION=1.0.0 devops-webapi:1.0.0

## Health Check
curl -f http://localhost:8081/health   (Windows: curl.exe)

## Nova versão
docker build -t devops-webapi:1.1.0 .

## Falha controlada
docker build -t devops-webapi:1.2.0 .   # /health retorna HTTP 500 de propósito
curl -f http://localhost:8081/health    # falha: curl retorna erro 22

## Rollback
docker rm -f devops-api-prod
docker run -d --name devops-api-prod -p 8082:8080 -e APP_ENVIRONMENT=production -e APP_VERSION=1.1.0 devops-webapi:1.1.0

## Docker Compose
docker compose up -d
docker compose ps
docker compose down

## Execução automatizada
`versions/` guarda o Program.cs de cada release (1.0.0, 1.1.0, 1.2.0).
`run-lab.sh` (Linux/macOS/Git Bash) executa todo o laboratório e grava as saídas em `evidencias/log.txt`.
