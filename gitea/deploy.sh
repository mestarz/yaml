#!/bin/bash
set -e

DEPLOY_DIR="/data/gitea-server"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ============ 1. 检查 Docker 环境 ============
if ! command -v docker &>/dev/null; then
  echo ">>> Docker 未安装，开始安装..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
  echo ">>> Docker 安装完成"
fi

# 判断 compose 命令
if docker compose version &>/dev/null; then
  COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  echo ">>> docker-compose 未安装，开始安装..."
  curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  COMPOSE="docker-compose"
  echo ">>> docker-compose 安装完成"
fi

# ============ 2. 创建部署目录 ============
echo ">>> 创建部署目录 ${DEPLOY_DIR}"
mkdir -p "${DEPLOY_DIR}/data"

# ============ 3. 复制 docker-compose.yml ============
echo ">>> 复制 docker-compose.yml 到 ${DEPLOY_DIR}"
cp "${SCRIPT_DIR}/docker-compose.yml" "${DEPLOY_DIR}/docker-compose.yml"

# ============ 4. 启动服务 ============
echo ">>> 拉取镜像并启动容器"
cd "${DEPLOY_DIR}"
${COMPOSE} up -d

echo ">>> 部署完成！访问地址: http://<服务器IP>:9091"
