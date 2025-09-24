#!/bin/bash

# Elasticsearch Docker Compose 启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 检查 Docker 和 Docker Compose
check_dependencies() {
    if ! command -v docker &> /dev/null; then
        print_message $RED "Error: Docker is not installed"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_message $RED "Error: Docker Compose is not installed"
        exit 1
    fi
}

# 设置系统参数
setup_system() {
    print_message $YELLOW "Setting up system parameters..."

    # 检查并设置 vm.max_map_count
    current_value=$(sysctl -n vm.max_map_count 2>/dev/null || echo "0")
    if [ "$current_value" -lt 262144 ]; then
        print_message $YELLOW "Setting vm.max_map_count to 262144..."
        sudo sysctl -w vm.max_map_count=262144

        # 询问是否要永久设置
        read -p "Do you want to make this setting permanent? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
            print_message $GREEN "vm.max_map_count has been set permanently"
        fi
    fi
}

# 显示使用帮助
show_help() {
    echo "Elasticsearch Docker Compose 管理脚本"
    echo ""
    echo "用法: $0 [选项] [环境文件]"
    echo ""
    echo "选项:"
    echo "  start [env_file]      启动单节点 Elasticsearch (默认使用 .env)"
    echo "  start-cluster [env]   启动 3 节点 Elasticsearch 集群"
    echo "  start-dev             使用开发环境配置启动"
    echo "  start-prod            使用生产环境配置启动"
    echo "  stop                  停止服务"
    echo "  restart [env_file]    重启服务"
    echo "  logs                  查看日志"
    echo "  status                查看服务状态"
    echo "  clean                 停止服务并清理数据"
    echo "  health                检查 Elasticsearch 健康状态"
    echo "  help                  显示此帮助信息"
    echo ""
    echo "环境文件:"
    echo "  .env                  默认配置"
    echo "  .env.development      开发环境配置"
    echo "  .env.production       生产环境配置"
    echo ""
    echo "示例:"
    echo "  $0 start                    # 使用默认配置启动"
    echo "  $0 start .env.development   # 使用开发环境配置启动"
    echo "  $0 start-dev                # 快捷启动开发环境"
    echo "  $0 start-cluster .env.production  # 使用生产环境配置启动集群"
    echo ""
}

# 启动单节点
start_single() {
    local env_file="${1:-.env}"
    print_message $GREEN "Starting single-node Elasticsearch with $env_file..."
    docker-compose --env-file "$env_file" up -d
    print_message $GREEN "Elasticsearch is starting up..."
    print_message $BLUE "Elasticsearch: http://localhost:$(grep ES_PORT $env_file | cut -d'=' -f2 || echo 9200)"
    print_message $BLUE "Kibana: http://localhost:$(grep KIBANA_PORT $env_file | cut -d'=' -f2 || echo 5601)"
}

# 启动集群
start_cluster() {
    local env_file="${1:-.env}"
    print_message $GREEN "Starting Elasticsearch cluster with $env_file..."
    docker-compose --env-file "$env_file" -f docker-compose-cluster.yml up -d
    print_message $GREEN "Elasticsearch cluster is starting up..."
    print_message $BLUE "Elasticsearch: http://localhost:$(grep ES_PORT $env_file | cut -d'=' -f2 || echo 9200)"
    print_message $BLUE "Kibana: http://localhost:$(grep KIBANA_PORT $env_file | cut -d'=' -f2 || echo 5601)"
}

# 使用环境变量启动
start_env() {
    print_message $GREEN "Starting Elasticsearch with environment variables..."
    docker-compose -f docker-compose.env.yml up -d
    print_message $GREEN "Elasticsearch is starting up..."
    print_message $BLUE "Elasticsearch: http://localhost:9200"
    print_message $BLUE "Kibana: http://localhost:5601"
}

# 停止服务
stop_services() {
    print_message $YELLOW "Stopping Elasticsearch services..."
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose-cluster.yml down 2>/dev/null || true
    print_message $GREEN "Services stopped"
}

# 查看日志
view_logs() {
    if docker-compose ps -q 2>/dev/null | grep -q .; then
        docker-compose logs -f
    elif docker-compose -f docker-compose-cluster.yml ps -q 2>/dev/null | grep -q .; then
        docker-compose -f docker-compose-cluster.yml logs -f
    else
        print_message $RED "No running services found"
    fi
}

# 检查健康状态
check_health() {
    print_message $YELLOW "Checking Elasticsearch health..."

    # 等待服务启动
    for i in {1..30}; do
        if curl -s http://localhost:9200/_cluster/health >/dev/null 2>&1; then
            break
        fi
        echo -n "."
        sleep 2
    done
    echo

    # 显示集群健康状态
    if curl -s http://localhost:9200/_cluster/health >/dev/null 2>&1; then
        print_message $GREEN "Elasticsearch is running!"
        echo
        print_message $BLUE "Cluster Health:"
        curl -s http://localhost:9200/_cluster/health?pretty
        echo
        print_message $BLUE "Cluster Nodes:"
        curl -s http://localhost:9200/_cat/nodes?v
    else
        print_message $RED "Elasticsearch is not responding"
        exit 1
    fi
}

# 清理数据
clean_data() {
    print_message $YELLOW "This will stop all services and remove all data. Are you sure?"
    read -p "Type 'yes' to continue: " -r
    if [[ $REPLY == "yes" ]]; then
        print_message $YELLOW "Cleaning up..."
        docker-compose down -v 2>/dev/null || true
        docker-compose -f docker-compose-cluster.yml down -v 2>/dev/null || true
        print_message $GREEN "Cleanup completed"
    else
        print_message $BLUE "Cleanup cancelled"
    fi
}

# 主程序
main() {
    check_dependencies

    case "${1:-}" in
        "start")
            setup_system
            start_single "${2:-}"
            ;;
        "start-cluster")
            setup_system
            start_cluster "${2:-}"
            ;;
        "start-dev")
            setup_system
            start_single ".env.development"
            ;;
        "start-prod")
            setup_system
            start_single ".env.production"
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 2
            start_single "${2:-}"
            ;;
        "logs")
            view_logs
            ;;
        "status")
            docker-compose ps 2>/dev/null || docker-compose -f docker-compose-cluster.yml ps 2>/dev/null
            ;;
        "clean")
            clean_data
            ;;
        "health")
            check_health
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_message $RED "Unknown command: ${1:-}"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"
