#!/bin/bash

# MySQL 数据备份脚本
# 作者: AI Assistant
# 日期: 2024-09-24

set -e

# 配置
BACKUP_DIR="../backups"
DATE=$(date +%Y%m%d_%H%M%S)
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
    echo "MySQL 备份脚本"
    echo ""
    echo "用法: $0 [选项] [数据库名]"
    echo ""
    echo "选项:"
    echo "  -h, --help        显示帮助信息"
    echo "  -a, --all         备份所有数据库"
    echo "  -c, --cluster     备份集群（主库）"
    echo "  -s, --single      备份单节点（默认）"
    echo "  -d, --database    指定数据库名"
    echo ""
    echo "示例:"
    echo "  $0                        # 备份默认数据库（单节点）"
    echo "  $0 -a                     # 备份所有数据库"
    echo "  $0 -d myapp              # 备份指定数据库"
    echo "  $0 -c -d myapp           # 备份集群中的指定数据库"
}

# 创建备份目录
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_info "创建备份目录: $BACKUP_DIR"
    fi
}

# 备份单个数据库
backup_database() {
    local db_name=$1
    local container_name=$2
    local backup_file="${BACKUP_DIR}/${db_name}_${DATE}.sql"

    log_info "备份数据库: $db_name"

    if docker exec "$container_name" mysqldump \
        -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --add-drop-database \
        --databases "$db_name" > "$backup_file"; then

        # 压缩备份文件
        gzip "$backup_file"
        local compressed_file="${backup_file}.gz"
        local file_size=$(du -h "$compressed_file" | cut -f1)

        log_success "备份完成: $compressed_file (大小: $file_size)"
        return 0
    else
        log_error "备份失败: $db_name"
        return 1
    fi
}

# 备份所有数据库
backup_all_databases() {
    local container_name=$1
    local backup_file="${BACKUP_DIR}/all_databases_${DATE}.sql"

    log_info "备份所有数据库"

    if docker exec "$container_name" mysqldump \
        -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --all-databases > "$backup_file"; then

        # 压缩备份文件
        gzip "$backup_file"
        local compressed_file="${backup_file}.gz"
        local file_size=$(du -h "$compressed_file" | cut -f1)

        log_success "全量备份完成: $compressed_file (大小: $file_size)"
        return 0
    else
        log_error "全量备份失败"
        return 1
    fi
}

# 检查容器状态
check_container() {
    local container_name=$1

    if ! docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        log_error "容器 $container_name 未运行"
        return 1
    fi

    # 检查 MySQL 服务状态
    if ! docker exec "$container_name" mysqladmin ping -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent; then
        log_error "MySQL 服务未就绪"
        return 1
    fi

    return 0
}

# 清理旧备份
cleanup_old_backups() {
    local days=${1:-7}
    log_info "清理 $days 天前的备份文件"

    find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +$days -delete
    log_success "清理完成"
}

# 主函数
main() {
    local mode="single"
    local backup_all=false
    local database_name="${MYSQL_DATABASE:-myapp}"

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--all)
                backup_all=true
                shift
                ;;
            -c|--cluster)
                mode="cluster"
                shift
                ;;
            -s|--single)
                mode="single"
                shift
                ;;
            -d|--database)
                database_name="$2"
                shift 2
                ;;
            *)
                database_name="$1"
                shift
                ;;
        esac
    done

    # 确定容器名称
    local container_name
    if [ "$mode" == "cluster" ]; then
        container_name="mysql-master"
    else
        container_name="mysql-standalone"
    fi

    log_info "开始备份 MySQL 数据库..."
    log_info "模式: $mode"
    log_info "容器: $container_name"

    # 检查容器状态
    if ! check_container "$container_name"; then
        exit 1
    fi

    # 创建备份目录
    create_backup_dir

    # 执行备份
    if [ "$backup_all" == true ]; then
        backup_all_databases "$container_name"
    else
        backup_database "$database_name" "$container_name"
    fi

    # 清理旧备份
    cleanup_old_backups 7

    log_success "备份任务完成"
    log_info "备份文件位置: $BACKUP_DIR"
    log_info "查看备份: ls -la $BACKUP_DIR"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
