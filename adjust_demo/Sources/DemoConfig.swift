import Foundation

/// 运行期配置。来源为打进 App 包的 `demo-config.json`，与 CI 读取的是同一份文件。
struct DemoConfig {

    let nativeVersion: String
    let adjustSdkVersion: String
    let appToken: String
    let environment: String
    let appName: String
    let bundleId: String
    let startupDeeplink: String

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
            adjustSdkVersion: str("adjustSdkVersion", "0.0.0"),
            appToken: str("appToken", "000000000000"),
            environment: str("environment", "production"),
            appName: str("appName", "AdjustDemo"),
            bundleId: str("bundleId", "com.example.adjustsigndemo"),
            startupDeeplink: str("startupDeeplink", "adjustdemo://startup")
        )
    }
}
