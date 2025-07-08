#!/bin/bash

# IT Words Learning - Docker快速启动脚本
# 本脚本将帮助你快速启动本地Docker环境

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo_title() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# 检查Docker是否安装
check_docker() {
    echo_title "检查Docker环境"
    
    if ! command -v docker &> /dev/null; then
        echo_error "Docker未安装。请先安装Docker Desktop: https://www.docker.com/products/docker-desktop"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo_error "Docker Compose未安装。请先安装Docker Compose"
        exit 1
    fi
    
    # 检查Docker是否运行
    if ! docker info &> /dev/null; then
        echo_error "Docker未运行。请启动Docker Desktop"
        exit 1
    fi
    
    echo_info "Docker环境检查通过"
}

# 准备环境文件
prepare_env() {
    echo_title "准备环境配置"
    
    if [ ! -f .env ]; then
        echo_info "创建.env文件..."
        cp docker-env.template .env
        echo_info ".env文件已创建，使用默认配置"
    else
        echo_info ".env文件已存在"
    fi
}

# 构建镜像
build_images() {
    echo_title "构建Docker镜像"
    
    echo_info "开始构建镜像，这可能需要几分钟..."
    
    # 构建所有服务
    docker-compose build --no-cache
    
    echo_info "镜像构建完成"
}

# 启动服务
start_services() {
    echo_title "启动服务"
    
    echo_info "启动所有服务..."
    
    # 启动服务
    docker-compose up -d
    
    echo_info "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    echo_title "等待服务就绪"
    
    echo_info "等待数据库启动..."
    # 等待MySQL启动
    for i in {1..30}; do
        if docker-compose exec -T db mysqladmin ping -h"localhost" --silent; then
            echo_info "数据库已就绪"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    echo_info "等待后端服务启动..."
    # 等待后端启动
    for i in {1..30}; do
        if curl -s http://localhost:8080/actuator/health &> /dev/null; then
            echo_info "后端服务已就绪"
            break
        fi
        echo -n "."
        sleep 2
    done
    
    echo_info "等待前端服务启动..."
    # 等待前端启动
    for i in {1..30}; do
        if curl -s http://localhost:80/health &> /dev/null; then
            echo_info "前端服务已就绪"
            break
        fi
        echo -n "."
        sleep 2
    done
}

# 显示服务状态
show_status() {
    echo_title "服务状态"
    
    echo_info "检查服务状态..."
    docker-compose ps
    
    echo ""
    echo_title "访问地址"
    echo_info "前端应用: http://localhost:80"
    echo_info "后端API: http://localhost:8080"
    echo_info "数据库: localhost:3306"
    echo_info "健康检查: http://localhost:8080/actuator/health"
    
    echo ""
    echo_title "常用命令"
    echo_info "查看日志: docker-compose logs -f"
    echo_info "停止服务: docker-compose down"
    echo_info "重启服务: docker-compose restart"
    echo_info "删除所有数据: docker-compose down -v"
}

# 主函数
main() {
    echo_title "IT Words Learning - Docker快速启动"
    
    check_docker
    prepare_env
    build_images
    start_services
    wait_for_services
    show_status
    
    echo ""
    echo_info "🎉 应用启动完成！"
    echo_info "访问 http://localhost:80 开始使用"
    echo_warn "首次启动可能需要等待数据库初始化完成"
}

# 清理函数
cleanup() {
    echo_title "清理资源"
    
    echo_info "停止所有服务..."
    docker-compose down
    
    echo_info "删除所有数据..."
    docker-compose down -v
    
    echo_info "清理完成"
}

# 检查参数
case "$1" in
    "cleanup"|"clean")
        cleanup
        exit 0
        ;;
    "status")
        show_status
        exit 0
        ;;
    *)
        main
        ;;
esac 