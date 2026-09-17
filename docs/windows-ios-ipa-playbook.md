# Windows 环境下创建、安装、运行 iOS 应用（IPA）完整手册

本手册的目标读者是需要交付**可运行的 iOS 应用**、但工作机是 Windows 的 Agent 与用户。

参考实现：`C:\Users\Admin\ios-netdemo`（公开仓库 `https://github.com/Voynul/ios-netdemo`）

全部内容基于一次真实交付验证，不是理论流程。验证记录：

| 项目 | 实测值 |
| --- | --- |
| 验证日期 | 2026-09-17 |
| 主机 | Windows 11 |
| 云构建 | GitHub Actions `macos-15`，Xcode 16.4 (16F6) |
| 构建耗时 | 约 27 秒（runner 启动后） |
| 产物 | `NetDemo.ipa`，49554 字节，SHA-256 `193553c7b016843eebf57387c2b1e6e65135b4d009009b6cae6d5c6089df4fd5` |
| 签名工具 | Sideloadly 0.60.0 |
| 结果 | 安装成功，应用在网络请求中收到服务器响应 |

---

## 1. 能力边界：先判断可行性，再动手

Windows 无法独立完成 iOS 应用交付，但可以借助云端 macOS 完成。必须先认清哪一环受限，否则会在错误的地方浪费时间。

| 环节 | Windows 本地可行性 | 说明 |
| --- | --- | --- |
| 编写 Swift / Objective-C 工程 | 可行 | 纯文本编辑，无平台依赖 |
| 编译出 arm64 Mach-O 可执行文件 | **不可行** | 需要 iPhoneOS SDK 与 Apple 链接器。该 SDK 的授权条款限制在 macOS 上使用 |
| 云端 macOS 编译 | 可行 | GitHub Actions 提供 macOS runner，公开仓库免费 |
| 打包成 `.ipa` | 可行 | IPA 本质是 zip，内部为固定的 `Payload/` 目录结构 |
| 用 Apple 证书签名 | **不可行** | 需要 `codesign` / `ldid` 与 Apple 证书链 |
| 重签并安装到真机 | 可行 | Sideloadly 等工具调用 Apple 官方签名服务完成 |
| 运行 iOS 模拟器 | **不存在** | 模拟器仅 macOS 有，Windows 上没有任何替代方案 |

**结论**：可行路径是「本地写代码 → 云端 macOS 编译 → 本地重签安装」。

需要提前确认的硬性条件：必须有 iPhone 真机、必须有可登录的 GitHub 账号、必须能接受使用 Apple ID。

---

## 2. 前置条件与自检

### 2.1 依赖清单

| 依赖 | 用途 | 缺失后果 |
| --- | --- | --- |
| Git | 版本管理、推送代码 | 无法触发云构建 |
| GitHub CLI (`gh`) | 建仓、触发构建、下载产物 | 需改用网页操作 |
| Python 3 | 校验 IPA 产物结构 | 只能手工核对 |
| Apple Mobile Device Support | iPhone 的 USB 通信 | Sideloadly 无法识别设备 |
| Sideloadly | 重签与安装 | 无法把 IPA 装进手机 |

本机实测已具备：Git、GitHub CLI、Python 3.13、Apple Mobile Device Support 18.0.0.33。

本机实测**不需要**、也不会有：`swift`、`swiftc`、`xcodebuild`、`codesign`、`ldid`。不要去尝试补装这些，它们无法在 Windows 上工作。

### 2.2 自检命令

```powershell
# 基础工具链
foreach ($n in 'git','gh','python') {
  $c = Get-Command $n -ErrorAction SilentlyContinue
  if ($c) { "{0,-8} {1}" -f $n, $c.Source } else { "{0,-8} missing" -f $n }
}

# GitHub 登录状态与权限范围
gh auth status

# Apple 移动设备服务
Get-Service 'Apple Mobile Device Service' | Select-Object Name, Status

# usbmuxd 监听端口（iPhone 通信栈是否就绪）
Test-NetConnection 127.0.0.1 -Port 27015 -InformationLevel Quiet
```

`gh auth status` 输出的 scope 必须包含 `repo` 与 `workflow`。缺 `workflow` 会导致无法触发 Actions，补救命令：

```powershell
gh auth refresh -s workflow
```

`Test-NetConnection` 返回 `True` 表示 usbmuxd 就绪。端口 27015 是 usbmuxd 的固定监听端口，它可用即说明 iPhone 插上后能被识别。

---

## 3. 总体流程与分工边界

### 3.1 四个阶段

```text
阶段一 创建工程        本地 Windows   写 Swift 源码 + XcodeGen 描述文件
    |
阶段二 云端编译        云 macOS       GitHub Actions 产出未签名 IPA
    |
阶段三 签名安装        本地 Windows   Sideloadly 重签并写入 iPhone
    |
阶段四 验证运行        iPhone         应用启动并完成网络收发
```

### 3.2 谁做什么

这一步很关键。Agent 能自动完成的与必须由用户亲自完成的，界限清楚，不要越界代替用户操作。

| 步骤 | 执行方 | 原因 |
| --- | --- | --- |
| 写工程文件、建仓、推送 | **Agent** | 纯本地与 GitHub 读写操作 |
| 触发并轮询云构建 | **Agent** | 可通过 `gh run` 完成 |
| 下载与校验 IPA | **Agent** | 可脚本化 |
| 安装 Sideloadly | **Agent**（需用户授权，可能弹 UAC） | 写入项目目录之外 |
| 输入 Apple ID 与密码 | **用户** | Agent 不应接触用户凭据 |
| 手机端信任证书、开启开发者模式 | **用户** | 必须在 iOS 设备上操作 |
| 处理弹窗与授权 | **用户** | 需要人工点击 |

**安全红线**：不要要求用户把 Apple ID 密码发到对话里。密码只在 Sideloadly 界面输入。

---

## 4. 阶段一：创建工程

### 4.1 目录结构

```text
ios-netdemo/
├── project.yml                        XcodeGen 工程描述
├── Resources/
│   └── Info.plist                     包信息与 ATS 配置
├── Sources/
│   ├── NetDemoApp.swift               入口
│   ├── ContentView.swift              界面
│   └── NetworkClient.swift            网络请求
├── .github/workflows/build-ipa.yml    云构建定义
└── .gitignore
```

采用 XcodeGen 而非手写 `.xcodeproj`，原因是工程文件用 YAML 描述更易读、易改、易 diff，且不需要 macOS 参与生成。

### 4.2 project.yml 关键设置

以下每一项都直接影响能否编译出可安装的产物，缺一不可。

```yaml
name: NetDemo

options:
  bundleIdPrefix: com.yourname
  deploymentTarget:
    iOS: "15.0"

settings:
  base:
    SWIFT_VERSION: "5.0"

targets:
  NetDemo:
    type: application
    platform: iOS
    deploymentTarget: "15.0"
    sources:
      - path: Sources
    settings:
      base:
        PRODUCT_NAME: NetDemo
        PRODUCT_BUNDLE_IDENTIFIER: com.yourname.netdemo
        INFOPLIST_FILE: Resources/Info.plist
        TARGETED_DEVICE_FAMILY: "1"      # 1=iPhone, 2=iPad
        GENERATE_INFOPLIST_FILE: NO      # 必须关闭，否则与自备 plist 冲突
        CODE_SIGNING_ALLOWED: NO         # 产出未签名包，交给 Sideloadly 重签
        CODE_SIGNING_REQUIRED: NO
        CODE_SIGN_IDENTITY: ""
        CODE_SIGN_ENTITLEMENTS: ""
        ENABLE_BITCODE: NO               # 已废弃，显式关闭避免告警
        ONLY_ACTIVE_ARCH: NO             # 必须为 NO，否则可能只编当前架构
        ARCHS: arm64                     # 真机架构。写成 x86_64 会导致装不上

schemes:
  NetDemo:
    build:
      targets:
        NetDemo: all
    archive:
      config: Release
```

`ARCHS` 与 `ONLY_ACTIVE_ARCH` 是最容易出错的两项。模拟器架构的包无法安装到真机。

### 4.3 Info.plist 关键项

```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
<key>CFBundleExecutable</key>
<string>$(EXECUTABLE_NAME)</string>
<key>CFBundlePackageType</key>
<string>APPL</string>
<key>UILaunchScreen</key>
<dict/>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**ATS 配置是网络功能的关键**。iOS 默认拦截明文 HTTP 请求，若应用需要访问 HTTP 端点，必须加上 `NSAllowsArbitraryLoads`。HTTPS 端点不需要此项。本项目为覆盖测试场景已放开。

### 4.4 Swift 源码要点

入口简洁即可：

```swift
import SwiftUI

@main
struct NetDemoApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

网络客户端的可复用模式，使用 `async/await` 与 `URLSession`：

```swift
import Foundation

struct SendResult {
    let ok: Bool
    let detail: String
}

final class NetworkClient {
    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 40
        session = URLSession(configuration: cfg)
    }

    func send(urlString: String, method: String, body: String) async -> SendResult {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              url.host?.isEmpty == false
        else {
            return SendResult(ok: false, detail: "URL 无效")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if method != "GET", !body.isEmpty {
            request.httpBody = Data(body.utf8)
            request.setValue("application/json; charset=utf-8",
                             forHTTPHeaderField: "Content-Type")
        }

        do {
            let (data, response) = try await session.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let text = String(data: data.prefix(4000), encoding: .utf8) ?? "<二进制响应>"
            return SendResult(ok: (200..<300).contains(code),
                              detail: "HTTP \(code)\n\n\(text)")
        } catch {
            let ns = error as NSError
            return SendResult(ok: false,
                              detail: "\(ns.domain) \(ns.code)\n\(ns.localizedDescription)")
        }
    }
}
```

界面层从后台任务回写状态时必须切回主线程：

```swift
Task {
    let result = await client.send(urlString: url, method: m, body: body)
    await MainActor.run {
        output = result.detail
        isSending = false
    }
}
```

### 4.5 本阶段已踩过的坑

| 坑 | 现象 | 正确做法 |
| --- | --- | --- |
| `ForEach` 使用元组键路径 | 编译报错，Swift 不支持 `\.1` 这类键路径 | 定义 `Identifiable` 结构体承载数据 |
| 在 workflow 里给 `xcodebuild` 加管道与回退 | 构建命令被执行两遍 | 去掉管道，直接 `xcodebuild ... -quiet` |

这两个问题都会导致构建直接失败，注意规避。

---

## 5. 阶段二：云端编译产出 IPA

### 5.1 workflow 定义

```yaml
name: build-ipa

on:
  workflow_dispatch:          # 允许手动触发
  push:
    branches: [ main ]        # 推送 main 自动触发

jobs:
  ipa:
    runs-on: macos-15
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v4

      - name: Show toolchain
        run: |
          xcodebuild -version
          xcrun --sdk iphoneos --show-sdk-version

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Build unsigned .app
        run: |
          set -euo pipefail
          xcodebuild \
            -project NetDemo.xcodeproj \
            -scheme NetDemo \
            -configuration Release \
            -sdk iphoneos \
            -destination 'generic/platform=iOS' \
            -derivedDataPath build \
            CODE_SIGNING_ALLOWED=NO \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGN_ENTITLEMENTS="" \
            build -quiet

      - name: Package into .ipa
        run: |
          set -euo pipefail
          APP="build/Build/Products/Release-iphoneos/NetDemo.app"
          test -d "$APP"
          mkdir -p out/Payload
          cp -R "$APP" out/Payload/
          cd out && zip -qry NetDemo.ipa Payload

      - name: Verify package
        run: |
          set -euo pipefail
          ls -lh out/NetDemo.ipa
          unzip -l out/NetDemo.ipa
          lipo -info out/Payload/NetDemo.app/NetDemo

      - uses: actions/upload-artifact@v4
        with:
          name: NetDemo-ipa
          path: out/NetDemo.ipa
          if-no-files-found: error
```

要点说明：

- `-sdk iphoneos` 与 `-destination 'generic/platform=iOS'` 共同指向真机目标，不要写成模拟器。
- 在**命令行参数**上重复传 `CODE_SIGNING_ALLOWED=NO` 等设置，比只写在 `project.yml` 更可靠，可覆盖工程内的设置。
- `lipo -info` 输出必须包含 `arm64`。这是产物可用于真机的第一道证据。
- IPA 结构固定为 `Payload/<AppName>.app/`，`zip` 时保持 `Payload` 目录为顶层。

### 5.2 触发与监控

```powershell
Set-Location <工程目录>
git add -A
git commit -m "说明"
git push

# 查看运行列表
gh run list --limit 5

# 轮询等待完成
$deadline = (Get-Date).AddMinutes(9)
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 25
  $line = gh run list --limit 1 --json status,conclusion,databaseId `
            --jq '.[0] | "\(.status) \(.conclusion) \(.databaseId)"'
  "[{0:HH:mm:ss}] {1}" -f (Get-Date), $line
  if ($line -match '^completed') { break }
}
```

macOS runner 需要排队启动，首次触发通常要等一到两分钟才开始执行。构建本身很快，实测约 27 秒。

### 5.3 下载与校验

```powershell
gh run download <run-id> -n NetDemo-ipa -D .\dist
```

校验脚本，逐项确认产物可用：

```python
import zipfile, plistlib, struct, os, hashlib

p = r"<路径>\dist\NetDemo.ipa"
print("size:", os.path.getsize(p))
print("sha256:", hashlib.sha256(open(p, "rb").read()).hexdigest())

z = zipfile.ZipFile(p)
print("zip integrity:", "OK" if z.testzip() is None else "CORRUPT")
for i in z.infolist():
    print(f"  {i.file_size:>8}  {i.filename}")

info = plistlib.loads(z.read("Payload/NetDemo.app/Info.plist"))
for k in ["CFBundleIdentifier", "CFBundleExecutable", "MinimumOSVersion",
          "CFBundleSupportedPlatforms", "UIDeviceFamily"]:
    print(f"  {k:<28} {info.get(k)}")

raw = z.read("Payload/NetDemo.app/NetDemo")
print("Mach-O magic:", hex(struct.unpack("<I", raw[:4])[0]))
print("cputype:", struct.unpack("<ii", raw[4:12])[0], "(16777228 = ARM64)")
print("filetype:", struct.unpack("<I", raw[12:16])[0], "(2 = MH_EXECUTE)")
```

判据表，全部满足才算产物合格：

| 检查项 | 合格判据 |
| --- | --- |
| zip 完整性 | `testzip()` 返回 `None` |
| 目录结构 | 存在 `Payload/<App>.app/`、`Info.plist`、`PkgInfo`、可执行文件 |
| Mach-O magic | `0xfeedfacf`（64 位小端） |
| cputype | `16777228`，即 ARM64 |
| filetype | `2`，即 `MH_EXECUTE` |
| `CFBundleSupportedPlatforms` | 含 `iPhoneOS` |
| `DTPlatformName` | `iphoneos` |
| 代码签名 | **无** `_CodeSignature` 条目（未签名是预期状态） |

---

## 6. 阶段三：签名并安装到 iPhone

### 6.1 安装 Sideloadly

官方地址：`https://sideloadly.io/SideloadlySetup64.exe`

实测版本 0.60.0，安装包 124.93 MB，SHA-256 `625ad1e8240ee4765d0d181a33acab686b5b92f842e625c0f17e812a7893fdf4`。

```powershell
$exe = Join-Path $env:USERPROFILE 'Downloads\SideloadlySetup64.exe'
curl.exe -L --fail --max-time 600 -o $exe 'https://sideloadly.io/SideloadlySetup64.exe'
Start-Process -FilePath $exe
```

**关于安全性的实测结论**，需要如实告知用户：

| 检查项 | 实测结果 |
| --- | --- |
| 数字签名 | **无签名**。厂商未做代码签名，这是该项目长期状态 |
| 安装包类型 | 标准 NSIS 安装程序，32 位 stub |
| 导入 DLL | 7 个标准库：ADVAPI32、COMCTL32、GDI32、KERNEL32、SHELL32、USER32、ole32 |
| 键盘记录 API | 无 |
| 进程注入 API | 无 |
| 网络下载 API | 无 |
| 服务与开机自启 API | 无 |

可审计部分无恶意特征，但 **124 MB 中大部分是 NSIS 压缩载荷，静态手段无法完整核验**。这是所有闭源安装包的共同局限，应如实向用户说明，不能表述为完整审计通过。

对安装包做字符串扫描时可能命中 `uu.ru`、`WPS` 之类的片段，那些来自压缩数据的随机字节，属于误报，不应作为风险结论。

如果用户更倾向可审计方案，备选是开源的 AltServer（`altstoreio/AltServer-Windows`）。代价是对新版 iOS 的兼容性通常不如 Sideloadly。

### 6.2 安装后的实际落点

Sideloadly 是**用户级安装，不写入 HKLM 卸载表**，用注册表查询会误判为未安装。实际路径：

| 内容 | 路径 |
| --- | --- |
| 主程序 | `%LOCALAPPDATA%\Sideloadly\Sideloadly.exe` |
| 刷新守护进程 | `%LOCALAPPDATA%\Sideloadly\sideloadlydaemon.exe` |
| 卸载程序 | `%LOCALAPPDATA%\Sideloadly\Uninstall.exe` |
| 配置数据 | `%APPDATA%\Sideloadly` |

`sideloadlydaemon.exe` 常驻用于自动重签，防止免费证书过期。确认安装成功的正确方式是检查进程：

```powershell
Get-Process | Where-Object { $_.ProcessName -match 'Sideloadly' } |
  Select-Object Id, ProcessName, Path
```

### 6.3 操作步骤

**Agent 可自动完成**：下载安装包、启动安装程序、检查进程与端口。

**必须由用户完成**（Agent 不应代替）：

1. 走完安装向导，遇到 UAC 提权框点允许。
2. 用数据线连接 iPhone，手机弹出「信任此电脑」时点信任并输入锁屏密码。
3. 在 Sideloadly 界面填入 Apple ID 与密码。**不要把密码发到对话里。**
4. 把 `.ipa` 文件拖入 Sideloadly 窗口，点 `Start`。
5. 等待进度完成，日志出现安装成功提示。

建议提醒用户使用次要 Apple ID。该账号必须**曾经在任意苹果设备上登录过 iCloud**，全新注册、从未登录过的账号会被拒绝。界面上保存凭据的选项可以不勾选。

### 6.4 首次启动的两个必做动作

签名生效后首次点击应用图标，iOS 会拦截并提示「不受信任的开发者」。这不是失败，重签已经成功，只差设备侧信任。

**动作一，信任开发证书**：

```text
设置 → 通用 → VPN与设备管理 → 开发者应用 → 点 Apple ID 邮箱 → 信任
```

弹窗出现时再点一次信任。

**动作二，开启开发者模式**（iOS 16 及以上必须）：

```text
设置 → 隐私与安全性 → 开发者模式 → 打开 → 重启手机生效
```

顺序可以调换，两项都完成后应用才能启动。

若 VPN与设备管理页面为空、找不到开发者应用入口，说明签名环节未真正完成，应回到 Sideloadly 查看安装日志，而不是继续在手机上找。

---

## 7. 阶段四：验证运行

验证不能只看应用能打开，必须确认核心功能生效。对本参考实现，判据是**网络请求收到服务器响应**。

建议的验证方法：使用公开的回显服务，服务端会把请求内容原样返回，便于确认请求确实发出且被处理。

| 用途 | 地址 |
| --- | --- |
| POST 回显 | `https://httpbin.org/post` |
| POST 回显备用 | `https://postman-echo.com/post` |
| 纯连通性检测 | `https://captive.apple.com/hotspot-detect.html` |

验证通过的表现：界面显示 HTTP 200 状态码、往返耗时、以及服务器回显的 JSON 内容。回显内容与请求体一致，说明请求体正确送达。

本次实测结果：应用成功收到服务器响应，链路完整可用。

---

## 8. 问题排查

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 提示「不受信任的开发者」 | 设备未信任开发证书 | 设置 → 通用 → VPN与设备管理 → 信任 |
| 信任后仍打不开 | iOS 16+ 开发者模式未开启 | 设置 → 隐私与安全性 → 开发者模式 → 重启 |
| VPN与设备管理页面为空 | 签名环节未完成 | 查看 Sideloadly 安装日志 |
| Sideloadly 识别不到设备 | USB 驱动或信任关系问题 | 检查 Apple 移动设备服务、换数据线、重新信任 |
| Apple ID 被拒绝 | 免费账号从未登录过 iCloud | 换一个用过的账号 |
| 7 天后应用打不开 | 免费证书过期 | 把 IPA 重新拖入 Sideloadly 重签 |
| 应用装不上，提示架构不符 | 产物不是 arm64 | 检查 `ARCHS=arm64`、`ONLY_ACTIVE_ARCH=NO` |
| 应用内 HTTP 请求失败 | ATS 拦截明文流量 | Info.plist 增加 `NSAllowsArbitraryLoads` |
| 构建失败，提示签名错误 | 签名设置未完全关闭 | 命令行显式传 `CODE_SIGNING_ALLOWED=NO` 等参数 |
| Actions 无法触发 | token 缺少 workflow 权限 | `gh auth refresh -s workflow` |
| 注册表查不到 Sideloadly | 它是用户级安装 | 改用 `%LOCALAPPDATA%\Sideloadly` 或进程检查 |
| PowerShell 命令被策略拦截 | 命令中包含删除等破坏性操作 | 拆分为多条只读命令执行 |

---

## 9. 限制与备选方案

### 9.1 免费 Apple ID 的固有限制

来自 Apple 对免费账号的规则，无法绕过：

| 限制 | 具体表现 |
| --- | --- |
| 签名有效期 7 天 | 到期应用无法打开，需重新签名 |
| 同时最多 3 个自签应用 | 超出需先删除 |
| iOS 16+ 需开开发者模式 | 必须在设备上手动开启并重启 |

自动化重签可显著降低维护成本：Sideloadly 的 `sideloadlydaemon.exe` 常驻后台，会在证书临近过期时自动重签，前提是电脑开机且设备可用。

### 9.2 备选路径对比

| 方案 | 适用场景 | 代价 |
| --- | --- | --- |
| GitHub Actions + Sideloadly | **默认推荐**，公开仓库完全免费 | 云构建时长受配额限制 |
| AltServer | 需要可审计的开源工具 | 对最新 iOS 兼容性较差 |
| 付费开发者账号 | 需要长期签名、上架或分发 | 年费 99 美元，证书有效期 1 年 |
| TrollStore | 已越狱设备 | 仍需先在 macOS 上编译二进制，绕不过编译环节 |
| Flutter Web / PWA | 只需演示效果、不要求原生应用 | 非原生分发形式 |
| 租用云端 Mac | 需要在真实 macOS 上调试 | 按小时计费 |

---

## 10. 完整复现清单

按顺序执行即可复现整套能力。

### 10.1 Agent 执行部分

```powershell
# 1. 环境自检
gh auth status
Test-NetConnection 127.0.0.1 -Port 27015 -InformationLevel Quiet

# 2. 创建工程目录与文件（project.yml、Info.plist、Sources、workflow）
#    参照本手册第 4 章

# 3. 初始化仓库并提交
git init -b main
git add -A
git commit -m "初始提交"

# 4. 创建公开仓库并推送
gh repo create <用户名>/<仓库名> --public --source . --remote origin --push

# 5. 等待构建完成
gh run list --limit 5

# 6. 下载产物
gh run download <run-id> -n NetDemo-ipa -D .\dist

# 7. 校验产物（参照第 5.3 节脚本）

# 8. 安装 Sideloadly（需用户授权）
#    安装后确认进程：
Get-Process | Where-Object { $_.ProcessName -match 'Sideloadly' }
```

### 10.2 用户执行部分

1. 在 Sideloadly 中填入 Apple ID 与密码，拖入 IPA，点 Start。
2. 手机端：设置 → 通用 → VPN与设备管理 → 信任开发证书。
3. 手机端：设置 → 隐私与安全性 → 开发者模式 → 打开 → 重启。
4. 打开应用，验证核心功能（本参考实现为发送网络请求并收到响应）。

### 10.3 交付验收判据

| 判据 | 确认方式 |
| --- | --- |
| 云构建成功 | `gh run list` 显示 `completed success` |
| 产物架构正确 | `lipo -info` 输出含 `arm64` |
| 安装成功 | 手机桌面出现应用图标 |
| 应用可启动 | 点击图标能正常打开 |
| 核心功能可用 | 运行时能完成预期的网络收发并显示响应 |

---

## 附录：本项目实测数据备查

```text
仓库          https://github.com/Voynul/ios-netdemo
运行 ID       35178997121
运行结果      success（11 个步骤全部通过）
Runner        macos-15
Xcode         16.4 (16F6)
XcodeGen      2.46.0

产物          NetDemo.ipa
大小          49554 字节
SHA-256       193553c7b016843eebf57387c2b1e6e65135b4d009009b6cae6d5c6089df4fd5

包内结构
  Payload/
  Payload/NetDemo.app/
  Payload/NetDemo.app/Info.plist        1003 字节
  Payload/NetDemo.app/PkgInfo              8 字节
  Payload/NetDemo.app/NetDemo         231488 字节

二进制
  magic       0xfeedfacf
  cputype     16777228 (ARM64)
  filetype    2 (MH_EXECUTE)
  签名        无

Info.plist
  CFBundleIdentifier          com.voynul.netdemo
  MinimumOSVersion            15.0
  CFBundleSupportedPlatforms  ['iPhoneOS']
  UIDeviceFamily              [1]
  NSAllowsArbitraryLoads      True

Sideloadly
  版本        0.60.0
  安装包      131003599 字节
  SHA-256     625ad1e8240ee4765d0d181a33acab686b5b92f842e625c0f17e812a7893fdf4
  数字签名    无
  安装位置    %LOCALAPPDATA%\Sideloadly
```
