#!/bin/bash
set -e

DEPLOY_DIR="/data/gitea-server"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ============ 1. 检查 Docker 环境 ============
if ! command -v docker &>/dev/null; then
  echo ">>> Docker 未安装，使用阿里云镜像安装..."
  curl -fsSL https://get.docker.com | sh -s -- --mirror Aliyun
  systemctl enable --now docker
  echo ">>> Docker 安装完成"
fi

# 配置 Docker 镜像加速（如果尚未配置）
DAEMON_JSON="/etc/docker/daemon.json"
if [ ! -f "${DAEMON_JSON}" ] || ! grep -q "registry-mirrors" "${DAEMON_JSON}" 2>/dev/null; then
  echo ">>> 配置 Docker 镜像加速源..."
  mkdir -p /etc/docker
  cat > "${DAEMON_JSON}" <<'MIRRORS'
{
  "registry-mirrors": [
    "https://docker.1ms.run",
    "https://docker.xuanyuan.me"
  ]
}
MIRRORS
  systemctl daemon-reload
  systemctl restart docker
  echo ">>> 镜像加速配置完成"
fi

# 判断 compose 命令
if docker compose version &>/dev/null; then
  COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  echo ">>> docker-compose 未安装，开始安装..."
  COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
  # 国内使用 ghproxy 加速下载
  curl -fsSL "https://ghfast.top/${COMPOSE_URL}" -o /usr/local/bin/docker-compose \
    || curl -fsSL "${COMPOSE_URL}" -o /usr/local/bin/docker-compose
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

# ============ 5. 限制访问：仅允许 VPN 网段 10.8.0.0/24 ============
echo ">>> 配置防火墙：仅允许 10.8.0.0/24 访问"
# Docker 推荐使用 DOCKER-USER 链来过滤容器流量
iptables -C DOCKER-USER -p tcp --dport 3000 -s 10.8.0.0/24 -j ACCEPT 2>/dev/null \
  || iptables -I DOCKER-USER -p tcp --dport 3000 -s 10.8.0.0/24 -j ACCEPT
iptables -C DOCKER-USER -p tcp --dport 22 -s 10.8.0.0/24 -j ACCEPT 2>/dev/null \
  || iptables -I DOCKER-USER -p tcp --dport 22 -s 10.8.0.0/24 -j ACCEPT
iptables -C DOCKER-USER -p tcp --dport 3000 -j DROP 2>/dev/null \
  || iptables -A DOCKER-USER -p tcp --dport 3000 -j DROP
iptables -C DOCKER-USER -p tcp --dport 22 -j DROP 2>/dev/null \
  || iptables -A DOCKER-USER -p tcp --dport 22 -j DROP

# 持久化 iptables 规则，重启不丢失
echo ">>> 持久化 iptables 规则"
if ! dpkg -l iptables-persistent &>/dev/null; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
fi
netfilter-persistent save

echo ">>> 部署完成！仅 VPN 网段可访问: http://10.8.0.x:9091"
