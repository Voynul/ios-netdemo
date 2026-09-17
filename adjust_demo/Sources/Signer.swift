import Foundation

/// 一次签名调用的完整结果。
struct SignedPackage {
    /// 可直接写入 HTTP 头的完整 Authorization。
    let authorization: String
    /// 签名器写回的全部键值，含最终请求字段和 authorization。
    let writeBack: [String: String]
    /// 签名器处理后的最终 HTTP body 字段。
    let bodyFields: [(key: String, value: String)]
    /// 本次进核的输入键数。
    let inputKeyCount: Int
}

enum SignerError: Error, CustomStringConvertible {
    case runtime(String)
    case emptyAuthorization(writeBack: [String: String])

    var description: String {
        switch self {
        case .runtime(let message):
            return message
        case .emptyAuthorization(let writeBack):
            let keys = writeBack.keys.sorted().joined(separator: ",")
            return "签名器未写回 authorization。写回键：\(keys)"
        }
    }
}

/// 调用 AdjustSigSdk 的 ADJSigner。签名库版本由链接的 xcframework 决定，
/// 不由本文件控制。
enum Signer {

    static var libraryVersion: String {
        AdjustSignerRuntimeBridge.version() ?? "不可用"
    }

    /// 调用官方 SDK 使用的三参数签名入口。
    static func sign(fields: OrderedFields,
                     activityKind: String,
                     clientSdk: String,
                     endpoint: String) throws -> SignedPackage {
        var packageParams: [String: String] = [:]
        for item in fields.items where !FieldsBuilder.signatureOnlyKeys.contains(item.key) {
            packageParams[item.key] = item.value
        }
        let inputKeyCount = fields.items.count

        let result = AdjustSignerRuntimeBridge.signPackageParams(
            packageParams,
            activityKind: activityKind,
            clientSdk: clientSdk,
            endpoint: endpoint
        )
        if let errorMessage = result.errorMessage {
            throw SignerError.runtime(errorMessage)
        }

        let writeBack = result.outputParams ?? [:]

        guard let authorization = writeBack["authorization"], !authorization.isEmpty else {
            throw SignerError.emptyAuthorization(writeBack: writeBack)
        }

        let excluded: Set<String> = ["authorization", "endpoint"]
        let bodyFields = writeBack
            .filter { !excluded.contains($0.key) }
            .sorted { $0.key < $1.key }
            .map { (key: $0.key, value: $0.value) }

        return SignedPackage(authorization: authorization,
                             writeBack: writeBack,
                             bodyFields: bodyFields,
                             inputKeyCount: inputKeyCount)
    }
}
