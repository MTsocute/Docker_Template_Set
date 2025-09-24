#!/bin/bash

# MySQL 数据恢复脚本
# 作者: AI Assistant
# 日期: 2024-09-24

set -e

# 配置
BACKUP_DIR="../backups"
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
    echo "MySQL 恢复脚本"
    echo ""
    echo "用法: $0 [选项] <备份文件>"
    echo ""
    echo "选项:"
    echo "  -h, --help        显示帮助信息"
    echo "  -c, --cluster     恢复到集群（主库）"
    echo "  -s, --single      恢复到单节点（默认）"
    echo "  -f, --force       强制恢复（不询问确认）"
    echo ""
    echo "示例:"
    echo "  $0 backup.sql.gz              # 恢复压缩备份文件"
    echo "  $0 backup.sql                 # 恢复 SQL 文件"
    echo "  $0 -c backup.sql.gz           # 恢复到集群"
    echo "  $0 -f backup.sql.gz           # 强制恢复"
}

# 列出可用的备份文件
list_backups() {
    log_info "可用的备份文件:"
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        ls -la "$BACKUP_DIR"/*.sql* 2>/dev/null || log_warning "没有找到备份文件"
    else
        log_warning "备份目录不存在或为空: $BACKUP_DIR"
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

# 恢复数据库
restore_database() {
    local backup_file=$1
    local container_name=$2
    local temp_file=""

    # 检查文件是否存在
    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        return 1
    fi

    log_info "准备恢复数据库"
    log_info "备份文件: $backup_file"
    log_info "目标容器: $container_name"

    # 处理压缩文件
    if [[ "$backup_file" == *.gz ]]; then
        log_info "解压缩备份文件..."
        temp_file="/tmp/restore_temp_$(date +%s).sql"
        gunzip -c "$backup_file" > "$temp_file"
        backup_file="$temp_file"
    fi

    # 获取文件大小
    local file_size=$(du -h "$backup_file" | cut -f1)
    log_info "文件大小: $file_size"

    # 执行恢复
    log_info "开始恢复数据库..."
    if docker exec -i "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" < "$backup_file"; then
        log_success "数据库恢复完成"
    else
        log_error "数据库恢复失败"
        return 1
    fi

    # 清理临时文件
    if [ -n "$temp_file" ] && [ -f "$temp_file" ]; then
        rm -f "$temp_file"
        log_info "清理临时文件: $temp_file"
    fi

    return 0
}

# 确认操作
confirm_restore() {
    local container_name=$1
    local backup_file=$2

    echo ""
    log_warning "注意: 此操作将覆盖目标数据库中的现有数据!"
    echo "目标容器: $container_name"
    echo "备份文件: $backup_file"
    echo ""
    read -p "确认继续恢复操作? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        return 1
    fi

    return 0
}

# 验证恢复结果
verify_restore() {
    local container_name=$1

    log_info "验证恢复结果..."

    # 检查数据库连接
    if docker exec "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
        log_success "数据库连接正常"
    else
        log_error "数据库连接异常"
        return 1
    fi

    # 显示数据库列表
    log_info "当前数据库列表:"
    docker exec "$container_name" mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;" 2>/dev/null

    return 0
}

# 主函数
main() {
    local mode="single"
    local force=false
    local backup_file=""

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
            -f|--force)
                force=true
                shift
                ;;
            -*)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                backup_file="$1"
                shift
                ;;
        esac
    done

    # 检查备份文件参数
    if [ -z "$backup_file" ]; then
        log_error "请指定备份文件"
        list_backups
        exit 1
    fi

    # 如果备份文件是相对路径且不存在，尝试在备份目录中查找
    if [ ! -f "$backup_file" ] && [[ "$backup_file" != /* ]]; then
        local full_path="$BACKUP_DIR/$backup_file"
        if [ -f "$full_path" ]; then
            backup_file="$full_path"
        fi
    fi

    # 确定容器名称
    local container_name
    if [ "$mode" == "cluster" ]; then
        container_name="mysql-master"
    else
        container_name="mysql-standalone"
    fi

    log_info "开始恢复 MySQL 数据库..."
    log_info "模式: $mode"
    log_info "容器: $container_name"

    # 检查容器状态
    if ! check_container "$container_name"; then
        exit 1
    fi

    # 确认操作（除非强制模式）
    if [ "$force" != true ] && ! confirm_restore "$container_name" "$backup_file"; then
        exit 1
    fi

    # 执行恢复
    if restore_database "$backup_file" "$container_name"; then
        verify_restore "$container_name"
        log_success "恢复任务完成"
    else
        log_error "恢复任务失败"
        exit 1
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
