import Foundation
import UIKit

/// 设备与时间字段。签名器会把白名单里存在的键按固定顺序拼接，因此这些值必须真实可追溯。
enum DeviceInfo {

    /// Adjust 使用的本地时间格式：2026-09-17T14:30:00.000+0800
    static func timestamp(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// 硬件标识，如 iPhone10,3。对应 Adjust 的 device_type。
    static func hardwareModel() -> String {
        var info = utsname()
        uname(&info)
        let mirror = Mirror(reflecting: info.machine)
        let model = mirror.children.reduce(into: "") { acc, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            acc.append(Character(UnicodeScalar(UInt8(value))))
        }
        return model.isEmpty ? "unknown" : model
    }

    static var idfv: String {
        UIDevice.current.identifierForVendor?.uuidString ?? ""
    }

    static var osVersion: String {
        UIDevice.current.systemVersion
    }

    static var deviceName: String {
        UIDevice.current.name
    }
}

/// 跨启动保留的少量状态：首次安装时间与会话计数。
enum DemoState {

    private static let installedAtKey = "demo.installed_at"
    private static let sessionCountKey = "demo.session_count"

    /// 首次启动时间，仅写入一次。
    static var installedAt: String {
        if let existing = UserDefaults.standard.string(forKey: installedAtKey) {
            return existing
        }
        let now = DeviceInfo.timestamp()
        UserDefaults.standard.set(now, forKey: installedAtKey)
        return now
    }

    /// 每次启动递增，首次为 1。
    static func nextSessionCount() -> Int {
        let next = UserDefaults.standard.integer(forKey: sessionCountKey) + 1
        UserDefaults.standard.set(next, forKey: sessionCountKey)
        return next
    }
}

