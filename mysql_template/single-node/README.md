# MySQL 单节点 Docker 快速启动模板

## 快速开始

1. **启动 MySQL 容器**

```shell
./mysql_control.sh start
```

2. **查看容器状态**

```shell
./mysql_control.sh status
```

3. **查看 MySQL 日志**

```shell
./mysql_control.sh logs
```

4. **停止 MySQL 容器**

```shell
./mysql_control.sh stop
```

## 目录结构

- `docker-compose.yml`：MySQL 服务的 Docker Compose 配置
- `mysql_control.sh`：一键控制脚本（启动/停止/状态/日志）
- `data/`：MySQL 数据持久化目录（自动生成）
- `init/`：初始化 SQL 文件目录（可选）

## 默认配置
- root 密码：`123456`
- 默认数据库：`testdb`
- 默认用户：`testuser`，密码：`testpass`

## 其他说明
- 如需自定义初始化 SQL，可将 `.sql` 文件放入 `init/` 目录。
- 如需修改端口、密码等参数，请编辑 `docker-compose.yml`。

---

如有问题欢迎反馈。
