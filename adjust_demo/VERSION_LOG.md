# AdjustDemo 版本记录（iOS）

本文件记录 `E:\work\IOS_adjust\adjust_demo` 工程跑过的 Signature Library 版本，
以及每次实际构建、安装、发包的实测信息。每次切换版本或完成一轮验证后追加一条。

本 Demo 的用途是**产出真实 iOS Adjust HTTP 样本**，供
`../adjust_test/adjust-signature` 对拍。它不替代算法复现工程。

## 本文档与 Android 版的关系

本文件由 `E:\work\adjust_new\adjust_demo\VERSION_LOG.md`（Android）的**骨架**改写而来。
两侧是独立文档，互不同步。

**Android 的数值不是 iOS 真值。** 官方 iOS 与 Android 的同号签名库在依赖声明上
并不一致，实测至少有 5 处冲突（见「iOS 官方 SDK 与 Signature 库配对」）。因此：

- 本文件只登记 **iOS 侧实测**结果；
- Android 文档里的 `adj_signing_id` / `headers_id` 等只能作排期候选，
  必须由本 Demo 抓到的真实 iOS Authorization 覆盖；
- 不得把 Android 的字段表、证书槽、白名单、XOR、常量抄进 iOS 算法或本记录。

依据：本工作区根 `AGENTS.md` §3.1 与 `../签名版本处理清单.md` 的「`adj` 对应口径」。

## 当前工程版本

| 项目 | 值 | 说明 |
| --- | --- | --- |
| nativeVersion | `3.20.1` | `Config/demo-config.json` |
| clientSdk | `ios5.0.1` | 候选值，待抓包核对（依据见下文配对表） |
| app_token | 占位值 + Secret 注入 | 仓库存 `REPLACE_WITH_ADJUST_APP_TOKEN`；真实值在 Secret `ADJUST_APP_TOKEN`，构建时注入 |
| environment | `sandbox` | |
| host | `app.adjust.com` | |
| 签名库 | `AdjustSigSdk.xcframework` | CI 按 nativeVersion 从官方 releases 下载 |
| 工程生成 | XcodeGen | `project.yml` |
| 构建 | GitHub Actions `macos-15` | 本机 Windows 不编译 |
| 安装 | Sideloadly 重签 | 产物为未签名 IPA |
| 宿主仓库 | `Voynul/ios-netdemo` | 本 Demo 位于其 `adjust_demo/` 子目录 |

版本号统一配置在 `Config/demo-config.json`，CI 与 App 读同一份文件。

## 版本创建状态与排期

**本 Demo 的「已跑通」与根目录 `../签名版本处理清单.md` 的「已处理」是两个口径，
不要互相套用：**

| 口径 | 含义 | 维护位置 |
| --- | --- | --- |
| Demo 已跑通 | 该 nativeVersion 已成功构建、装机、发出三连请求、抓包落样本 | 本文件 |
| 算法已处理 | 该 nativeVersion 的算法已复现、对拍、发包验证并通过归档 | `../签名版本处理清单.md` |

Demo 跑通是算法处理的前置条件，因此 Demo 进度通常领先。**跑通 Demo 不代表算法完成，
不得据此改动处理清单**——那只在用户明确归档命令后执行。

完整版本排期（31 个版本，含 beta）见 `../签名版本处理清单.md`。

## 已跑通的组合

| 序号 | nativeVersion | clientSdk | 构建 | 三连请求 | 抓包落样本 | 备注 |
| --- | --- | --- | --- | --- | --- | --- |
| — | 3.20.1 | ios5.0.1 | 待执行 | 待执行 | 待执行 | 首次创建，服务于 3.20.1 复现任务的样本闸门 |

## 已生成 / 已验证记录

### 记录模板

```text
### YYYY-MM-DD（nativeVersion X / clientSdk Y）

- 配置：nativeVersion、clientSdk、app_token、environment、host。
- 构建：run id、结果、IPA 大小与 SHA-256、内嵌 framework 版本。
- 签名库：getVersion() 实际返回值，与配置是否一致。
- 设备：机型 / iOS 版本 / 越狱状态。
- 双次运行（按 AGENTS.md 规则顺序）：
  - 第一次启动：全新安装后启动，记录时间与三连请求结果。
  - 卸载（iOS 无单独清数据命令）。
  - 第二次启动：重装后启动，记录时间与结果。
- Authorization 实测：`native_version` / `algorithm` / `adj_signing_id` /
  `headers_id` 实际值，与候选值是否一致。
- 样本：落盘到 `../samples/` 的路径。
- 遗留：未闭合项。
```

## iOS 官方 SDK 与 Signature 库配对

### 官方文档给了什么

Adjust 官方**没有发布逐版本的配对表**。公开文档只给下限与范围：

| 来源 | 约束 |
| --- | --- |
| iOS v4 集成页 | Adjust SDK ≥ `4.35.2`；Signature 版本在 `3.0.0` – `3.67.0` 之间（含） |
| iOS v5 集成页 | Adjust SDK ≥ `5.0.0`；签名库随 SDK v5 更新自动升级 |
| Help Center | SDK v5 默认已内置签名库，多数情况无需单独集成 |

### 逐版本配对的两个权威来源

配对关系需从以下两处推导，二者互相印证：

1. `adjust/ios_sdk` 的 `CHANGELOG.md`——升级时会写明
   `Updated the Adjust Signature library version to X`；
2. `adjust/ios_sdk` 各 tag 的 `Adjust.podspec` / `Package.swift` 依赖声明。

取值日期 2026-09-17。

| iOS SDK | AdjustSignature | 来源 |
| --- | --- | --- |
| 4.21.0 | （开始支持签名库作为插件） | CHANGELOG |
| 4.35.2 | （官方文档规定的最低 SDK 版本） | docs |
| 5.0.0 / 5.0.1 | `~> 3.18`（范围，非固定） | podspec |
| 5.0.2 | `3.35.2`（pinned） | CHANGELOG + podspec |
| 5.1.0 – 5.4.0 | `3.35.2` | podspec |
| 5.4.1 – 5.4.5 | `3.47.0` | CHANGELOG + podspec |
| 5.4.6 | `3.61.0` | CHANGELOG + podspec |
| 5.5.0 – 5.6.1 | `3.62.0` | CHANGELOG + podspec |
| 5.6.2 – 5.7.x | `3.67.0` | CHANGELOG + podspec |
| 5.8.0 | `5.0.0` | CHANGELOG + podspec |

### client_sdk 与 native_version 不是一回事

这两个字段容易混淆，含义不同：

| 字段 | 含义 | 例 |
| --- | --- | --- |
| `client_sdk` | Adjust **SDK** 版本串 | `ios5.0.1` |
| `native_version` | **签名库**版本 | `3.20.1` |

因此配对是**多对多**，不存在一对一映射：

- 一个 SDK 版本可能对应多个签名库版本——5.0.0 / 5.0.1 只声明范围 `~> 3.18`；
- 一个签名库版本可能被多个 SDK 版本使用——3.62.0 覆盖 5.5.0 至 5.6.1。

签名入口 `+[ADJSigner sign:withActivityKind:withSdkVersion:]` 把 `client_sdk` 当**入参**
接收，不校验它与自身版本的关系（本工作区 unidbg Probe 实测传入
`ios4.38.0` 时签名器照常产出签名）。所以本 Demo 的 `clientSdk` 只要是一个合理的
Adjust iOS SDK 版本串、且与 `Client-SDK` 头保持一致即可。

### 对 3.20.1 的结论

`nativeVersion=3.20.1` 落在 SDK 5.0.0 / 5.0.1 的 `~> 3.18` 范围内，因此
`clientSdk` 取 `ios5.0.0` 或 `ios5.0.1` 都自洽。本工程取 `ios5.0.1`，
理由是同代际相邻版本 3.20.2 的实测抓包为 `ios5.0.1`。

### 官方提醒

Help Center 指出：若要把签名库**降级到该 App 从未使用过的版本**，应先联系
Adjust 代表或 support@adjust.com。本 Demo 属本地测试、不涉及线上 App，不受此限；
但后续若要在正式 App 上做版本回退，需先走这条流程。

### 与 Android 文档的冲突点

Android 文档声明的配对与 iOS podspec / CHANGELOG 实测不一致的有 5 处：

| iOS SDK | iOS podspec | Android 文档 | 结论 |
| --- | --- | --- | --- |
| 5.0.0 | `~> 3.18` | `[3,)` | 冲突 |
| 5.0.1 | `~> 3.18` | `[3.20.0, 4.0.0)` | 冲突 |
| 5.0.2 | `3.35.2` | `3.35.0` | 冲突 |
| 5.4.5 | `3.47.0` | `3.61.0` | 冲突 |
| 5.6.1 | `3.62.0` | `3.67.0` | 冲突 |
| 5.4.1 / 5.7.0 / 5.8.0 | 一致 | 一致 | 无冲突 |

### 4.x 区间的说明

iOS SDK 4.x 从 `4.21.0` 起支持签名库作为插件，官方文档规定实际可用的下限是
`4.35.2`。该区间的 podspec 不含 signature 的 subspec 或 dependency 声明，
因此**无法从 podspec 推出逐版本配对**，只能确认可用范围。后续若测
3.14.x – 3.20.0 这批签名库，配对需另找证据（可从 App 实际抓包反推）。

另一个易混点：Android 文档里用的 `4.38.5` 在 iOS 侧**不存在**，
iOS SDK 4.x 止于 `v4.38.4`。后续测这批签名库时，`clientSdk` 不能照抄
Android 文档的 `ios4.38.5`。

## 候选 metadata 参考（来源 Android，仅供排期，非 iOS 真值）

下表来自 Android 全量实测。**它的 `adj_signing_id` / `headers_id` 是 Android 数值，
iOS 同号版本可能不同，必须以本 Demo 抓包覆盖。** 仅用于排期与预期对照。

| native_version | 候选 algorithm | 候选 adj_signing_id | 候选 headers_id | iOS 侧状态 |
| --- | --- | --- | --- | --- |
| 3.14.0 / 3.14.1 | adj5 | 1100000 | 5 | 待实测 |
| 3.18.0 / 3.20.0 / 3.20.1 | adj5 | 1100000 | 5 | 3.20.1 已由本工作区 IDA 确认 algorithm/secret_id/headers_id |
| 3.20.2 / 3.35.2 | adj5 | 1100000 / 1100001 | 5 | algorithm 已由 iOS 样本确认，其余见归档文档 |
| 3.32.0 / 3.35.0 / 3.35.1 | adj5 | 1100001 | 5 | 待实测 |
| 3.47.0 | adj6 | 1200000 | 5 | algorithm 已由 iOS 样本确认 |
| 3.61.0 | adj7 | 1300000 | 7 | algorithm 已由 iOS 样本确认 |
| 3.62.0 | adj7 | 1300000 | 8 | 待实测 |
| 3.67.0 | adj8 | 1400000 | 9 | algorithm 已由 iOS 样本确认 |
| 5.0.0 | adj9 | 1500000 | 10 | algorithm 已由本工作区冻结 iOS HTTP 确认 |
| 5.5.0 | adj9（用户确认） | 待实测 | 待实测 | 待实测 |
| 3.24.0 / 3.24.1 / 3.47.0 / 3.67.0 的 beta | 按同系列归组 | 待实测 | 待实测 | 待实测 |

adj4 系列（3.0.0 起共 11 个）本工作区目前不处理，未列入。

`native_version` 字段恒为该行自身的版本号，用于 Authorization 与签名器写回，
不随候选值变化。

## 新增一条记录的方法

1. 改 `Config/demo-config.json` 的 `nativeVersion`；按配对表核对 `clientSdk` 是否需要同改。
2. 推送到 `main` 触发构建，或
   `gh workflow run build-adjust-demo-ipa --repo Voynul/ios-netdemo`。

```powershell
gh run list --limit 5
gh run download <run-id> -n AdjustDemo-ipa -D .\dist
```

3. 用 Sideloadly 重签 IPA 并装到设备。
4. 按 AGENTS.md 的双次运行规则跑两轮，用 Reqable 抓三条请求。
5. 把 Authorization 实测值、请求结果与样本路径追加到本文件「已生成 / 已验证记录」，
   并把对应行从「已跑通」表的占位行替换为实测行。

## 注意事项

- **服务端返回非 2xx 属预期**。app_token 是占位值时会返回
  「app token 无效」类错误；出站请求和签名完整，可用于对拍。
  但复现工程的 **5.2 发包闸门要求 HTTP 2xx**，那道闸门需要真实 token。
- **签名真值以网络层证据为准**。App 内日志只作辅助；Authorization 的最终真值
  是 Reqable 冻结的那条请求。
- **iOS 无法单独清空 App 数据**。Android 的 `pm clear` 在 iOS 没有对应命令；
  等效做法是卸载重装。注意 iOS Keychain 在卸载后可能保留，本 Demo 的状态
  （installed_at / session_count）存在 UserDefaults，卸载即清。
- **免费 Apple ID 签名 7 天过期**，过期后应用打不开，重新用 Sideloadly 签一次即可。
  iOS 16 及以上需在设备上手动开启开发者模式，并在
  设置 → 通用 → VPN与设备管理 中信任开发证书。
- **换 nativeVersion 时一并核对 clientSdk**。两者不匹配会产出与目标版本不符的样本。
- **本 Demo 自己组字段发包，不经过 Adjust 官方 iOS SDK**，字段集是「够用且可追溯」，
  不等同于某个真实 App 的完整字段集。样本用于算法对拍，不用于复刻某个 App 的流量。
- **内嵌 AdjustSigSdk 是 Dynamic framework**，Sideloadly 重签时会一并处理；
  若换用 Static `.a` 形态，链接方式与 `project.yml` 需要同步调整。
- 不提交真实 App token、密钥、代理账号或其它敏感配置。
