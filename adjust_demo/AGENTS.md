# adjust_demo/ — 自建 iOS 发包 Demo

本目录的固定路径是 `E:\work\IOS_adjust\ios-netdemo\adjust_demo`，用于产出**真实 iOS Adjust HTTP 样本**。
这是唯一 Demo 维护目录，不得再创建 `E:\work\IOS_adjust\adjust_demo` 同步副本。
进入或修改前先读工作区根 `E:\work\IOS_adjust\AGENTS.md`。

## 职责

允许：组 Adjust 请求字段、调用 `AdjustSigSdk` 现签、向 Adjust 接口发包、展示与记录结果。

不负责：算法复现、逐字节对拍、正式插件接入。那些在
`..\..\adjust_test\adjust-signature`（`ios` 分支）和 `..\..\protocol-client`。

## 不可违反

- 本 Demo 的签名值来自**真实签名库**，不得把 `adjust_test` 的复现实现搬进来当签名源；
- 不得把本 Demo 抓到的样本当成「算法已复现」的证据。样本是对拍输入，不是结论；
- 字段集以本工作区证据为准（`..\..\analysis\unidbg\3201-sign-probe.md`、
  `..\..\analysis\ida\3201-whitelist-keys.txt`），不照抄 Android 工作区的字段表；
- 换 `nativeVersion` 时一并核对 `clientSdk`。两者不匹配会产出与目标版本不符的样本；
- 样本落 `..\..\samples`，过程材料落 `..\..\analysis`，不在本目录堆积证据文件；
- 首次用某个 `nativeVersion` 跑通后，在 `VERSION_LOG.md` 追加一条记录。

## 构建通道

本机是 Windows，编译交给 GitHub Actions 的 macOS runner，产出未签名 IPA，
用 Sideloadly 加 Apple ID 重签装机。

签名库由 CI 按 `Config/demo-config.json` 的 `nativeVersion` 从官方 releases 下载，
不在仓库内保存二进制。

后续构建只记录提交、GitHub Actions run、构建结果和产物路径，不计算或记录 IPA SHA-256。

**宿主仓库：** `https://github.com/Voynul/ios-netdemo`

本 Demo 以子目录 `adjust_demo/` 的形式托管在该仓库中，与同仓库的 NetDemo 并列。

**工作流部署位置：** `.github/workflows/build-adjust-demo.yml` 必须放在**仓库根**。
GitHub Actions 只读取仓库根的 `.github/workflows/`，不读取子目录里的同名文件。
因此该文件里的路径一律带 `adjust_demo/` 前缀，并用 `defaults.run.working-directory`
切换工作目录。本 Demo 若将来拆成独立仓库，需去掉前缀。

### app_token 处理

用户已确认 `aa0f4lr105j4` 只是可公开的测试 token，允许提交到公开仓库。

- `Config/demo-config.json` 固定保存该测试 token；
- 构建流程直接使用仓库配置，不再通过 GitHub Secret 覆盖；
- 若以后更换为真实或敏感 token，必须先恢复占位值与 Secret 注入方式。

## Demo 创建后的双次运行（必做）

与 Android 侧同名规则对应，但工具链不同。每次创建或切换完一个版本的 Demo 后，
按以下顺序运行 **2 次**，取得两组请求样本：

1. **第一次启动**：全新安装后直接启动 App，记录第 1 组请求。
2. **停止应用**：设备上上滑关闭，或用 `user-ios-mcp` 终止进程。
3. **清空数据**：iOS 没有 `pm clear` 的对等命令。等效做法是**卸载后重装**
   （本 Demo 状态存在 UserDefaults，卸载即清；Keychain 可能保留）。
4. **第二次启动**：重装后再次启动，记录第 2 组请求。
5. **存在记录验证**：两轮都要在 Reqable 中确认三条请求都发出
   （`/session`、`/sdk_click`、`/attribution`）。本 Demo 的签名与请求详情在
   **应用内日志面板**可见，但那只是辅助；Authorization 的最终真值以 Reqable
   冻结的那条请求为准。
6. 两轮的时间、设备、版本与 Authorization 实测值写入 `VERSION_LOG.md`。

该动作是 Demo 创建流程的固定步骤，无需用户再次提醒。

## 与签名版本排期清单的关系

工作区根目录 `..\..\签名版本处理清单.md` 只记「该 nativeVersion 的算法是否已归档」。
本 Demo 跑通**不代表**该版本处理完成，不得据此改那张表。改动时机见该清单的
「归档后同步」一节。
