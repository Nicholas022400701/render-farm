# render-farm

借这个公开仓库的免费机器渲染视频。仓库里没有任何明文内容：

- `bundle/` 是加密后的源码包（AES-256，密钥只在这个仓库的 Secrets 里，名字 `RENDER_KEY`），切成几块 base64 文本存放。
- 工作流 `render` 在机器上解开、渲染 20 段、每段加密后存进临时 Release；最后拼接、合音轨、核对帧数，成片加密后放进正式 Release。临时 Release 随后删除。
- 日志只打印进度、帧数、指纹，不打印文件名和内容。

拿到成片：从 Release 下载 `<标签>.mp4.enc`，用同一把密钥解开：

```
export RENDER_KEY=（密钥）
openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:RENDER_KEY -in levers-4.mp4.enc -out levers-4.mp4
```

`sha256.txt` 里有解密后文件的指纹，可以核对。
