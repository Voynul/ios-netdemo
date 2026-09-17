import Foundation

/// 一次签名调用的完整结果。
struct SignedPackage {
    /// 可直接写入 HTTP 头的完整 Authorization。
    let authorization: String
    /// 签名器写回的全部键值，含 signature / algorithm 等。
    let writeBack: [String: String]
    /// 本次进核的输入键数。
    let inputKeyCount: Int
}

enum SignerError: Error, CustomStringConvertible {
    case emptySignature(writeBack: [String: String])

    var description: String {
        switch self {
        case .emptySignature(let writeBack):
            let keys = writeBack.keys.sorted().joined(separator: ",")
            return "签名器未写回 signature。写回键：\(keys)"
        }
    }
}

/// 调用 AdjustSigSdk 的 ADJSigner。签名库版本由链接的 xcframework 决定，
/// 不由本文件控制。
enum Signer {

    /// 与 Protocol 组装格式一致：
    /// Signature signature="…",adj_signing_id="…",algorithm="…",headers_id="…",native_version="…"
    static func authorization(from writeBack: [String: String]) -> String {
        func value(_ key: String) -> String {
            writeBack[key] ?? ""
        }
        return "Signature signature=\"\(value("signature"))\""
            + ",adj_signing_id=\"\(value("adj_signing_id"))\""
            + ",algorithm=\"\(value("algorithm"))\""
            + ",headers_id=\"\(value("headers_id"))\""
            + ",native_version=\"\(value("native_version"))\""
    }

    /// 就地签名。签名器直接改写传入的字典。
    static func sign(fields: OrderedFields,
                     activityKind: String,
                     clientSdk: String) throws -> SignedPackage {
        let dict = NSMutableDictionary()
        for item in fields.items {
            dict[item.key] = item.value
        }
        let inputKeyCount = fields.items.count

        activityKind.withCString { kindPointer in
            clientSdk.withCString { sdkPointer in
                ADJSigner.sign(dict, withActivityKind: kindPointer, withSdkVersion: sdkPointer)
            }
        }

        var writeBack: [String: String] = [:]
        for case let key as String in dict.allKeys {
            if let value = dict[key] as? String {
                writeBack[key] = value
            }
        }

        guard let signature = writeBack["signature"], !signature.isEmpty else {
            throw SignerError.emptySignature(writeBack: writeBack)
        }

        return SignedPackage(authorization: authorization(from: writeBack),
                             writeBack: writeBack,
                             inputKeyCount: inputKeyCount)
    }
}

