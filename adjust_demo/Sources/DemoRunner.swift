import Foundation

/// 按 session → sdk_click → attribution 顺序发包。
///
/// 顺序与根目录 `AGENTS.md` 5.2 一致。三个 path 都发，不跳过 session，也不只发 click。
final class DemoRunner {

    private let config: DemoConfig
    private let bundleId: String
    private let appVersion: String
    private let sessionCount: Int
    private let onLog: (String) -> Void
    private let onFinish: () -> Void

    private let sequence: [(kind: String, path: String)] = [
        ("session", "/session"),
        ("click", "/sdk_click"),
        ("attribution", "/attribution")
    ]

    init(config: DemoConfig,
         bundleId: String,
         appVersion: String,
         sessionCount: Int,
         onLog: @escaping (String) -> Void,
         onFinish: @escaping () -> Void) {
        self.config = config
        self.bundleId = bundleId
        self.appVersion = appVersion
        self.sessionCount = sessionCount
        self.onLog = onLog
        self.onFinish = onFinish
    }

    func run() {
        onLog("=== AdjustDemo 发包开始 ===")
        onLog("签名库 getVersion() = \(ADJSigner.getVersion())")
        onLog("nativeVersion(配置) = \(config.nativeVersion)")
        onLog("client_sdk = \(config.clientSdk)")
        onLog("app_token = \(config.appToken)")
        onLog("environment = \(config.environment)")
        onLog("bundle_id = \(bundleId)")
        onLog("host = \(config.baseUrl)")
        onLog("")
        runStep(at: 0)
    }

    private func runStep(at index: Int) {
        guard index < sequence.count else {
            onLog("=== 三个请求已全部发出 ===")
            onFinish()
            return
        }

        let step = sequence[index]
        let fields = FieldsBuilder.make(activityKind: step.kind,
                                        config: config,
                                        bundleId: bundleId,
                                        appVersion: appVersion,
                                        sessionCount: sessionCount)

        let signed: SignedPackage
        do {
            signed = try Signer.sign(fields: fields,
                                     activityKind: step.kind,
                                     clientSdk: config.clientSdk)
        } catch {
            onLog("[\(step.kind)] 签名失败：\(error)")
            advance(from: index)
            return
        }

        onLog("--- \(step.kind) → \(step.path) ---")
        onLog("输入键数 \(signed.inputKeyCount)，signature 长度 \(signed.writeBack["signature"]?.count ?? 0)")
        onLog("Authorization:")
        onLog(signed.authorization)

        AdjustSender.send(label: step.kind,
                          path: step.path,
                          fields: fields,
                          authorization: signed.authorization,
                          clientSdk: config.clientSdk,
                          config: config) { [weak self] outcome in
            guard let self else { return }
            if let transportError = outcome.transportError {
                self.onLog("传输失败：\(transportError)（\(outcome.elapsedMs) ms）")
            } else {
                self.onLog("HTTP \(outcome.status)  \(outcome.elapsedMs) ms  body \(outcome.bodyFields.count) 字段")
                if !outcome.responseBody.isEmpty {
                    self.onLog("响应：\(Self.clip(outcome.responseBody))")
                }
            }
            self.onLog("")
            self.advance(from: index)
        }
    }

    private func advance(from index: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + config.intervalSeconds) { [weak self] in
            self?.runStep(at: index + 1)
        }
    }

    private static func clip(_ text: String, limit: Int = 600) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit)) + " …(截断)"
    }
}

