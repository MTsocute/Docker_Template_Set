# Elasticsearch Docker Compose 模板

本项目提供了两种 Elasticsearch 部署方式的 Docker Compose 配置文件。

## 文件说明

- `docker-compose.yml` - 单节点 Elasticsearch + Kibana 配置（使用环境变量）
- `docker-compose-cluster.yml` - 3节点 Elasticsearch 集群 + Kibana 配置（使用环境变量）
- `config/elasticsearch.yml` - Elasticsearch 详细配置文件
- `.env` - 默认环境变量配置文件
- `.env.development` - 开发环境专用配置（低内存，调试模式）
- `.env.production` - 生产环境专用配置（高内存，安全模式）
- `es-manager.sh` - 便捷的管理脚本

## 环境配置

现在所有的 docker-compose 文件都使用环境变量，您可以通过修改 `.env` 文件或使用不同的环境配置文件来自定义设置：

### 默认配置 (.env)
- 适合一般开发和测试
- 内存: 512MB
- 安全: 关闭
- 端口: 9200/5601

### 开发环境配置 (.env.development)
- 适合本地开发
- 内存: 256MB（节省资源）
- 安全: 关闭
- 日志: DEBUG 级别

### 生产环境配置 (.env.production)
- 适合生产部署
- 内存: 2GB
- 安全: 启用（需要配置认证）
- 日志: WARN 级别

## 快速开始

### 单节点模式（推荐用于开发环境）

```bash
# 使用默认配置启动
docker-compose up -d
# 或者使用管理脚本
./es-manager.sh start

# 使用开发环境配置启动（更低内存占用）
./es-manager.sh start-dev
# 等同于
docker-compose --env-file .env.development up -d

# 使用生产环境配置启动
./es-manager.sh start-prod
# 等同于
docker-compose --env-file .env.production up -d

# 查看日志
docker-compose logs -f
# 或者
./es-manager.sh logs

# 停止服务
docker-compose down
# 或者
./es-manager.sh stop
```

### 集群模式（推荐用于生产环境）

```bash
# 使用默认配置启动集群
docker-compose -f docker-compose-cluster.yml up -d
# 或者使用管理脚本
./es-manager.sh start-cluster

# 使用生产环境配置启动集群
./es-manager.sh start-cluster .env.production
# 等同于
docker-compose --env-file .env.production -f docker-compose-cluster.yml up -d

# 停止集群
docker-compose -f docker-compose-cluster.yml down
# 或者
./es-manager.sh stop
```

## 访问地址

- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601

## 健康检查

检查 Elasticsearch 是否正常运行：

```bash
curl -X GET "localhost:9200/_cluster/health?pretty"
```

检查集群节点状态：

```bash
curl -X GET "localhost:9200/_cat/nodes?v"
```

## 配置说明

### 内存设置
- 默认 JVM 堆内存设置为 512MB (`-Xms512m -Xmx512m`)
- 生产环境建议根据服务器配置调整内存大小

### 安全设置
- 默认关闭了 X-Pack 安全功能，适合开发环境
- 生产环境建议启用安全验证

### 数据持久化
- 使用 Docker 数据卷持久化存储数据
- 数据卷名称：`es_data`（单节点）或 `es01_data, es02_data, es03_data`（集群）

## 系统要求

### Linux 系统设置

如果遇到内存锁定问题，需要设置系统参数：

```bash
# 临时设置
sudo sysctl -w vm.max_map_count=262144

# 永久设置
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
```

### Docker 资源限制

确保 Docker 有足够的内存资源：
- 单节点：至少 2GB 内存
- 集群模式：至少 4GB 内存

## 常见问题

1. **启动失败**: 检查系统内存和 `vm.max_map_count` 设置
2. **连接超时**: 确保防火墙允许 9200 和 5601 端口
3. **数据丢失**: 使用 `docker-compose down -v` 会删除数据，请谨慎使用

## 自定义配置

如需修改配置，请编辑：
- `config/elasticsearch.yml` - Elasticsearch 主配置
- `docker-compose.yml` - 服务配置和环境变量

## 版本信息

- Elasticsearch: 8.11.0
- Kibana: 8.11.0

## 许可证

本模板遵循 MIT 许可证。
