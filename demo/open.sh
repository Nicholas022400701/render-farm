#!/usr/bin/env bash
# 把加密的 demo 录制包（demo/bundle/）解开到 work/。密钥只从环境变量 RENDER_KEY（GitHub Secrets）读，不出现在命令行、不打印任何文件名或内容。
# 先解基础包 NN.b64（演示页面与模型代码、旁白音频、片头片尾卡），再在其上覆盖补丁包 patch-NN.b64（录制与合成脚本）；改脚本只需换补丁，不必重传基础包。
set -euo pipefail
test -n "${RENDER_KEY:-}" || { echo "缺少 RENDER_KEY（仓库 Settings → Secrets and variables → Actions）" >&2; exit 1; }
open1() {   # $1 = 分块文件前缀（空 或 patch-），$2 = sha256.txt 里的标签前缀（空 或 p）
  cat demo/bundle/$1[0-9][0-9].b64 | base64 -d > /tmp/demo.enc
  grep -q "^$(sha256sum /tmp/demo.enc | cut -d' ' -f1)  $2enc$" demo/bundle/sha256.txt || { echo "加密包的指纹不对，可能上传时坏了" >&2; exit 1; }
  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in /tmp/demo.enc -out /tmp/demo.tgz 2>/dev/null || { echo "解不开：密钥不对" >&2; exit 1; }
  grep -q "^$(sha256sum /tmp/demo.tgz | cut -d' ' -f1)  $2tgz$" demo/bundle/sha256.txt || { echo "解出来的内容指纹不对：密钥不对" >&2; exit 1; }
  mkdir -p work && tar xzf /tmp/demo.tgz -C work --strip-components=1
  rm -f /tmp/demo.enc /tmp/demo.tgz
}
open1 "" ""
ls demo/bundle/patch-[0-9][0-9].b64 >/dev/null 2>&1 && open1 patch- p
echo "录制包已解开：$(find work -type f | wc -l) 个文件"
