# Docker 服务模板集合

这是一个常用的 Docker 服务模板集合，包含了开发和测试中经常用到的各种服务的快速部署配置。

## 📦 包含的服务

### 🔍 ElasticSearch
- **位置**: `elasticSearch_template/`
- **用途**: 搜索引擎服务，支持单节点和集群部署
- **快速启动**: 查看目录下的 README.md

### 📡 EMQX (开源版)
- **位置**: `emqx_template/`
- **用途**: MQTT 消息代理服务器
- **快速启动**: 运行 `quick.sh` 脚本

### 📡 EMQX Enterprise (企业版)
- **位置**: `emqx_enterprise_template/`
- **用途**: EMQX 企业版 MQTT 服务器
- **快速启动**: 使用 docker-compose 启动

### 🗄️ MySQL
- **位置**: `mysql_template/`
- **用途**: MySQL 数据库服务，支持单节点和主从集群
- **快速启动**: 查看 QUICKSTART.md

## 🚀 使用方法

1. 进入需要的服务目录
2. 查看对应的 README.md 或 QUICKSTART.md
3. 运行提供的启动脚本或 docker-compose 命令

## 📝 注意事项

- 所有服务都已配置好基本的生产级别配置
- 数据持久化已设置，重启容器不会丢失数据
- 根据需要修改配置文件中的端口和参数
- 首次使用前请确保 Docker 和 Docker Compose 已安装

---
*快速部署，开箱即用* ✨
