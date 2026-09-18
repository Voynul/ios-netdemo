# adjust_demo

自建 iOS SDK 接入 Demo。App 只初始化官方 Adjust iOS SDK，并在启动时调用官方
deep link 处理入口；字段、网址、方法、队列和 Authorization 均由 SDK 与指定版本
`AdjustSigSdk` 生成，供 Reqable 抓包后冻结真实样本。

本目录属于 `E:\work\IOS_adjust` 工作区（iOS Adjust 签名复现）。规则见同目录 `AGENTS.md`。

版本跑通状态与实测记录见 [VERSION_LOG.md](VERSION_LOG.md)。

## 这个 Demo 解决什么

本工作区的算法复现任务要求「真实 iOS HTTP 样本」和文档后的网络发包验证，
但目标是官方 Dynamic xcframework，不是某个 App，本机跑不出 Adjust 流量。

Demo 补上这一环：它接入指定版本的 Adjust SDK 与签名库，由 SDK 产生真实请求。
抓到的 Authorization 就是该版本的 HTTP 真值。

## 工作原理

```text
Config/demo-config.json
  → CI 下载指定 AdjustSdk 和 AdjustSigSdk xcframework
  → xcodegen 生成工程，链接并内嵌两个 framework
  → App 以 production 初始化 Adjust SDK
  → App 启动时提交 deep link
  → SDK 内部生成 session、sdk_click 和后续归因请求
```

App 不做算法复现，也不替代 `adjust_test/adjust-signature`。它只负责用真实签名库
产出真实请求。

## 切换版本

只改 `Config/demo-config.json` 的 `nativeVersion`（必要时同改 `adjustSdkVersion`），
推送到 `main` 即触发重新构建。签名库由 CI 从官方 releases 下载，仓库不存二进制。

| 字段 | 说明 |
| --- | --- |
| `nativeVersion` | 决定链接哪个版本的 `AdjustSigSdk`，同时写入 Authorization 的 `native_version` |
| `adjustSdkVersion` | 决定构建时接入哪个 Adjust iOS SDK；`client_sdk` 由 SDK 自己生成 |
| `appToken` | 请求里的 `app_token` |
| `environment` | 固定为 `production`；不是 production 时 App 拒绝初始化 SDK |
| `startupDeeplink` | 启动时交给 `Adjust.processDeeplink` 的业务 deep link，不是 HTTP 接口地址 |

## 请求行为

App 启动后执行两步：

1. 使用 `ADJEnvironmentProduction` 初始化 Adjust SDK。
2. 立即调用 `Adjust.processDeeplink`，让 SDK 内部生成 `/sdk_click`。

`/session` 由 SDK 生命周期产生。`/attribution` 是否发送、发送时间和方法由 SDK
状态及服务端响应决定。Demo 不手工构造请求，也不保证固定三连顺序。

## 构建

宿主仓库：`https://github.com/Voynul/ios-netdemo`，本 Demo 位于其 `adjust_demo/` 子目录。
构建工作流部署在仓库根的 `.github/workflows/build-adjust-demo.yml`。

推送到 `main` 且改动命中 `adjust_demo/` 时自动触发；也可在 Actions 页面手动触发。

```powershell
gh workflow run build-adjust-demo-ipa --repo Voynul/ios-netdemo
gh run list --limit 5
gh run download <run-id> -n AdjustDemo-ipa -D .\dist
```

产物是未签名 IPA，用 Sideloadly 加 Apple ID 重签后装到设备。

### app_token

仓库固定使用可公开的测试 token `aa0f4lr105j4`，构建流程直接读取
`Config/demo-config.json`。若以后改用敏感 token，需恢复占位值和 Secret 注入方式。

## 抓包与冻结样本

1. 设备挂 Reqable 代理，确认 Adjust 域名的 HTTPS 能被解密。
2. 打开 App，等待 SDK 自动发送请求。
3. 在 Reqable 取得 `/session` 和启动 deep link 产生的 `/sdk_click`；若 SDK 同时产生
   `/attribution`，一并记录。样本落盘到 `../../samples/`，不得覆盖旧样本。
4. 把 Authorization 与 body 写进 `../../analysis/` 的对应记录。

这些 SDK 请求是 `../../adjust_test/adjust-signature` 对该 `nativeVersion` 对拍的输入。

## 限制

- 启动 deep link 是用于稳定进入 SDK 的 click 路径，不是 Adjust HTTP 接口地址。
- 服务端可能因占位 app_token 返回非 2xx。本 Demo 的产出是**签名真值**，
  不是「接口调用成功」的证据；5.2 发包闸门在复现工程侧执行。
- 内嵌的是 Dynamic framework，Sideloadly 重签时需要一并处理。
