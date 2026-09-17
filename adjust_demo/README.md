# adjust_demo

自建 iOS 发包 Demo。用官方 `AdjustSigSdk` 签名库现签，向 Adjust 接口发真实请求，
供 Reqable 抓包后冻结点对样本。

本目录属于 `E:\work\IOS_adjust` 工作区（iOS Adjust 签名复现）。规则见同目录 `AGENTS.md`。

版本跑通状态与实测记录见 [VERSION_LOG.md](VERSION_LOG.md)。

## 这个 Demo 解决什么

本工作区的算法复现任务要求「真实 iOS HTTP 样本」和文档后的网络发包验证，
但目标是官方 Dynamic xcframework，不是某个 App，本机跑不出 Adjust 流量。

Demo 补上这一环：它链接指定 `nativeVersion` 的签名库，按 Adjust 的请求格式发包，
抓到的 Authorization 就是该版本的 HTTP 真值。

## 工作原理

```text
Config/demo-config.json
  → CI 按 nativeVersion 下载 AdjustSigSdk.xcframework
  → xcodegen 生成工程，链接并内嵌该 framework
  → App 组字段 → ADJSigner 签名 → 拼 Authorization → POST
```

App 不做算法复现，也不替代 `adjust_test/adjust-signature`。它只负责用真实签名库
产出真实请求。

## 切换版本

只改 `Config/demo-config.json` 的 `nativeVersion`（必要时同改 `clientSdk`），
推送到 `main` 即触发重新构建。签名库由 CI 从官方 releases 下载，仓库不存二进制。

| 字段 | 说明 |
| --- | --- |
| `nativeVersion` | 决定链接哪个版本的 `AdjustSigSdk`，同时写入 Authorization 的 `native_version` |
| `clientSdk` | 写入 `client_sdk` 字段与 `Client-SDK` 头 |
| `appToken` | 请求里的 `app_token` |
| `environment` | `sandbox` 或 `production`，写入 `environment` 字段 |
| `host` / `scheme` | 目标地址，默认 `https://app.adjust.com` |
| `autoSend` | 启动后自动发包 |
| `intervalSeconds` | 三个请求之间的间隔 |

## 请求内容

固定顺序发三个请求，与根目录 `AGENTS.md` 5.2 一致：

| 顺序 | path | `activity_kind` |
| --- | --- | --- |
| 1 | `/session` | `session` |
| 2 | `/sdk_click` | `click` |
| 3 | `/attribution` | `attribution` |

16 个输入字段依据 `analysis/unidbg/3201-sign-probe.md` 的 Probe 输入与
`analysis/ida/3201-whitelist-keys.txt` 的 85 键白名单。`secret_id` 不进输入，
由签名库注入缺省值。

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

真实 App token 存在仓库 Secret `ADJUST_APP_TOKEN`，构建时注入，仓库里只有占位值
`REPLACE_WITH_ADJUST_APP_TOKEN`。未配置 Secret 时仍可构建，签名完整，只是请求会
带占位 token。

```powershell
gh secret set ADJUST_APP_TOKEN --repo Voynul/ios-netdemo --body "<真实 token>"
```

## 抓包与冻结样本

1. 设备挂 Reqable 代理，确认 Adjust 域名的 HTTPS 能被解密。
2. 打开 App，等三个请求发完。
3. 在 Reqable 取 `/session`、`/sdk_click`、`/attribution` 三条，落盘到
   `../samples/`（不覆盖旧样本）。
4. 把 Authorization 与 body 写进 `../analysis/` 的对应记录。

三条样本是 `adjust_test/adjust-signature` 对该 `nativeVersion` 对拍的输入。

## 限制

- 本 Demo 自己组字段并发包，不经过 Adjust 官方 iOS SDK，因此字段集是
  「够用且可追溯」，不等同于某个真实 App 的完整字段集。
- 服务端可能因占位 app_token 返回非 2xx。本 Demo 的产出是**签名真值**，
  不是「接口调用成功」的证据；5.2 发包闸门在复现工程侧执行。
- 内嵌的是 Dynamic framework，Sideloadly 重签时需要一并处理。
