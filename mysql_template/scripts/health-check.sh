#!/bin/bash

# MySQL 健康检查脚本
# 作者: AI Assistant
# 日期: 2024-09-24

set -e

# 配置
MYSQL_USER="root"
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD:-123456}"

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
    echo "MySQL 健康检查脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help        显示帮助信息"
    echo "  -c, --cluster     检查集群状态"
    echo "  -s, --single      检查单节点状态（默认）"
    echo "  -v, --verbose     详细输出"
    echo ""
    echo "示例:"
    echo "  $0                # 检查单节点状态"
    echo "  $0 -c             # 检查集群状态"
    echo "  $0 -v             # 详细输出"
}

# 检查容器状态
check_container_status() {
    local container_name=$1
    local status="FAIL"

    log_info "检查容器状态: $container_name"

    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "^$container_name"; then
        local container_status=$(docker ps --format "{{.Status}}" --filter "name=$container_name")
        if [[ "$container_status" == *"Up"* ]]; then
            log_success "容器运行中: $container_status"
            status="OK"
        else
            log_error "容器状态异常: $container_status"
        fi
    else
        log_error "容器未运行"
    fi

    echo "$status"
}

# 检查 MySQL 服务状态
check_mysql_service() {
    local container_name=$1
    local status="FAIL"

    log_info "检查 MySQL 服务状态: $container_name"

    if docker exec "$container_name" mysqladmin ping -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
        log_success "MySQL 服务正常"
        status="OK"
    else
        log_error "MySQL 服务异常"
    fi

    echo "$status"
}

# 检查数据库连接
check_database_connection() {
    local container_name=$1
    local status="FAIL"

    log_info "检查数据库连接: $container_name"

    if docker exec "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        log_success "数据库连接正常"
        status="OK"
    else
        log_error "数据库连接失败"
    fi

    echo "$status"
}

# 检查磁盘空间
check_disk_space() {
    local container_name=$1
    local status="OK"

    log_info "检查磁盘空间: $container_name"

    local disk_usage=$(docker exec "$container_name" df -h /var/lib/mysql | tail -1 | awk '{print $5}' | sed 's/%//')

    if [ "$disk_usage" -gt 90 ]; then
        log_error "磁盘空间不足: ${disk_usage}%"
        status="CRITICAL"
    elif [ "$disk_usage" -gt 80 ]; then
        log_warning "磁盘空间紧张: ${disk_usage}%"
        status="WARNING"
    else
        log_success "磁盘空间充足: ${disk_usage}%"
    fi

    echo "$status"
}

# 检查内存使用
check_memory_usage() {
    local container_name=$1
    local status="OK"

    log_info "检查内存使用: $container_name"

    local memory_stats=$(docker stats "$container_name" --no-stream --format "{{.MemPerc}}" | sed 's/%//')

    if (( $(echo "$memory_stats > 90" | bc -l) )); then
        log_error "内存使用过高: ${memory_stats}%"
        status="CRITICAL"
    elif (( $(echo "$memory_stats > 80" | bc -l) )); then
        log_warning "内存使用较高: ${memory_stats}%"
        status="WARNING"
    else
        log_success "内存使用正常: ${memory_stats}%"
    fi

    echo "$status"
}

# 检查主从复制状态
check_replication_status() {
    local master_container=$1
    local slave_container=$2
    local status="OK"

    log_info "检查主从复制状态"

    # 检查主库状态
    local master_status=$(docker exec "$master_container" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW MASTER STATUS\G" 2>/dev/null)
    if [ -n "$master_status" ]; then
        log_success "主库状态正常"
    else
        log_error "主库状态异常"
        status="FAIL"
    fi

    # 检查从库状态
    local slave_io=$(docker exec "$slave_container" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep "Slave_IO_Running" | awk '{print $2}')
    local slave_sql=$(docker exec "$slave_container" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW SLAVE STATUS\G" 2>/dev/null | grep "Slave_SQL_Running" | awk '{print $2}')

    if [ "$slave_io" == "Yes" ] && [ "$slave_sql" == "Yes" ]; then
        log_success "从库复制状态正常"
    else
        log_error "从库复制状态异常 (IO: $slave_io, SQL: $slave_sql)"
        status="FAIL"
    fi

    echo "$status"
}

# 显示详细信息
show_detailed_info() {
    local container_name=$1

    log_info "详细信息: $container_name"
    echo "========================================"

    # MySQL 版本
    local mysql_version=$(docker exec "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT VERSION();" 2>/dev/null | tail -1)
    echo "MySQL 版本: $mysql_version"

    # 运行时间
    local uptime=$(docker exec "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW STATUS LIKE 'Uptime';" 2>/dev/null | tail -1 | awk '{print $2}')
    local uptime_formatted=$(($uptime / 86400))d\ $(($uptime % 86400 / 3600))h\ $(($uptime % 3600 / 60))m
    echo "运行时间: $uptime_formatted"

    # 连接数
    local connections=$(docker exec "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | tail -1 | awk '{print $2}')
    local max_connections=$(docker exec "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW VARIABLES LIKE 'max_connections';" 2>/dev/null | tail -1 | awk '{print $2}')
    echo "当前连接数: $connections / $max_connections"

    # 数据库大小
    local db_size=$(docker exec "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size (MB)' FROM information_schema.tables;" 2>/dev/null | tail -1)
    echo "数据库大小: ${db_size} MB"

    echo "========================================"
}

# 生成状态报告
generate_report() {
    local mode=$1
    local verbose=$2

    echo ""
    echo "========================================"
    echo "MySQL 健康检查报告"
    echo "时间: $(date)"
    echo "模式: $mode"
    echo "========================================"

    local overall_status="OK"

    if [ "$mode" == "single" ]; then
        local container_name="mysql-standalone"

        # 检查各项指标
        local container_status=$(check_container_status "$container_name")
        local mysql_status=$(check_mysql_service "$container_name")
        local db_status=$(check_database_connection "$container_name")
        local disk_status=$(check_disk_space "$container_name")
        local memory_status=$(check_memory_usage "$container_name")

        # 汇总状态
        if [[ "$container_status" != "OK" || "$mysql_status" != "OK" || "$db_status" != "OK" ]]; then
            overall_status="CRITICAL"
        elif [[ "$disk_status" == "CRITICAL" || "$memory_status" == "CRITICAL" ]]; then
            overall_status="CRITICAL"
        elif [[ "$disk_status" == "WARNING" || "$memory_status" == "WARNING" ]]; then
            overall_status="WARNING"
        fi

        # 显示详细信息
        if [ "$verbose" == true ] && [ "$mysql_status" == "OK" ]; then
            show_detailed_info "$container_name"
        fi

    elif [ "$mode" == "cluster" ]; then
        local master_container="mysql-master"
        local slave_container="mysql-slave"

        log_info "检查主库..."
        local master_container_status=$(check_container_status "$master_container")
        local master_mysql_status=$(check_mysql_service "$master_container")
        local master_db_status=$(check_database_connection "$master_container")
        local master_disk_status=$(check_disk_space "$master_container")
        local master_memory_status=$(check_memory_usage "$master_container")

        log_info "检查从库..."
        local slave_container_status=$(check_container_status "$slave_container")
        local slave_mysql_status=$(check_mysql_service "$slave_container")
        local slave_db_status=$(check_database_connection "$slave_container")
        local slave_disk_status=$(check_disk_space "$slave_container")
        local slave_memory_status=$(check_memory_usage "$slave_container")

        # 检查复制状态
        local replication_status="FAIL"
        if [[ "$master_mysql_status" == "OK" && "$slave_mysql_status" == "OK" ]]; then
            replication_status=$(check_replication_status "$master_container" "$slave_container")
        fi

        # 汇总状态
        if [[ "$master_container_status" != "OK" || "$master_mysql_status" != "OK" || "$master_db_status" != "OK" ||
              "$slave_container_status" != "OK" || "$slave_mysql_status" != "OK" || "$slave_db_status" != "OK" ||
              "$replication_status" != "OK" ]]; then
            overall_status="CRITICAL"
        elif [[ "$master_disk_status" == "CRITICAL" || "$master_memory_status" == "CRITICAL" ||
                "$slave_disk_status" == "CRITICAL" || "$slave_memory_status" == "CRITICAL" ]]; then
            overall_status="CRITICAL"
        elif [[ "$master_disk_status" == "WARNING" || "$master_memory_status" == "WARNING" ||
                "$slave_disk_status" == "WARNING" || "$slave_memory_status" == "WARNING" ]]; then
            overall_status="WARNING"
        fi

        # 显示详细信息
        if [ "$verbose" == true ]; then
            if [ "$master_mysql_status" == "OK" ]; then
                show_detailed_info "$master_container"
            fi
            if [ "$slave_mysql_status" == "OK" ]; then
                show_detailed_info "$slave_container"
            fi
        fi
    fi

    echo ""
    echo "========================================"
    case $overall_status in
        "OK")
            log_success "整体状态: 健康"
            ;;
        "WARNING")
            log_warning "整体状态: 警告"
            ;;
        "CRITICAL")
            log_error "整体状态: 严重"
            ;;
    esac
    echo "========================================"

    return $([ "$overall_status" == "OK" ] && echo 0 || echo 1)
}

# 主函数
main() {
    local mode="single"
    local verbose=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--cluster)
                mode="cluster"
                shift
                ;;
            -s|--single)
                mode="single"
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    log_info "开始 MySQL 健康检查..."

    if generate_report "$mode" "$verbose"; then
        log_success "健康检查完成"
        exit 0
    else
        log_error "发现健康问题"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
