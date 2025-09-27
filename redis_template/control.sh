#!/bin/bash

case "$1" in
  start)
    echo "🚀 启动 Redis 服务..."
    docker-compose up -d
      echo ""
      echo "✅ Redis 服务已启动！"
      echo "🔗 Redis 服务器: localhost:6379"
      echo "🌐 Redis Commander 网页管理界面: http://localhost:8081"
      echo "请在浏览器中访问上面的网址进行 Web UI 管理。"
    ;;
  logs)
    echo "📜 查看 Redis 日志..."
    docker-compose logs -f
    ;;
  stop)
    echo "🛑 停止 Redis 服务..."
    docker-compose down
    ;;
  cli)
    echo "🔗 进入 Redis CLI..."
    docker exec -it redis_server redis-cli
    ;;
  *)
    echo "Redis 控制脚本"
    echo "用法: ./control.sh [命令]"
    echo "命令列表:"
    echo "  start  启动 Redis 服务"
    echo "  logs   查看 Redis 日志"
    echo "  stop   停止 Redis 服务"
    echo "  cli    进入 Redis CLI"
    ;;
esac
