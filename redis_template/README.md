# Redis Docker 模板

这是一个简单的 Redis Docker 部署模板，包含了 Redis 服务器和 Web 管理界面。

## 包含的服务

- **Redis 服务器**: Redis 7 Alpine 版本
- **Redis Commander**: Web 界面管理工具

## 快速开始

1. 启动服务：
```bash
docker-compose up -d
```

2. 访问服务：
- Redis 服务器: `localhost:6379`
- Web 管理界面: `http://localhost:8081`

3. 停止服务：
```bash
docker-compose down
```

## 配置说明

### Redis 配置
- 配置文件: `redis.conf`
- 数据持久化: 开启 AOF 和 RDB
- 内存限制: 256MB
- 内存策略: allkeys-lru

### 安全配置
如需启用密码认证，编辑 `redis.conf` 文件：
```
requirepass your_password_here
```

### 数据持久化
数据存储在 Docker volume `redis_data` 中，即使容器重启数据也不会丢失。

## 连接 Redis

### 使用命令行
```bash
# 进入 Redis 容器
docker exec -it redis_server redis-cli

# 或者从主机连接
redis-cli -h localhost -p 6379
```

### 使用程序连接
```python
import redis
r = redis.Redis(host='localhost', port=6379, db=0)
```


## 服务控制脚本

你可以使用 `control.sh` 快速管理 Redis 服务：

```bash
./control.sh logs   # 查看 Redis 日志
./control.sh stop   # 停止 Redis 服务
./control.sh cli    # 进入 Redis CLI
```

## 自定义配置

可以根据需要修改：
- `docker-compose.yml`: 端口、网络配置
- `redis.conf`: Redis 服务器配置
