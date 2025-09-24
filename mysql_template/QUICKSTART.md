# 快速开始指南

## 一分钟快速启动

### 单节点模式（适合开发/测试）

```bash
./start.sh single
# 或者
cd single-node && ./start.sh
```

### 集群模式（适合生产环境）

```bash
./start.sh cluster
# 或者
cd cluster && ./start.sh
```

## 常用命令

```bash
# 启动服务
./start.sh single           # 单节点模式
./start.sh cluster          # 集群模式

# 停止服务
cd single-node && docker-compose down    # 停止单节点
cd cluster && docker-compose down        # 停止集群

# 查看服务状态
cd single-node && docker-compose ps      # 单节点状态
cd cluster && docker-compose ps          # 集群状态

# 连接数据库
cd single-node && docker-compose exec mysql mysql -uroot -p      # 单节点
cd cluster && docker-compose exec mysql-master mysql -uroot -p   # 集群主库
cd cluster && docker-compose exec mysql-slave mysql -uroot -p    # 集群从库

# 备份和维护
./scripts/backup.sh          # 备份数据
./scripts/health-check.sh    # 健康检查
./scripts/restore.sh backup.sql.gz  # 恢复数据
```

## 默认连接信息

### 单节点

- 主机: `localhost`
- 端口: `3306`
- 用户: `root`
- 密码: `123456`

### 集群

- 主库（写）: `localhost:3306`
- 从库（读）: `localhost:3307`
- 用户: `root`
- 密码: `123456`

## 自定义配置

1. 复制配置文件：`cp .env.example .env`
2. 编辑 `.env` 文件修改密码、端口等配置
3. 重启服务使配置生效

## 注意事项

⚠️ **生产环境请务必修改默认密码！**

详细文档请参考 [README.md](README.md)
