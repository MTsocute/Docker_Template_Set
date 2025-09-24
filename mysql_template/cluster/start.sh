#!/bin/bash

# MySQL 集群启动脚本
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

    mkdir -p ../volumes/mysql-master-data
    mkdir -p ../volumes/mysql-slave-data
    mkdir -p ../volumes/logs-master
    mkdir -p ../volumes/logs-slave

    # 设置目录权限
    chmod 755 ../volumes/mysql-master-data
    chmod 755 ../volumes/mysql-slave-data
    chmod 755 ../volumes/logs-master
    chmod 755 ../volumes/logs-slave

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

# 启动主库
start_master() {
    log_info "启动 MySQL 主库..."
    docker-compose --env-file=../.env up -d mysql-master

    # 等待主库就绪
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T mysql-master mysqladmin ping -h localhost --silent; then
            log_success "MySQL 主库已就绪"
            return 0
        fi

        log_info "等待主库启动... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    log_error "主库启动超时"
    return 1
}

# 启动从库
start_slave() {
    log_info "启动 MySQL 从库..."
    docker-compose --env-file=../.env up -d mysql-slave

    # 等待从库就绪
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T mysql-slave mysqladmin ping -h localhost --silent; then
            log_success "MySQL 从库已就绪"
            return 0
        fi

        log_info "等待从库启动... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done

    log_error "从库启动超时"
    return 1
}

# 配置主从复制
setup_replication() {
    log_info "配置主从复制..."

    # 在从库上配置复制
    docker-compose exec -T mysql-slave mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-123456}" -e "
        CHANGE MASTER TO
        MASTER_HOST='mysql-master',
        MASTER_USER='${MYSQL_REPLICATION_USER:-replicator}',
        MASTER_PASSWORD='${MYSQL_REPLICATION_PASSWORD:-replicator_pass}',
        MASTER_AUTO_POSITION=1;
        START SLAVE;
    " 2>/dev/null

    # 检查复制状态
    sleep 3
    local slave_status
    slave_status=$(docker-compose exec -T mysql-slave mysql -uroot -p"${MYSQL_ROOT_PASSWORD:-123456}" -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep "Slave_IO_Running\|Slave_SQL_Running")

    if echo "$slave_status" | grep -q "Yes.*Yes"; then
        log_success "主从复制配置成功"
    else
        log_warning "主从复制可能存在问题，请手动检查"
        log_info "检查命令: docker-compose exec mysql-slave mysql -uroot -p -e 'SHOW SLAVE STATUS\\G'"
    fi
}

# 显示连接信息
show_connection_info() {
    log_info "集群连接信息:"
    echo "========================================"
    echo "主库（写操作）:"
    echo "  主机: localhost"
    echo "  端口: ${MYSQL_PORT:-3306}"
    echo "  用户: root"
    echo "  密码: ${MYSQL_ROOT_PASSWORD:-123456}"
    echo ""
    echo "从库（读操作）:"
    echo "  主机: localhost"
    echo "  端口: ${MYSQL_SLAVE_PORT:-3307}"
    echo "  用户: root"
    echo "  密码: ${MYSQL_ROOT_PASSWORD:-123456}"
    echo "========================================"
    echo ""
    echo "连接命令示例:"
    echo "# 连接主库（写操作）"
    echo "mysql -h localhost -P ${MYSQL_PORT:-3306} -u root -p"
    echo ""
    echo "# 连接从库（读操作）"
    echo "mysql -h localhost -P ${MYSQL_SLAVE_PORT:-3307} -u root -p"
    echo ""
}

# 显示管理命令
show_management_commands() {
    echo "管理命令:"
    echo "========================================"
    echo "查看服务状态: docker-compose ps"
    echo "查看主库日志: docker-compose logs -f mysql-master"
    echo "查看从库日志: docker-compose logs -f mysql-slave"
    echo "停止服务: docker-compose down"
    echo "重启服务: docker-compose restart"
    echo ""
    echo "进入容器:"
    echo "  主库: docker-compose exec mysql-master bash"
    echo "  从库: docker-compose exec mysql-slave bash"
    echo ""
    echo "检查复制状态:"
    echo "  主库: docker-compose exec mysql-master mysql -uroot -p -e 'SHOW MASTER STATUS'"
    echo "  从库: docker-compose exec mysql-slave mysql -uroot -p -e 'SHOW SLAVE STATUS\\G'"
    echo ""
    echo "其他工具:"
    echo "  备份数据: ../scripts/backup.sh"
    echo "  健康检查: ../scripts/health-check.sh"
    echo "========================================"
}

# 主函数
main() {
    log_info "MySQL 集群部署开始..."

    check_dependencies
    create_directories
    check_env_file

    if start_master && start_slave; then
        setup_replication
        log_success "MySQL 集群部署完成!"
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
