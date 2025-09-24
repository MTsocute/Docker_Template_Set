#!/bin/bash

# EMQX MQTT 连接测试脚本

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🧪 EMQX MQTT 连接测试${NC}"
echo "=================================="

# 检查 EMQX 服务是否运行
if ! docker ps | grep -q "emqx.*Up"; then
    echo -e "${RED}❌ EMQX 服务未运行，请先启动服务${NC}"
    echo "运行: ./emqx_manager.sh start"
    exit 1
fi

echo -e "${GREEN}✅ EMQX 服务正在运行${NC}"

# 检查是否安装了 mosquitto 客户端
if ! command -v mosquitto_pub &> /dev/null || ! command -v mosquitto_sub &> /dev/null; then
    echo -e "${YELLOW}⚠️  未安装 mosquitto 客户端工具${NC}"
    echo "Ubuntu/Debian: sudo apt-get install mosquitto-clients"
    echo "CentOS/RHEL: sudo yum install mosquitto"
    echo "macOS: brew install mosquitto"
    echo ""
    echo -e "${CYAN}💡 或者可以使用 Docker 容器进行测试：${NC}"
    echo "# 订阅消息"
    echo "docker run --rm -it --network host eclipse-mosquitto mosquitto_sub -h localhost -p 1883 -t test/topic"
    echo ""
    echo "# 发布消息"
    echo "docker run --rm -it --network host eclipse-mosquitto mosquitto_pub -h localhost -p 1883 -t test/topic -m 'Hello EMQX'"
    exit 1
fi

# 测试 MQTT 连接
echo -e "${CYAN}🔌 测试 MQTT TCP 连接 (端口 1883)${NC}"

# 发布测试消息
TEST_MESSAGE="Hello EMQX - $(date)"
TEST_TOPIC="test/mqtt/connection"

echo "发布测试消息..."
if mosquitto_pub -h localhost -p 1883 -t "$TEST_TOPIC" -m "$TEST_MESSAGE" 2>/dev/null; then
    echo -e "${GREEN}✅ MQTT 发布成功${NC}"
else
    echo -e "${RED}❌ MQTT 发布失败${NC}"
fi

# 测试订阅（后台运行5秒）
echo "测试订阅消息（5秒后自动结束）..."
timeout 5s mosquitto_sub -h localhost -p 1883 -t "$TEST_TOPIC" &
SUBSCRIBE_PID=$!

sleep 1

# 再次发布消息用于订阅测试
mosquitto_pub -h localhost -p 1883 -t "$TEST_TOPIC" -m "订阅测试消息 - $(date)" 2>/dev/null

wait $SUBSCRIBE_PID 2>/dev/null

echo -e "${GREEN}✅ MQTT 订阅测试完成${NC}"

echo ""
echo -e "${CYAN}📊 EMQX 状态信息：${NC}"
echo "- 管理界面: http://localhost:18083"
echo "- 默认账户: admin/public"
echo "- MQTT TCP: localhost:1883"
echo "- MQTT SSL: localhost:8883"
echo "- WebSocket: ws://localhost:8083/mqtt"
echo "- WebSocket SSL: wss://localhost:8084/mqtt"

echo ""
echo -e "${YELLOW}💡 手动测试命令：${NC}"
echo "# 订阅主题"
echo "mosquitto_sub -h localhost -p 1883 -t test/topic"
echo ""
echo "# 发布消息"
echo "mosquitto_pub -h localhost -p 1883 -t test/topic -m 'Hello World'"
