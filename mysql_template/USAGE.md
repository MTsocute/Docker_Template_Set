# MySQL Docker 模板 - 简单使用指南

---

## 🚀 三种启动方式（任选其一）

### 方式 1：使用主启动脚本（推荐）

```bash
# 启动单节点（开发/测试）
./start.sh single

# 启动集群（生产环境）
./start.sh cluster
```

### 方式 2：进入对应目录启动

```bash
# 单节点
cd single-node
./start.sh

# 集群
cd cluster
./start.sh
```

### 方式 3：直接使用 docker-compose

```bash
# 单节点
cd single-node
docker-compose up -d

# 集群
cd cluster
docker-compose up -d
```

## 📋 常用管理命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 进入 MySQL 容器
docker-compose exec mysql bash           # 单节点
docker-compose exec mysql-master bash    # 集群主库
docker-compose exec mysql-slave bash     # 集群从库

# 连接数据库
docker-compose exec mysql mysql -uroot -p              # 单节点
docker-compose exec mysql-master mysql -uroot -p       # 集群主库
docker-compose exec mysql-slave mysql -uroot -p        # 集群从库
```

## 🛠️ 工具脚本

```bash
# 数据备份
./scripts/backup.sh

# 数据恢复
./scripts/restore.sh backup.sql.gz

# 健康检查
./scripts/health-check.sh
```
