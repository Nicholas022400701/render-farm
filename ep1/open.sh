#!/usr/bin/env bash
# 把 ep1 的加密源码包解开到 work/。密钥只从环境变量 RENDER_KEY（GitHub Secrets）读，不出现在命令行、不打印任何文件名或内容。
# 格式与 farm/open.sh 相同：ep1/bundle/NN.b64 是 base64 分块，拼起来是 openssl aes-256-cbc（pbkdf2，10 万次）加密的 tar.gz；sha256.txt 记录密文与明文的指纹。
set -euo pipefail
test -n "${RENDER_KEY:-}" || { echo "缺少 RENDER_KEY（仓库 Settings → Secrets and variables → Actions）" >&2; exit 1; }
openOne(){ # $1 = 包名（base / patch），$2 = 分块文件的通配
  local name=$1 enc=/tmp/ep1-$1.enc tgz=/tmp/ep1-$1.tgz
  cat $2 | base64 -d > "$enc"
  grep -q "^$(sha256sum "$enc" | cut -d' ' -f1)  ${name}.enc$" ep1/bundle/sha256.txt || { echo "加密包 ${name} 的指纹不对，可能上传时坏了" >&2; exit 1; }
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in "$enc" -out "$tgz" 2>/dev/null || { echo "解不开 ${name}：密钥不对" >&2; exit 1; }
  grep -q "^$(sha256sum "$tgz" | cut -d' ' -f1)  ${name}.tgz$" ep1/bundle/sha256.txt || { echo "解出来的 ${name} 指纹不对：密钥不对" >&2; exit 1; }
  mkdir -p work && tar xzf "$tgz" -C work
  rm -f "$enc" "$tgz"
  echo "${name} 已解开"
}
openOne base 'ep1/bundle/[0-9][0-9].b64'
if ls ep1/bundle/patch-[0-9][0-9].b64 >/dev/null 2>&1; then openOne patch 'ep1/bundle/patch-[0-9][0-9].b64'; else echo "没有补丁包"; fi
echo "源码已解开：$(find work -type f | wc -l) 个文件"
