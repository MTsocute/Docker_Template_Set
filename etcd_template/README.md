
# etcd Docker Compose 模板

本项目包含两个用于快速搭建 etcd 服务的 Docker Compose 模板：

- `etcd_single`：单节点 etcd，适合开发和简单测试。
- `etcd_cluster`：三节点 etcd 集群，带 nginx 代理，适合高可用和分布式测试。

## 目录结构

- `etcd_single/docker-compose.yml`：单节点配置
- `etcd_cluster/docker-compose.yml`：集群配置

## 使用方法

1. 进入对应目录：
	- 单节点：`cd etcd_single`
	- 集群：`cd etcd_cluster`

2. 启动服务：
	```bash
	docker-compose up -d
	```

3. 停止服务：
	```bash
	docker-compose down
	```

## 端口说明

- 单节点：2379 (客户端), 2380 (集群)
- 集群：nginx 代理 2379，所有节点各自 2379/2380

## 数据持久化

所有 etcd 节点数据均持久化到本地卷，重启容器数据不丢失。

## 依赖

- Docker
- Docker Compose

## 常见问题

- 端口冲突请修改 `docker-compose.yml` 配置
- 查看日志：`docker-compose logs`

