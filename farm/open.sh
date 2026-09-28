#!/usr/bin/env bash
# 把加密的源码包解开到 work/。密钥只从环境变量 RENDER_KEY（GitHub Secrets）读，不出现在命令行、不打印任何文件名或内容。
set -euo pipefail
test -n "${RENDER_KEY:-}" || { echo "缺少 RENDER_KEY（仓库 Settings → Secrets and variables → Actions）" >&2; exit 1; }
cat bundle/[0-9][0-9].b64 | base64 -d > /tmp/bundle.enc
grep -q "^$(sha256sum /tmp/bundle.enc | cut -d' ' -f1)  enc$" bundle/sha256.txt || { echo "加密包的指纹不对，可能上传时坏了" >&2; exit 1; }
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in /tmp/bundle.enc -out /tmp/bundle.tgz 2>/dev/null || { echo "解不开：密钥不对" >&2; exit 1; }
grep -q "^$(sha256sum /tmp/bundle.tgz | cut -d' ' -f1)  tgz$" bundle/sha256.txt || { echo "解出来的内容指纹不对：密钥不对" >&2; exit 1; }
mkdir -p work && tar xzf /tmp/bundle.tgz -C work
rm -f /tmp/bundle.enc /tmp/bundle.tgz
echo "源码已解开：$(find work -type f | wc -l) 个文件"
