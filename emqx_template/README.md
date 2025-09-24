# 🚀 EMQX Docker 环境

这是一个基于 Docker Compose 的 EMQX MQTT Broker 服务环境，包含完整的管理脚本和测试工具。

## ✨ 特性概览

- 🐳 **一键部署** - 使用 Docker Compose 快速启动 EMQX
- 🎨 **美观的 TUI** - 带彩色图标的交互式管理界面
- 🧪 **自动测试** - 智能 MQTT 连接测试脚本
- 📊 **实时监控** - 服务状态检查和健康监控
- 🔧 **灵活配置** - 支持环境变量自定义配置
- 📖 **详细文档** - 完整的使用说明和故障排除指南

## 📁 文件说明

| 文件名                 | 描述                        | 用途                               |
| ---------------------- | --------------------------- | ---------------------------------- |
| `docker-compose.yml` | Docker Compose 配置文件     | 定义 EMQX 服务、端口、数据卷等配置 |
| `emqx_manager.sh`    | 完整版管理脚本（带TUI界面） | 提供交互式菜单和命令行管理功能     |
| `quick.sh`           | 简化版快速管理脚本          | 提供基本的启动、停止、查看功能     |
| `test_mqtt.sh`       | MQTT 连接测试脚本           | 自动测试 MQTT 连接和消息收发功能   |
| `.env.example`       | 环境变量配置示例            | 提供可自定义的环境变量模板         |

## 快速开始

### 1. 启动服务

```bash
# 使用管理脚本启动（推荐）
./emqx_manager.sh start

# 或使用快速脚本
./quick.sh start

# 或直接使用 docker-compose
docker-compose up -d
```

### 2. 访问管理界面

启动后访问: http://localhost:18083

- 用户名: `admin`
- 密码: `123456`

### 3. 查看状态

```bash
./emqx_manager.sh status
# 或
./quick.sh status
```

### 4. 查看日志

```bash
./emqx_manager.sh logs
# 或
./quick.sh logs
```

### 6. 测试 MQTT 连接

```bash
./test_mqtt.sh
```

这个脚本将自动：

- ✅ 检查 EMQX 服务状态
- ✅ 测试 MQTT 端口连通性
- ✅ 验证消息发布和订阅功能
- ✅ 显示连接信息和测试结果

### 7. 停止服务

```bash
./emqx_manager.sh stop
# 或
./quick.sh stop
```

## 服务信息

- **MQTT TCP 端口**: 1883
- **MQTT SSL 端口**: 8883
- **WebSocket 端口**: 8083
- **WebSocket SSL 端口**: 8084
- **管理界面端口**: 18083
- **容器名**: emqx
- **网络**: emqx-network
- **数据卷**: emqx_data, emqx_log

## 管理脚本使用

### 完整版管理脚本 (emqx_manager.sh)

#### 交互式菜单模式

```bash
./emqx_manager.sh
```

#### 命令行模式

```bash
./emqx_manager.sh [命令]
```

支持的命令：

- `start` - 启动服务
- `stop` - 停止服务
- `restart` - 重启服务
- `logs` - 查看日志
- `status` - 检查状态
- `config` - 显示配置
- `dashboard` - 打开管理界面
- `help` - 显示帮助

### 快速管理脚本 (quick.sh)

```bash
./quick.sh [命令]
```

### 测试脚本 (test_mqtt.sh)

这是一个智能的 MQTT 连接测试脚本：

```bash
./test_mqtt.sh
```

**功能特点：**

- 🔍 **自动检测服务状态** - 验证 EMQX 容器是否运行
- 🔌 **端口连通性测试** - 检查 MQTT 端口（1883, 8883, 8083, 8084, 18083）可访问性
- 📡 **MQTT 消息测试** - 自动发布和订阅测试消息
- 🛠️ **工具检查** - 检测是否安装了 mosquitto 客户端工具
- 💡 **智能提示** - 提供安装建议和 Docker 替代方案
- 📊 **详细报告** - 显示测试结果和连接信息

**输出示例：**

```
🧪 EMQX MQTT 连接测试
==================================
✅ EMQX 服务正在运行
🔌 测试 MQTT TCP 连接 (端口 1883)
✅ MQTT 发布成功
✅ MQTT 订阅测试完成
📊 EMQX 状态信息：
- 管理界面: http://localhost:18083
- 默认账户: admin/public
```

**如果没有 mosquitto 客户端：**
脚本会提供 Docker 容器测试方法：

```bash
# 订阅消息
docker run --rm -it --network host eclipse-mosquitto mosquitto_sub -h localhost -p 1883 -t test/topic

# 发布消息
docker run --rm -it --network host eclipse-mosquitto mosquitto_pub -h localhost -p 1883 -t test/topic -m 'Hello EMQX'
```

## 📝 环境配置

### 自定义配置（可选）

项目提供了 `.env.example` 文件作为环境变量配置模板：

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置文件
nano .env
```

**可配置项包括：**

- 管理员账户和密码
- 各个端口号
- 集群配置
- SSL/TLS 证书路径
- 日志级别

## 🔧 EMQX 配置

- EMQX 版本: 5.0.12
- 默认管理员账户: admin/public
- 自动健康检查
- 数据持久化
- 网络隔离

## MQTT 连接测试

启动服务后，可以使用以下方式测试 MQTT 连接：

### 使用 mosquitto 客户端

```bash
# 订阅主题
mosquitto_sub -h localhost -p 1883 -t test/topic

# 发布消息
mosquitto_pub -h localhost -p 1883 -t test/topic -m "Hello EMQX"
```

### 使用 WebSocket

可以通过浏览器或 JavaScript 连接 WebSocket：

- WS: `ws://localhost:8083/mqtt`
- WSS: `wss://localhost:8084/mqtt`

## 管理界面功能

访问 http://localhost:18083 可以：

- 查看连接的客户端
- 监控消息收发统计
- 配置认证和授权
- 管理主题和订阅
- 查看系统监控信息
- 配置插件和规则引擎

## 🔧 故障排除

### 常见问题

**1. 端口被占用**

```bash
# 检查端口占用情况
sudo netstat -tlnp | grep :1883
sudo netstat -tlnp | grep :18083

# 杀死占用端口的进程
sudo kill -9 <PID>
```

**2. 容器启动失败**

```bash
# 查看容器日志
docker-compose logs emqx

# 检查容器状态
docker-compose ps
```

**3. 无法访问管理界面**

- 确认服务已启动：`./emqx_manager.sh status`
- 检查防火墙设置
- 验证端口映射：`docker port emqx`

**4. MQTT 连接失败**

- 使用测试脚本诊断：`./test_mqtt.sh`
- 检查客户端配置（主机名、端口、协议）
- 查看 EMQX 日志：`./emqx_manager.sh logs`

### 重置环境

```bash
# 完全重置（会删除数据）
docker-compose down -v
docker system prune -f
./emqx_manager.sh start
```

## ⚠️ 注意事项

- 确保已安装 Docker 和 Docker Compose
- 确保端口 1883, 8083, 8084, 8883, 18083 未被占用
- 数据存储在 Docker 卷中，删除卷将丢失数据
- 生产环境建议修改默认管理员密码
- 建议根据需要配置 SSL/TLS 证书
