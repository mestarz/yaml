#!/bin/bash
set -e

DEPLOY_DIR="/data/gitea-server"

echo ">>> 创建部署目录 ${DEPLOY_DIR}"
mkdir -p "${DEPLOY_DIR}/data"

echo ">>> 写入 docker-compose.yml（HTTP 端口 9091）"
cat > "${DEPLOY_DIR}/docker-compose.yml" <<'EOF'
services:
  server:
    image: gitea/gitea:1.21.7
    container_name: gitea
    restart: always
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=sqlite3
    networks:
      - gitea_net
    volumes:
      - ./data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "9091:3000"
      - "2222:22"

networks:
  gitea_net:
    driver: bridge
EOF

echo ">>> 拉取镜像并启动容器"
cd "${DEPLOY_DIR}"
docker compose up -d

echo ">>> 部署完成！访问地址: http://<服务器IP>:9091"
