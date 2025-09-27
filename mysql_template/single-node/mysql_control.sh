#!/bin/zsh
# MySQL 单节点 Docker 快速控制脚本

compose_file="docker-compose.yml"

function start_mysql() {
  docker compose -f $compose_file up -d
}

function stop_mysql() {
  docker compose -f $compose_file down
}

function status_mysql() {
  docker compose -f $compose_file ps
}

function logs_mysql() {
  docker compose -f $compose_file logs -f mysql
}

function usage() {
  echo "用法: $0 {start|stop|status|logs}"
  echo ""
  echo "  start   启动 MySQL 服务（后台运行）"
  echo "  stop    停止并移除 MySQL 容器"
  echo "  status  查看容器运行状态"
  echo "  logs    实时查看 MySQL 日志"
  echo ""
  echo "示例:"
  echo "  $0 start   # 启动 MySQL"
  echo "  $0 status  # 查看状态"
  echo "  $0 logs    # 查看日志"
  echo "  $0 stop    # 停止服务"
}

case "$1" in
  start)
    start_mysql
    ;;
  stop)
    stop_mysql
    ;;
  status)
    status_mysql
    ;;
  logs)
    logs_mysql
    ;;
  *)
    usage
    ;;
esac
