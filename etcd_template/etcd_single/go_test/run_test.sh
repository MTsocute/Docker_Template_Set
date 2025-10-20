#!/bin/bash
set -e

# 进入 go_test 目录
cd "$(dirname "$0")"

# 安装依赖
if [ ! -f go.sum ]; then
  go mod tidy
fi

# 运行测试脚本
go run test_etcd.go
