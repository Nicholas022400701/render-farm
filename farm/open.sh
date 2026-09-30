#!/usr/bin/env bash
# 把加密的源码包解开到 work/。密钥只从环境变量 RENDER_KEY（GitHub Secrets）读，不出现在命令行、不打印任何文件名或内容。
# 三层：底包 bundle/NN.b64 是整套源码；补丁包 bundle/patch-NN.b64 是之后改过的文件（含口播 voice.mp3），解开后覆盖在底包上；
# 修补包 bundle/fix-NN.b64 是再之后改过的几个源码文件，覆盖在补丁包上（没有的层就跳过）。这样改几句字幕、几行时间表只需要推一个小文件，不必把 8 MB 的口播重新推一遍。
set -euo pipefail
test -n "${RENDER_KEY:-}" || { echo "缺少 RENDER_KEY（仓库 Settings → Secrets and variables → Actions）" >&2; exit 1; }
openOne(){ # $1 = 包名（base / patch），$2 = 分块文件的通配
  local name=$1 enc=/tmp/$1.enc tgz=/tmp/$1.tgz
  cat $2 | base64 -d > "$enc"
  grep -q "^$(sha256sum "$enc" | cut -d' ' -f1)  ${name}.enc$" bundle/sha256.txt || { echo "加密包 ${name} 的指纹不对，可能上传时坏了" >&2; exit 1; }
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in "$enc" -out "$tgz" 2>/dev/null || { echo "解不开 ${name}：密钥不对" >&2; exit 1; }
  grep -q "^$(sha256sum "$tgz" | cut -d' ' -f1)  ${name}.tgz$" bundle/sha256.txt || { echo "解出来的 ${name} 指纹不对：密钥不对" >&2; exit 1; }
  mkdir -p work && tar xzf "$tgz" -C work
  rm -f "$enc" "$tgz"
  echo "${name} 已解开"
}
openOne base 'bundle/[0-9][0-9].b64'
if ls bundle/patch-[0-9][0-9].b64 >/dev/null 2>&1; then openOne patch 'bundle/patch-[0-9][0-9].b64'; else echo "没有补丁包"; fi
if ls bundle/fix-[0-9][0-9].b64 >/dev/null 2>&1; then openOne fix 'bundle/fix-[0-9][0-9].b64'; else echo "没有修补包"; fi
echo "源码已解开：$(find work -type f | wc -l) 个文件"
