#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 图标定义
ROCKET="🚀"
STOP="🛑"
LOGS="📋"
STATUS="📊"
CONFIG="⚙️"
DOCKER="🐳"
SUCCESS="✅"
ERROR="❌"
INFO="ℹ️"
LOADING="⏳"
MQTT="📡"
DASHBOARD="🖥️"

# 函数：打印带颜色的标题
print_header() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                    EMQX Docker 管理工具                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# 函数：打印分隔线
print_separator() {
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
}

# 函数：启动服务
start_services() {
    echo -e "\n${ROCKET} ${GREEN}启动 EMQX 服务...${NC}"
    print_separator

    if docker-compose up -d; then
        echo -e "\n${SUCCESS} ${GREEN}EMQX 服务启动成功！${NC}"
        echo -e "${MQTT} ${CYAN}MQTT 端口: 1883 (TCP), 8883 (SSL)${NC}"
        echo -e "${MQTT} ${CYAN}WebSocket 端口: 8083 (WS), 8084 (WSS)${NC}"
        echo -e "${DASHBOARD} ${CYAN}管理界面: http://localhost:18083${NC}"
        echo -e "${INFO} ${YELLOW}默认账户/密码: admin/123456${NC}"

        # 等待服务启动并检查健康状态
        echo -e "\n${LOADING} ${YELLOW}等待服务就绪...${NC}"
        sleep 5
        check_health
    else
        echo -e "\n${ERROR} ${RED}服务启动失败！${NC}"
        return 1
    fi
}

# 函数：停止服务
stop_services() {
    echo -e "\n${STOP} ${YELLOW}停止 EMQX 服务...${NC}"
    print_separator

    if docker-compose down; then
        echo -e "\n${SUCCESS} ${GREEN}EMQX 服务已停止！${NC}"
    else
        echo -e "\n${ERROR} ${RED}服务停止失败！${NC}"
        return 1
    fi
}

# 函数：查看日志
view_logs() {
    echo -e "\n${LOGS} ${CYAN}查看 EMQX 服务日志...${NC}"
    print_separator
    echo -e "${INFO} ${YELLOW}按 Ctrl+C 退出日志查看${NC}\n"

    docker-compose logs -f emqx
}

# 函数：查看服务状态
check_status() {
    echo -e "\n${STATUS} ${BLUE}检查服务状态...${NC}"
    print_separator

    # 检查容器状态
    if docker-compose ps | grep -q "emqx"; then
        echo -e "${SUCCESS} ${GREEN}容器状态:${NC}"
        docker-compose ps

        echo -e "\n${INFO} ${CYAN}容器详细信息:${NC}"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" emqx 2>/dev/null || echo -e "${ERROR} ${RED}无法获取容器统计信息${NC}"
    else
        echo -e "${ERROR} ${RED}EMQX 容器未运行${NC}"
    fi
}

# 函数：检查服务健康状态
check_health() {
    echo -e "\n${INFO} ${CYAN}检查 EMQX 健康状态...${NC}"

    # 检查端口是否可用
    local ports=(1883 8083 8084 8883 18083)
    local port_names=("MQTT TCP" "MQTT WebSocket" "MQTT WSS" "MQTT SSL" "Dashboard")

    for i in "${!ports[@]}"; do
        if nc -z localhost "${ports[$i]}" 2>/dev/null; then
            echo -e "${SUCCESS} ${GREEN}${port_names[$i]} 端口 (${ports[$i]}) 可访问${NC}"
        else
            echo -e "${ERROR} ${RED}${port_names[$i]} 端口 (${ports[$i]}) 不可访问${NC}"
        fi
    done

    # 尝试连接 EMQX 状态API
    echo -e "\n${LOADING} ${YELLOW}测试 EMQX 管理API 连接...${NC}"
    if docker exec emqx /opt/emqx/bin/emqx_ctl status 2>/dev/null | grep -q "is running"; then
        echo -e "${SUCCESS} ${GREEN}EMQX 服务运行正常${NC}"
    else
        echo -e "${ERROR} ${RED}EMQX 服务状态异常${NC}"
    fi
}

# 函数：重启服务
restart_services() {
    echo -e "\n${ROCKET} ${YELLOW}重启 EMQX 服务...${NC}"
    print_separator

    stop_services
    sleep 2
    start_services
}

# 函数：显示配置信息
show_config() {
    echo -e "\n${CONFIG} ${CYAN}EMQX 配置信息:${NC}"
    print_separator
    echo -e "${INFO} ${WHITE}容器名称:${NC} emqx"
    echo -e "${INFO} ${WHITE}镜像版本:${NC} emqx/emqx:5.0.12"
    echo -e "${INFO} ${WHITE}MQTT TCP 端口:${NC} 1883"
    echo -e "${INFO} ${WHITE}MQTT SSL 端口:${NC} 8883"
    echo -e "${INFO} ${WHITE}WebSocket 端口:${NC} 8083"
    echo -e "${INFO} ${WHITE}WebSocket SSL 端口:${NC} 8084"
    echo -e "${INFO} ${WHITE}管理界面端口:${NC} 18083"
    echo -e "${INFO} ${WHITE}网络:${NC} emqx-network"
    echo -e "${INFO} ${WHITE}数据卷:${NC} emqx_data, emqx_log"
    echo -e "${INFO} ${WHITE}默认管理员-账号/密码:${NC} admin/public"
    echo -e "${INFO} ${WHITE}管理界面:${NC} http://localhost:18083"
}

# 函数：显示菜单
show_menu() {
    print_header
    echo -e "\n${WHITE}请选择操作:${NC}"
    echo -e "${GREEN}1)${NC} ${ROCKET} 启动 EMQX 服务"
    echo -e "${RED}2)${NC} ${STOP} 停止 EMQX 服务"
    echo -e "${YELLOW}3)${NC} ${ROCKET} 重启 EMQX 服务"
    echo -e "${CYAN}4)${NC} ${LOGS} 查看服务日志"
    echo -e "${BLUE}5)${NC} ${STATUS} 检查服务状态"
    echo -e "${PURPLE}6)${NC} ${CONFIG} 显示配置信息"
    echo -e "${GREEN}7)${NC} ${DASHBOARD} 打开管理界面"
    echo -e "${WHITE}8)${NC} ❓ 显示帮助"
    echo -e "${RED}0)${NC} 🚪 退出"
    print_separator
}

# 函数：打开管理界面
open_dashboard() {
    echo -e "\n${DASHBOARD} ${CYAN}打开 EMQX 管理界面...${NC}"

    # 检查服务是否运行
    if docker-compose ps | grep -q "emqx.*Up"; then
        echo -e "${INFO} ${GREEN}管理界面地址: http://localhost:18083${NC}"
        echo -e "${INFO} ${YELLOW}默认账户: admin${NC}"
        echo -e "${INFO} ${YELLOW}默认密码: public${NC}"

        # 尝试打开浏览器（如果可能）
        if command -v xdg-open &> /dev/null; then
            echo -e "${LOADING} ${YELLOW}正在打开浏览器...${NC}"
            xdg-open "http://localhost:18083" &> /dev/null &
        elif command -v open &> /dev/null; then
            echo -e "${LOADING} ${YELLOW}正在打开浏览器...${NC}"
            open "http://localhost:18083" &> /dev/null &
        else
            echo -e "${INFO} ${CYAN}请手动打开浏览器访问: http://localhost:18083${NC}"
        fi
    else
        echo -e "${ERROR} ${RED}EMQX 服务未运行，请先启动服务${NC}"
    fi
}

# 函数：显示帮助
show_help() {
    echo -e "\n${INFO} ${CYAN}EMQX Docker 管理工具帮助:${NC}"
    print_separator
    echo -e "${WHITE}用法:${NC}"
    echo -e "  ./emqx_manager.sh [选项]"
    echo -e "\n${WHITE}选项:${NC}"
    echo -e "  start      - 启动 EMQX 服务"
    echo -e "  stop       - 停止 EMQX 服务"
    echo -e "  restart    - 重启 EMQX 服务"
    echo -e "  logs       - 查看服务日志"
    echo -e "  status     - 检查服务状态"
    echo -e "  config     - 显示配置信息"
    echo -e "  dashboard  - 打开管理界面"
    echo -e "  help       - 显示此帮助信息"
    echo -e "\n${WHITE}端口说明:${NC}"
    echo -e "  1883  - MQTT TCP 端口"
    echo -e "  8883  - MQTT SSL 端口"
    echo -e "  8083  - MQTT WebSocket 端口"
    echo -e "  8084  - MQTT WebSocket SSL 端口"
    echo -e "  18083 - Web 管理界面"
    echo -e "\n${WHITE}示例:${NC}"
    echo -e "  ./emqx_manager.sh start"
    echo -e "  ./emqx_manager.sh logs"
    echo -e "  ./emqx_manager.sh dashboard"
    echo -e "\n${INFO} ${YELLOW}无参数运行将显示交互式菜单${NC}"
}

# 主函数
main() {
    # 检查是否安装了必要的工具
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${ERROR} ${RED}错误: 未找到 docker-compose 命令${NC}"
        echo -e "${INFO} ${YELLOW}请先安装 Docker Compose${NC}"
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        echo -e "${ERROR} ${RED}错误: 未找到 docker 命令${NC}"
        echo -e "${INFO} ${YELLOW}请先安装 Docker${NC}"
        exit 1
    fi

    # 处理命令行参数
    case "$1" in
        "start")
            print_header
            start_services
            ;;
        "stop")
            print_header
            stop_services
            ;;
        "restart")
            print_header
            restart_services
            ;;
        "logs")
            print_header
            view_logs
            ;;
        "status")
            print_header
            check_status
            ;;
        "config")
            print_header
            show_config
            ;;
        "dashboard")
            print_header
            open_dashboard
            ;;
        "help"|"-h"|"--help")
            print_header
            show_help
            ;;
        "")
            # 交互式菜单
            while true; do
                show_menu
                echo -n -e "${WHITE}请输入选择 [0-8]: ${NC}"
                read -r choice

                case $choice in
                    1)
                        start_services
                        echo -e "\n${INFO} ${YELLOW}按任意键返回菜单...${NC}"
                        read -r
                        ;;
                    2)
                        stop_services
                        echo -e "\n${INFO} ${YELLOW}按任意键返回菜单...${NC}"
                        read -r
                        ;;
                    3)
                        restart_services
                        echo -e "\n${INFO} ${YELLOW}按任意键返回菜单...${NC}"
                        read -r
                        ;;
                    4)
                        view_logs
                        ;;
                    5)
                        check_status
                        echo -e "\n${INFO} ${YELLOW}按任意键返回菜单...${NC}"
                        read -r
                        ;;
                    6)
                        show_config
                        echo -e "\n${INFO} ${YELLOW}按任意键返回菜单...${NC}"
                        read -r
                        ;;
                    7)
                        open_dashboard
                        echo -e "\n${INFO} ${YELLOW}按任意键返回菜单...${NC}"
                        read -r
                        ;;
                    8)
                        show_help
                        echo -e "\n${INFO} ${YELLOW}按任意键返回菜单...${NC}"
                        read -r
                        ;;
                    0)
                        echo -e "\n${SUCCESS} ${GREEN}再见！${NC}\n"
                        exit 0
                        ;;
                    *)
                        echo -e "\n${ERROR} ${RED}无效选择，请输入 0-8${NC}"
                        echo -e "${INFO} ${YELLOW}按任意键继续...${NC}"
                        read -r
                        ;;
                esac
            done
            ;;
        *)
            print_header
            echo -e "\n${ERROR} ${RED}未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
