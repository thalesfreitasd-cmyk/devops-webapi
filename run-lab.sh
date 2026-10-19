#!/usr/bin/env bash
# Executa o laboratório e registra a saída real de cada passo em evidencias/log.txt
# Uso (dentro da pasta DevOpsWebApi):  bash run-lab.sh
set -u
mkdir -p evidencias; LOG=evidencias/log.txt; : > "$LOG"
step(){ echo -e "\n=================== $1 ===================" | tee -a "$LOG"; }
run(){ echo "\$ $*" | tee -a "$LOG"; "$@" 2>&1 | tee -a "$LOG"; echo "[exit code: ${PIPESTATUS[0]}]" | tee -a "$LOG"; }
deploy(){ # nome porta env versao
  docker rm -f "$1" >/dev/null 2>&1
  run docker run -d --name "$1" -p "$2:8080" -e APP_ENVIRONMENT="$3" -e APP_VERSION="$4" devops-webapi:"$4"; sleep 4; }

step "PASSO 0 - Pre-requisitos"
run docker --version; run dotnet --version; run git --version
run docker run --rm hello-world

step "BUILD 1.0.0"
cp versions/Program.1.0.0.cs Program.cs
run docker build -t devops-webapi:1.0.0 .
step "STAGING e PRODUCTION 1.0.0"
deploy devops-api-staging 8081 staging 1.0.0
deploy devops-api-prod 8082 production 1.0.0
run curl -s http://localhost:8081/; run curl -s http://localhost:8082/

step "BUILD 1.1.0 (staging primeiro)"
cp versions/Program.1.1.0.cs Program.cs
run docker build -t devops-webapi:1.1.0 .
run docker images devops-webapi
deploy devops-api-staging 8081 staging 1.1.0
run curl -f http://localhost:8081/health; run curl -s http://localhost:8081/version
step "PROMOCAO 1.1.0 -> PRODUCTION"
deploy devops-api-prod 8082 production 1.1.0
run curl -f http://localhost:8082/health
run docker ps

step "RELEASE 1.2.0 COM FALHA (staging)"
cp versions/Program.1.2.0.cs Program.cs
run docker build -t devops-webapi:1.2.0 .
deploy devops-api-staging 8081 staging 1.2.0
run curl -f -i http://localhost:8081/health
step "INCIDENTE: 1.2.0 em PRODUCTION"
deploy devops-api-prod 8082 production 1.2.0
run curl -f -i http://localhost:8082/health

step "ROLLBACK PRODUCTION -> 1.1.0"
deploy devops-api-prod 8082 production 1.1.0
run curl -f http://localhost:8082/health
run docker ps
cp versions/Program.1.1.0.cs Program.cs

step "DOCKER COMPOSE"
docker rm -f devops-api-staging devops-api-prod >/dev/null 2>&1
run docker compose up -d; sleep 4
run docker compose ps
run curl -f http://localhost:8081/health; run curl -f http://localhost:8082/health
run docker compose config
run docker compose down
echo -e "\nConcluido. Log em $LOG"
