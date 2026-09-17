import Foundation

/// 有序字段集合。签名器按自己的白名单顺序取值，但 HTTP body 需要稳定顺序，
/// 否则同一份输入两次运行会产出不同 body，不利于冻结样本。
struct OrderedFields {

    private(set) var items: [(key: String, value: String)] = []

    mutating func set(_ key: String, _ value: String) {
        items.append((key: key, value: value))
    }

    var dictionary: [String: String] {
        var result: [String: String] = [:]
        for item in items {
            result[item.key] = item.value
        }
        return result
    }
}

enum FieldsBuilder {

    /// 只参与签名、不进入 HTTP body 的字段。
    static let signatureOnlyKeys: Set<String> = ["activity_kind", "client_sdk"]

    /// 签名器写回的键，不得进入 body。
    static let signedBackKeys: Set<String> = [
        "signature", "adj_signing_id", "algorithm", "headers_id", "native_version"
    ]

    /// 构造本次 activity 的输入字段。
    ///
    /// 字段集依据本工作区 `analysis/unidbg/3201-sign-probe.md` 的 16 键 Probe 输入，
    /// 以及 `analysis/ida/3201-whitelist-keys.txt` 的 85 键白名单。
    /// `secret_id` 不放入输入，由签名器注入缺省值。
    static func make(activityKind: String,
                     config: DemoConfig,
                     bundleId: String,
                     appVersion: String,
                     sessionCount: Int) -> OrderedFields {
        var fields = OrderedFields()
        let now = DeviceInfo.timestamp()

        fields.set("app_token", config.appToken)
        fields.set("app_version", appVersion)
        fields.set("app_version_short", appVersion)
        fields.set("bundle_id", bundleId)
        fields.set("created_at", now)
        fields.set("device_name", DeviceInfo.deviceName)
        fields.set("device_type", DeviceInfo.hardwareModel())
        fields.set("environment", config.environment)
        fields.set("idfv", DeviceInfo.idfv)
        fields.set("installed_at", DemoState.installedAt)
        fields.set("os_name", "ios")
        fields.set("os_version", DeviceInfo.osVersion)
        fields.set("session_count", String(sessionCount))
        fields.set("started_at", now)
        fields.set("activity_kind", activityKind)
        fields.set("client_sdk", config.clientSdk)
        return fields
    }
}

