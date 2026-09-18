import AdjustSdk
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let config = DemoConfig.load()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let startupResult = initializeAdjust()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(
            rootViewController: DemoViewController(config: config, startupResult: startupResult)
        )
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    private func initializeAdjust() -> String {
        guard config.environment == "production" else {
            return "初始化失败：environment 必须为 production"
        }
        guard let adjustConfig = ADJConfig(
            appToken: config.appToken,
            environment: ADJEnvironmentProduction
        ) else {
            return "初始化失败：Adjust SDK 拒绝当前配置"
        }

        Adjust.initSdk(adjustConfig)

        guard let url = URL(string: config.startupDeeplink),
              let deeplink = ADJDeeplink(deeplink: url)
        else {
            return "SDK 已初始化，但启动 deep link 无效"
        }
        Adjust.processDeeplink(deeplink)
        return "SDK 已初始化，并已提交启动 deep link；请求内容和地址由 SDK 决定"
    }
}
