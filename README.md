# NetDemo

一个用 SwiftUI 写的 iOS 网络测试应用，同时是**在 Windows 上交付 iOS 应用**的完整可复现参考实现。

本仓库验证了一条路径：工作机完全不需要 macOS，也能做出可安装、可运行、能收发网络数据的 iOS 应用。全部数据来自真实执行，不是理论流程。

本仓库包含两个独立的 iOS 工程：

| 目录 | 工程 | 说明 |
| --- | --- | --- |
| 仓库根 | NetDemo | 本文档介绍的对象。SwiftUI 网络测试应用 + Windows 交付参考实现 |
| [`adjust_demo/`](adjust_demo/) | AdjustDemo | 链接 Adjust 官方 `AdjustSigSdk` 签名库的发包演示，用于产出真实 Adjust HTTP 样本。见其 [README](adjust_demo/README.md) |

两者的构建工作流各自独立，带路径过滤，互不触发。

---

## 这个项目做什么

**作为应用**，NetDemo 是一个轻量的 HTTP 请求工具，运行在 iPhone 上：

| 功能 | 说明 |
| --- | --- |
| 发送请求 | 支持 GET / POST / PUT，可自定义 URL |
| 编辑请求体 | 内置 JSON 编辑器，可修改请求内容 |
| 查看响应 | 显示 HTTP 状态码、往返耗时、响应体全文 |
| 明文 HTTP | 已配置 ATS 例外，HTTP 端点同样可访问 |
| 预设地址 | 内置公开回显服务，便于快速验证连通性 |

它适合用来验证 iOS 设备上的网络链路：请求能否发出、服务器能否收到、响应能否正确解析。

**作为参考实现**，本仓库演示了在 Windows 上从零完成 iOS 应用交付的全部环节，包括工程搭建、云端编译、产物校验、签名安装与真机验证。

---

## 为什么需要这套方案

Windows 无法独立编译 iOS 应用。iPhoneOS SDK 的授权条款限制在 macOS 上使用，`xcodebuild`、`codesign` 等工具在 Windows 上没有可用版本，iOS 模拟器也不存在 Windows 版本。

本项目的做法是把编译环节交给云端 macOS，其余全部在 Windows 本地完成：

```text
本地 Windows          云 macOS              本地 Windows          iPhone
写 Swift 代码   ->   Actions 编译出 IPA  ->   Sideloadly 重签  ->  信任证书后运行
```

这样把不可行的环节限制到最小，同时保留完整的调试与迭代能力。

---

## 目录结构

```text
.
├── project.yml                       XcodeGen 工程描述
├── Resources/
│   └── Info.plist                    包信息与 ATS 配置
├── Sources/
│   ├── NetDemoApp.swift              应用入口
│   ├── ContentView.swift             界面
│   └── NetworkClient.swift           网络请求实现
├── .github/workflows/
│   └── build-ipa.yml                 云端编译与打包
└── docs/
    └── windows-ios-ipa-playbook.md   完整操作手册
```

---

## 编译

推送到 `main` 分支会自动触发构建，也可以在 Actions 页面手动触发。

```bash
git clone https://github.com/Voynul/ios-netdemo.git
cd ios-netdemo
# 修改代码后提交并推送，即自动触发云端构建
git commit -am "改动说明" && git push
```

构建在 `macos-15` runner 上执行，产出未签名的 `NetDemo.ipa`，作为 artifact 供下载。

用命令行触发与获取产物：

```powershell
# 触发构建
gh workflow run build-ipa

# 查看运行状态
gh run list --limit 5

# 下载产物
gh run download <run-id> -n NetDemo-ipa -D .\dist
```

本地也可以指定目标平台重新生成工程，但这一步不要期望在 Windows 上完成编译。

---

## 安装到 iPhone

未签名的 IPA 无法直接安装，需要用 Apple ID 重新签名。推荐使用 Sideloadly。

1. 下载并安装 Sideloadly（`https://sideloadly.io`）。
2. 用数据线连接 iPhone，在手机上点信任此电脑。
3. 打开 Sideloadly，填入 Apple ID，把 `NetDemo.ipa` 拖入窗口，点 Start。
4. 手机上进入 设置 → 通用 → VPN与设备管理，信任对应的开发者证书。
5. iOS 16 及以上还需开启开发者模式：设置 → 隐私与安全性 → 开发者模式。

安装完成后打开应用，默认地址为 `https://httpbin.org/post`，点击发送即可看到服务器回显的 JSON 与状态码。

**注意**：免费 Apple ID 的签名有效期为 7 天，到期后应用无法打开，重新用 Sideloadly 签一次即可。

---

## 完整文档

详细的操作流程、工程配置逐项说明、产物校验脚本、问题排查表与备选方案，见：

**[Windows 环境下创建、安装、运行 iOS 应用完整手册](docs/windows-ios-ipa-playbook.md)**

手册覆盖内容包括能力边界判断、XcodeGen 配置要点、Actions workflow 全文、IPA 产物校验判据、Sideloadly 安全实测结论、首次启动的信任流程、12 条常见问题排查，以及免费账号限制与六种备选路径对比。

---

## 验证记录

本仓库的流程经过一次完整交付验证，实测数据如下：

| 项目 | 实测值 |
| --- | --- |
| 验证日期 | 2026-09-17 |
| 工作机 | Windows 11 |
| 云构建 | GitHub Actions `macos-15`，Xcode 16.4 (16F6) |
| 构建结果 | 成功，11 个步骤全部通过 |
| 产物 | `NetDemo.ipa`，49554 字节 |
| SHA-256 | `193553c7b016843eebf57387c2b1e6e65135b4d009009b6cae6d5c6089df4fd5` |
| 二进制架构 | arm64，MH_EXECUTE |
| 签名工具 | Sideloadly 0.60.0 |
| 最终结果 | 应用成功安装并启动，网络请求收到服务器响应 |

---

## 已知限制

| 限制 | 说明 |
| --- | --- |
| 无法在 Windows 上编译 | 必须依赖云端 macOS，离线环境不可用 |
| 签名 7 天过期 | 免费 Apple ID 的固有限制，需定期重签 |
| 最多 3 个自签应用 | 同时安装数量受免费账号规则限制 |
| 无应用图标 | 工程未配置图标资源，桌面显示默认灰色图标 |
| 云构建需联网 | 公开仓库免费，私有仓库按十倍系数扣减额度 |

---

## 开源许可

本仓库内容可自由用于学习与参考。
