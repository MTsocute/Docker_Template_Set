#!/bin/bash

# MySQL 单节点启动脚本
# 作者: AI Assistant
# 日期: 2024-09-24

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查 Docker 和 Docker Compose
check_dependencies() {
    log_info "检查依赖..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装或不在 PATH 中"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose 未安装或不在 PATH 中"
        exit 1
    fi

    log_success "依赖检查完成"
}

# 创建必要的目录
create_directories() {
    log_info "创建数据目录..."

    mkdir -p ../volumes/mysql-data
    mkdir -p ../volumes/logs

    # 设置目录权限
    chmod 755 ../volumes/mysql-data
    chmod 755 ../volumes/logs

    log_success "目录创建完成"
}

# 检查环境变量文件
check_env_file() {
    if [ ! -f "../.env" ]; then
        log_warning ".env 文件不存在，创建默认配置..."
        cp ../.env.example ../.env
        log_info "请编辑 .env 文件以自定义配置"
    fi
}

# 启动服务
start_services() {
    log_info "启动 MySQL 单节点服务..."

    # 使用父目录的 .env 文件
    docker-compose --env-file=../.env up -d

    log_success "MySQL 服务已启动"
}

# 等待服务就绪
wait_for_service() {
    log_info "等待 MySQL 服务就绪..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec mysql mysqladmin ping -h localhost --silent; then
            log_success "MySQL 服务已就绪"
            return 0
        fi

        log_info "等待中... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    log_error "MySQL 服务启动超时"
    return 1
}

# 显示连接信息
show_connection_info() {
    log_info "连接信息:"
    echo "----------------------------------------"
    echo "主机: localhost"
    echo "端口: ${MYSQL_PORT:-3306}"
    echo "用户: root"
    echo "密码: ${MYSQL_ROOT_PASSWORD:-123456}"
    echo "数据库: ${MYSQL_DATABASE:-myapp}"
    echo "----------------------------------------"
    echo ""
    echo "连接命令示例:"
    echo "mysql -h localhost -P ${MYSQL_PORT:-3306} -u root -p"
    echo ""
}

# 显示管理命令
show_management_commands() {
    echo "管理命令:"
    echo "----------------------------------------"
    echo "查看服务状态: docker-compose ps"
    echo "查看日志: docker-compose logs -f"
    echo "停止服务: docker-compose down"
    echo "重启服务: docker-compose restart"
    echo "进入容器: docker-compose exec mysql bash"
    echo "备份数据: ../scripts/backup.sh"
    echo "健康检查: ../scripts/health-check.sh"
    echo "----------------------------------------"
}

# 主函数
main() {
    log_info "MySQL 单节点部署开始..."

    check_dependencies
    create_directories
    check_env_file
    start_services

    if wait_for_service; then
        log_success "MySQL 单节点部署完成!"
        show_connection_info
        show_management_commands
    else
        log_error "部署失败，请检查日志: docker-compose logs"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
