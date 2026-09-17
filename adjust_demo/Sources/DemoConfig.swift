import Foundation

/// 运行期配置。来源为打进 App 包的 `demo-config.json`，与 CI 读取的是同一份文件。
struct DemoConfig {

    let nativeVersion: String
    let clientSdk: String
    let appToken: String
    let environment: String
    let host: String
    let scheme: String
    let appName: String
    let bundleId: String
    let autoSend: Bool
    let intervalSeconds: Double

    static func load() -> DemoConfig {
        guard let url = Bundle.main.url(forResource: "demo-config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            fatalError("demo-config.json 未打进 App 包，检查 project.yml 的 Config 资源声明")
        }

        func str(_ key: String, _ fallback: String) -> String {
            (obj[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? fallback
        }

        return DemoConfig(
            nativeVersion: str("nativeVersion", "unknown"),
            clientSdk: str("clientSdk", "ios0.0.0"),
            appToken: str("appToken", "000000000000"),
            environment: str("environment", "sandbox"),
            host: str("host", "app.adjust.com"),
            scheme: str("scheme", "https"),
            appName: str("appName", "AdjustDemo"),
            bundleId: str("bundleId", "com.example.adjustsigndemo"),
            autoSend: (obj["autoSend"] as? Bool) ?? true,
            intervalSeconds: (obj["intervalSeconds"] as? Double) ?? 1.5
        )
    }

    var baseUrl: String {
        "\(scheme)://\(host)"
    }
}

