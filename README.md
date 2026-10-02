# render-farm

借这个公开仓库的免费机器渲染视频。仓库里没有任何明文内容：

- `bundle/` 是加密后的源码包（AES-256，密钥只在这个仓库的 Secrets 里，名字 `RENDER_KEY`），切成几块 base64 文本存放。分两层：`NN.b64` 是整套源码的底包，`patch-NN.b64` 是之后改过的文件（覆盖在底包上），这样改几句字幕只用推一个小文件。
- 工作流 `render` 在机器上解开、渲染 20 段、每段加密后存进临时 Release；最后拼接、合音轨、核对帧数，成片加密后放进正式 Release。临时 Release 随后删除。
- 日志只打印进度、帧数、指纹，不打印文件名和内容。

拿到成片：从 Release 下载 `<标签>.mp4.enc`，用同一把密钥解开：

```
export RENDER_KEY=（密钥）
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in levers-9.mp4.enc -out levers-9.mp4
```

`sha256.txt` 里有解密后文件的指纹，可以核对。

成片一览：`levers-8` 第四稿（人话重写、换声音）；`levers-9` 第五稿（画面动作对到口播的词上，动作之间画面不动）。

## demo：录 QA-GNN-Lite 演示视频

工作流 `demo`（`.github/workflows/demo.yml`）借这台机器录一段演示：解开 `demo/bundle/` 里的加密录制包（演示页面与答题模型代码、旁白音频、片头片尾卡、录制脚本），模型文件从缓存 Release `demo-assets`（已加密，首次运行时自动生成）取回，真实模型在机器上答题，浏览器按脚本点击、打字、滚动并逐帧截取（目标每秒 60 帧），再定帧率、接旁白与字幕、加片头片尾、做检查。结果（成片 mp4、检查图、全部日志）加密后放进 Release `<标签>.tgz.enc`：

```
export RENDER_KEY=（密钥）
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in demo-1.tgz.enc -out demo-1.tgz && tar xzf demo-1.tgz
```

录制包同样分两层：`demo/bundle/NN.b64` 是底包，`patch-NN.b64` 是录制脚本的补丁（覆盖在底包上），改脚本只用换补丁。
