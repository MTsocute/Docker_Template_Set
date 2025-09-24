#!/bin/bash

# 简化版快速管理脚本
# 使用: ./quick.sh [start|stop|logs|status|dashboard]

case "$1" in
    "start")
        echo "🚀 启动 EMQX 服务..."
        docker-compose up -d
        echo "✅ 服务启动完成！"
        echo "📡 MQTT 端口: 1883 (TCP), 8883 (SSL)"
        echo "🖥️  管理界面: http://localhost:18083 (admin/public)"
        ;;
    "stop")
        echo "🛑 停止 EMQX 服务..."
        docker-compose down
        echo "✅ 服务已停止！"
        ;;
    "logs")
        echo "📋 查看 EMQX 日志 (Ctrl+C 退出)..."
        docker-compose logs -f emqx
        ;;
    "status")
        echo "📊 检查服务状态..."
        docker-compose ps
        ;;
    "dashboard")
        echo "🖥️  打开 EMQX 管理界面..."
        echo "地址: http://localhost:18083"
        echo "账户: admin/public"
        ;;
    *)
        echo "用法: $0 {start|stop|logs|status|dashboard}"
        echo "示例:"
        echo "  $0 start      # 启动服务"
        echo "  $0 stop       # 停止服务"
        echo "  $0 logs       # 查看日志"
        echo "  $0 status     # 查看状态"
        echo "  $0 dashboard  # 打开管理界面"
        ;;
esac
