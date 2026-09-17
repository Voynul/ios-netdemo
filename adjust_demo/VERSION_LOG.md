# Adjust Signature iOS nativeVersion 版本台账

本文件用于维护 iOS `AdjustSignature` 的版本处理进度、后续排期，以及
`nativeVersion` 与 Adjust iOS SDK 版本之间的官方依赖关系。

最后核对日期：2026-09-17。

## 1. 维护口径

| 名称 | 含义 |
| --- | --- |
| `nativeVersion` | `AdjustSignature` / `AdjustSigSdk` 的版本号，最终写入 Authorization 的 `native_version` |
| `clientSdk` | 请求头和签名入参中的 Adjust iOS SDK 版本串，例如 `ios5.0.1` |
| 已完成 | 已取得真实 iOS 样本，算法复现、对拍、发包验证和归档均已完成 |
| 进行中 | 已进入 Demo 构建或真机取样阶段，尚未满足已完成条件 |
| 待处理 | 已进入处理范围，但尚未开始 |
| 暂缓 | 官方版本存在，当前排期不处理 |

Demo 构建成功、IPA 安装成功和三连请求抓包是独立检查项。只有完成归档后，
该 `nativeVersion` 才计入已完成。

归档状态仍需同步到工作区根目录 `签名版本处理清单.md`。该清单只在收到明确归档命令后修改。

## 2. 总体进度

官方 `adjust/adjust_signature_sdk` 当前公开 31 个 Release，包含正式版和带 beta 后缀的版本。

| 状态 | 数量 | 说明 |
| --- | ---: | --- |
| 已完成 | 6 | 已有真实 iOS 样本并完成归档 |
| 进行中 | 2 | `3.32.0`、`3.20.1` |
| 待处理 | 12 | 进入后续排期 |
| 暂缓 | 11 | `3.0.0` 至 `3.13.1` |
| 合计 | 31 | 与官方 Release 数量一致 |

## 3. 当前 Demo 配置

| 项目 | 当前值 | 状态 |
| --- | --- | --- |
| nativeVersion | `3.32.0` | 当前 Demo |
| clientSdk | `ios5.0.1` | 与 iOS SDK 5.0.1 的 `~> 3.18` 依赖范围相容 |
| app_token | `aa0f4lr105j4` | 可公开的测试值 |
| environment | `production` | 已配置 |
| host | `app.adjust.com` | 已配置 |
| GitHub Actions run | 待生成 | 3.32.0 尚未构建 |
| 提交 | 待生成 | 3.32.0 修改尚未推送 |
| 真机双次运行 | 待执行 | 3.32.0 构建安装后执行 |
| 三连请求样本 | 待执行 | `/session`、`/sdk_click`、`/attribution` |

## 4. Adjust iOS SDK 与 nativeVersion 的官方关系

### 4.1 iOS SDK 5.x 的固定依赖

以下关系来自 `adjust/ios_sdk` 各 tag 的 `Adjust.podspec`，并由官方 `CHANGELOG.md`
中的 Signature library 更新记录交叉核对。

| Adjust iOS SDK | `AdjustSignature` 依赖 | 关系类型 |
| --- | --- | --- |
| `5.0.0` - `5.0.1` | `~> 3.18` | 范围依赖，实际解析版本受锁文件和解析时间影响 |
| `5.0.2` - `5.4.0` | `3.35.2` | 固定版本 |
| `5.4.1` - `5.4.5` | `3.47.0` | 固定版本 |
| `5.4.6` | `3.61.0` | 固定版本 |
| `5.5.0` - `5.6.1` | `3.62.0` | 固定版本 |
| `5.6.2` - `5.7.0` | `3.67.0` | 固定版本 |
| `5.8.0` | `5.0.0` | 固定版本 |

截至 2026-09-17，官方 iOS SDK 最新 tag 为 `5.8.0`，其固定依赖为
`AdjustSignature 5.0.0`。签名库 `5.5.0` 发布时间晚于 iOS SDK `5.8.0`，
当前公开的 iOS SDK tag 中尚未出现对 `5.5.0` 的固定依赖。

### 4.2 iOS SDK 4.x 的关系边界

- iOS SDK 从 `4.21.0` 开始支持 Signature library 插件。
- 官方集成文档要求 Adjust iOS SDK `4.35.2` 或更高版本。
- 官方文档给出的 Signature library 支持范围为 `3.0.0` 至 `3.67.0`。
- iOS SDK 4.x 的 podspec 没有逐版本固定 `AdjustSignature`，无法据此建立一对一关系。
- 需要使用 4.x 的旧签名库时，Demo 默认从 `ios4.38.4` 开始验证，并以真实请求结果确认。

### 4.3 关系使用规则

1. 固定依赖优先使用表中对应的 `clientSdk`。
2. `~> 3.18` 只证明版本范围相容，不能证明某个 App 当时实际解析到哪个签名库版本。
3. beta 版本没有官方固定配对时，只能选择同系列稳定版对应的 SDK 作为测试候选。
4. `clientSdk` 与 `nativeVersion` 分别记录，不把两者合并成单一版本号。

## 5. 已完成 nativeVersion

| nativeVersion | 对应 Adjust iOS SDK 关系 | 状态 | 归档记录 |
| --- | --- | --- | --- |
| `5.0.0` | iOS SDK `5.8.0` 固定依赖 | 已完成 | iOS 样本已验证 |
| `3.67.0` | iOS SDK `5.6.2` - `5.7.0` 固定依赖 | 已完成 | `native-3.67.0-20260910-102529` |
| `3.61.0` | iOS SDK `5.4.6` 固定依赖 | 已完成 | `native-3.61.0-20260911-153154` |
| `3.47.0` | iOS SDK `5.4.1` - `5.4.5` 固定依赖 | 已完成 | `native-3.47.0-20260910-151515` |
| `3.35.2` | iOS SDK `5.0.2` - `5.4.0` 固定依赖 | 已完成 | `native-3.35.2-20260910-183416` |
| `3.20.2` | iOS SDK `5.0.0` - `5.0.1` 的 `~> 3.18` 范围 | 已完成 | `native-3.20.2-20260914-151006` |

## 6. 进行中与待处理排期

执行顺序以当前任务优先，其余版本按现有版本计划从新到旧推进。

| 顺序 | nativeVersion | 类型 | 建议 clientSdk | 关系依据 | 状态 |
| ---: | --- | --- | --- | --- | --- |
| 1 | `3.32.0` | 正式版 | `ios5.0.1` | `~> 3.18` 范围 | 进行中：当前 Demo，待构建与真机验证 |
| 2 | `3.20.1` | 正式版 | `ios5.0.1` | `~> 3.18` 范围 | 进行中：修复版已构建，待真机双次运行与抓包 |
| 3 | `3.67.0-beta` | beta | `ios5.6.2` | 同系列稳定版由 iOS SDK 5.6.2 固定依赖 | 待处理，需单独验证 |
| 4 | `3.62.0` | 正式版 | `ios5.5.0` | iOS SDK 5.5.0 首次固定依赖 | 待处理 |
| 5 | `3.47.0-beta` | beta | `ios5.4.1` | 同系列稳定版由 iOS SDK 5.4.1 固定依赖 | 待处理，需单独验证 |
| 6 | `3.35.1` | 正式版 | `ios5.0.1` | `~> 3.18` 范围 | 待处理 |
| 7 | `3.35.0` | 正式版 | `ios5.0.1` | `~> 3.18` 范围 | 待处理 |
| 8 | `3.24.1-beta` | beta | `ios5.0.1` | 5.0.1 作为测试候选，需单独验证 | 待处理 |
| 9 | `3.24.0-beta` | beta | `ios5.0.1` | 5.0.1 作为测试候选，需单独验证 | 待处理 |
| 10 | `3.20.0` | 正式版 | `ios5.0.1` | `~> 3.18` 范围 | 待处理 |
| 11 | `3.18.0` | 正式版 | `ios5.0.1` | `~> 3.18` 范围下限 | 待处理 |
| 12 | `3.14.1` | 正式版 | `ios4.38.4` | iOS SDK 4.x 插件路径，待真实请求确认 | 待处理 |
| 13 | `3.14.0` | 正式版 | `ios4.38.4` | iOS SDK 4.x 插件路径，待真实请求确认 | 待处理 |
| 14 | `5.5.0` | 正式版 | 待定 | 当前没有 iOS SDK tag 固定依赖该版本 | 待处理，排期最后 |

## 7. 暂缓版本

以下 11 个版本当前不进入处理排期。需要支持时，再恢复到待处理列表并确定对应的
`clientSdk` 候选。

| nativeVersion | 当前状态 |
| --- | --- |
| `3.13.1`、`3.13.0`、`3.12.0`、`3.10.0` | 暂缓 |
| `3.7.0`、`3.6.0`、`3.5.2`、`3.5.1`、`3.5.0` | 暂缓 |
| `3.3.0`、`3.0.0` | 暂缓 |

## 8. 单版本验证记录

每个版本完成后追加一节，保留可验证信息，不在本文件记录算法常量或复现细节。

```text
### YYYY-MM-DD - nativeVersion X / clientSdk Y

- 官方关系：固定依赖、范围依赖或测试候选。
- 配置：nativeVersion、clientSdk、environment、host。
- 构建：提交、Actions run id、构建结果和产物路径。
- 签名库：getVersion() 返回值。
- 设备：机型、iOS 版本、签名方式。
- 第一次运行：/session、/sdk_click、/attribution 的状态与样本路径。
- 卸载重装。
- 第二次运行：/session、/sdk_click、/attribution 的状态与样本路径。
- 结论：通过、阻塞或需要补证。
```

## 9. 更新流程

1. 从本文件排期表选择目标 `nativeVersion`。
2. 按第 4 节确定 `clientSdk`；无固定关系时明确标记为测试候选。
3. 修改 `Config/demo-config.json`，推送后由 GitHub Actions 构建 IPA。
4. 使用 Sideloadly 重签安装，按 `AGENTS.md` 执行两次安装运行。
5. 冻结两轮三连请求样本，在本文件追加验证记录。
6. 完成算法复现、对拍、发包验证和归档后，将该版本移入已完成表并重算数量。
7. 只有收到明确归档命令后，才同步根目录 `签名版本处理清单.md`。

## 10. 官方来源

- Adjust Signature SDK Releases：<https://github.com/adjust/adjust_signature_sdk/releases>
- Adjust iOS SDK Releases：<https://github.com/adjust/ios_sdk/releases>
- Adjust iOS SDK CHANGELOG：<https://github.com/adjust/ios_sdk/blob/master/CHANGELOG.md>
- Adjust iOS SDK tags 中的 `Adjust.podspec`：<https://github.com/adjust/ios_sdk/tags>
- Adjust iOS Signature library integration：<https://dev.adjust.com/en/sdk/ios/features/signature-library/>
