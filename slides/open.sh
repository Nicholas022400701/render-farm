#!/usr/bin/env bash
# 把加密的 slides 源码包（slides/bundle/）解开到 work/。密钥只从环境变量 RENDER_KEY（GitHub Secrets）读，不出现在命令行、不打印任何文件名或内容。
# 与 farm/open.sh 的差别：包目录换成 slides/bundle/，tar 顶层目录 motion/ 去掉一层，解出来 work/ 就是 Remotion 工程根。
set -euo pipefail
test -n "${RENDER_KEY:-}" || { echo "缺少 RENDER_KEY（仓库 Settings → Secrets and variables → Actions）" >&2; exit 1; }
cat slides/bundle/[0-9][0-9].b64 | base64 -d > /tmp/slides.enc
grep -q "^$(sha256sum /tmp/slides.enc | cut -d' ' -f1)  enc$" slides/bundle/sha256.txt || { echo "加密包的指纹不对，可能上传时坏了" >&2; exit 1; }
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in /tmp/slides.enc -out /tmp/slides.tgz 2>/dev/null || { echo "解不开：密钥不对" >&2; exit 1; }
grep -q "^$(sha256sum /tmp/slides.tgz | cut -d' ' -f1)  tgz$" slides/bundle/sha256.txt || { echo "解出来的内容指纹不对：密钥不对" >&2; exit 1; }
mkdir -p work && tar xzf /tmp/slides.tgz -C work --strip-components=1
rm -f /tmp/slides.enc /tmp/slides.tgz
echo "源码已解开：$(find work -type f | wc -l) 个文件"
