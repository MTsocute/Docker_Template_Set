#!/bin/bash
set -e

ACTION=$1

case "$ACTION" in
  start)
    docker-compose up -d
    echo "etcd 单节点服务已启动。"
    ;;
  stop)
    docker-compose down
    echo "etcd 单节点服务已关闭。"
    ;;
  logs)
    docker-compose logs -f etcd
    ;;
  ui)
    echo "暂无集成交互界面，如需可手动添加 etcdkeeper 或 etcd-viewer。"
    ;;
  test)
    cd go_test
    bash run_test.sh
    ;;
  *)
    echo "用法: $0 {start|stop|logs|ui|test}"
    exit 1
    ;;
esac
