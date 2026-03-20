# yaml

服务器一键部署脚本集合，基于 Docker Compose。

## 目录

| 目录 | 服务 | 说明 |
|------|------|------|
| [gitea/](gitea/) | Gitea | 轻量 Git 托管，SQLite 存储，端口 9091 |
| [openvpn/](openvpn/) | OpenVPN | 一键安装 OpenVPN，来源 [Nyr/openvpn-install](https://github.com/Nyr/openvpn-install) |

## 使用方式

将对应目录拷贝到目标服务器，执行 `bash deploy.sh` 即可。

脚本会自动完成：
- Docker / docker-compose 安装（国内镜像加速）
- 镜像拉取 & 容器启动
- 防火墙配置（仅 VPN 网段 10.8.0.0/24 可访问）