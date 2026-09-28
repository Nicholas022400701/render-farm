#!/usr/bin/env bash
# 用同一把密钥加密一个文件：seal.sh 输入 输出。解密：openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in 输入 -out 输出
set -euo pipefail
test -n "${RENDER_KEY:-}" || { echo "缺少 RENDER_KEY" >&2; exit 1; }
openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -pass env:RENDER_KEY -in "$1" -out "$2"
