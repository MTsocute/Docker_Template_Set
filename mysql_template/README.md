# MySQL Docker 模板

这是一个通用的 MySQL Docker 部署模板，支持单节点和主从集群两种部署方式。可以快速在任何环境中启动 MySQL 服务。

## 目录结构

```
mysql-template/
├── README.md                   # 项目说明文档
├── QUICKSTART.md               # 快速开始指南
├── .env.example                # 环境变量示例文件
├── .gitignore                  # Git忽略文件
├── start.sh                    # 主启动脚本
├── single-node/                # 单节点部署
│   ├── docker-compose.yml
│   ├── my.cnf
│   └── start.sh
├── cluster/                    # 主从集群部署
│   ├── docker-compose.yml
│   ├── master/
│   │   ├── my.cnf
│   │   └── setup-replication.sql
│   ├── slave/
│   │   ├── my.cnf
│   │   └── setup-slave.sql
│   └── start.sh
├── scripts/                   # 工具脚本
│   ├── backup.sh              # 数据备份脚本
│   ├── restore.sh             # 数据恢复脚本
│   └── health-check.sh        # 健康检查脚本
└── init/                      # 初始化 SQL 脚本
    └── sample.sql             # 示例初始化脚本
```

## 快速开始

### 1. 环境准备

```bash
# 克隆或下载模板
git clone <this-template> mysql-project
cd mysql-project

# 复制环境变量文件并根据需要修改
cp .env.example .env
```

### 2. 单节点部署

单节点部署适合开发环境、测试环境或小型项目使用。

```bash
cd single-node
chmod +x start.sh
./start.sh
```

### 3. 集群部署（主从复制）

集群部署适合生产环境，提供读写分离和数据冗余。

```bash
cd cluster
chmod +x start.sh
./start.sh
```

## 详细配置说明

### 环境变量配置

编辑 `.env` 文件来配置数据库参数：

| 变量名                  | 默认值      | 说明                |
| ----------------------- | ----------- | ------------------- |
| `MYSQL_ROOT_PASSWORD` | `123456`  | MySQL root 用户密码 |
| `MYSQL_DATABASE`      | `myapp`   | 默认创建的数据库名  |
| `MYSQL_USER`          | `appuser` | 应用用户名          |
| `MYSQL_PASSWORD`      | `apppass` | 应用用户密码        |
| `MYSQL_PORT`          | `3306`    | MySQL 对外端口      |

### 单节点配置

- **容器名称**: mysql-standalone
- **端口映射**: 3306:3306
- **数据持久化**: ./volumes/mysql-data
- **配置文件**: ./single-node/my.cnf
- **初始化脚本**: ./init/*.sql

### 集群配置

#### 主节点（Master）

- **容器名称**: mysql-master
- **端口映射**: 3306:3306
- **数据持久化**: ./volumes/mysql-master-data

#### 从节点（Slave）

- **容器名称**: mysql-slave
- **端口映射**: 3307:3306
- **数据持久化**: ./volumes/mysql-slave-data

## 使用说明

### 连接数据库

#### 单节点

```bash
mysql -h localhost -P 3306 -u root -p
```

#### 集群

```bash
# 连接主节点（写操作）
mysql -h localhost -P 3306 -u root -p

# 连接从节点（读操作）
mysql -h localhost -P 3307 -u root -p
```

### 自定义初始化脚本

1. 将你的 SQL 脚本放在 `init/` 目录下
2. 脚本将在容器首次启动时自动执行
3. 脚本按文件名字典序执行

### 数据备份与恢复

```bash
# 备份数据
./scripts/backup.sh

# 恢复数据
./scripts/restore.sh backup-20231024.sql
```

### 健康检查

```bash
# 检查服务状态
./scripts/health-check.sh
```

## 停止服务

### 单节点

```bash
cd single-node
docker-compose down
```

### 集群

```bash
cd cluster
docker-compose down
```

## 删除数据（谨慎操作）

```bash
# 停止服务并删除数据卷
docker-compose down -v

# 手动清理数据目录
rm -rf volumes/mysql-data/*
rm -rf volumes/logs/*
```

## 注意事项

1. **生产环境建议**：

   - 修改默认密码
   - 使用外部数据卷
   - 配置防火墙规则
   - 定期备份数据
2. **性能优化**：

   - 根据服务器配置调整 my.cnf 参数
   - 合理设置内存和连接数限制
3. **安全建议**：

   - 不要在生产环境中使用默认密码
   - 限制数据库访问 IP 范围
   - 定期更新 MySQL 镜像版本

## 故障排查

### 常见问题

1. **容器启动失败**

   ```bash
   docker logs mysql-standalone
   ```
2. **无法连接数据库**

   - 检查端口是否被占用
   - 确认防火墙设置
   - 验证密码是否正确
3. **主从同步异常**

   ```bash
   # 在主节点检查
   SHOW MASTER STATUS;

   # 在从节点检查
   SHOW SLAVE STATUS\G
   ```

## 版本信息

- MySQL: 8.0
- Docker Compose: 3.8+
