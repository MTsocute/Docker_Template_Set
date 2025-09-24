#!/bin/bash

# MySQL 模板快速启动脚本
# 作者: AI Assistant
# 日期: 2024-09-24

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "MySQL 模板快速启动脚本"
    echo ""
    echo "用法: $0 [模式] [选项]"
    echo ""
    echo "模式:"
    echo "  single        启动单节点 MySQL（默认）"
    echo "  cluster       启动 MySQL 主从集群"
    echo ""
    echo "选项:"
    echo "  -h, --help    显示帮助信息"
    echo ""
    echo "示例:"
    echo "  $0            # 启动单节点模式"
    echo "  $0 single     # 启动单节点模式"
    echo "  $0 cluster    # 启动集群模式"
}

# 显示欢迎信息
show_welcome() {
    echo ""
    echo "========================================"
    echo "       MySQL Docker 模板启动器"
    echo "========================================"
    echo ""
}

# 启动单节点模式
start_single_node() {
    log_info "启动单节点 MySQL..."
    cd single-node
    ./start.sh
}

# 启动集群模式
start_cluster() {
    log_info "启动 MySQL 集群..."
    cd cluster
    ./start.sh
}

# 主函数
main() {
    show_welcome

    local mode="single"

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            single)
                mode="single"
                shift
                ;;
            cluster)
                mode="cluster"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 检查 .env 文件
    if [ ! -f ".env" ]; then
        log_warning ".env 文件不存在，创建默认配置..."
        cp .env.example .env
        log_info "请根据需要编辑 .env 文件"
    fi

    # 根据模式启动服务
    case $mode in
        "single")
            start_single_node
            ;;
        "cluster")
            start_cluster
            ;;
        *)
            log_error "未知模式: $mode"
            exit 1
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
