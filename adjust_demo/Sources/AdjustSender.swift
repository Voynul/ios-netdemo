import Foundation

/// 单次请求的完整结果，供日志与 UI 展示。
struct SendOutcome {
    let label: String
    let url: String
    let authorization: String
    let bodyFields: [(key: String, value: String)]
    let status: Int
    let responseBody: String
    let transportError: String?
    let elapsedMs: Int

    var succeeded: Bool {
        transportError == nil && (200..<300).contains(status)
    }
}

/// 按 Adjust 的 form 编码发送请求。
///
/// 形式依据本工作区 `adjust_test/adjust-signature` 的 `AdjustHttpClient`：
/// POST、`application/x-www-form-urlencoded`、头 `Client-SDK` / `Authorization` /
/// `User-Agent`；`activity_kind` 与 `client_sdk` 只参与签名，不进入 body。
enum AdjustSender {

    private static let formAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    static func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: formAllowed) ?? value
    }

    static func send(label: String,
                     path: String,
                     bodyFields: [(key: String, value: String)],
                     authorization: String,
                     clientSdk: String,
                     config: DemoConfig,
                     completion: @escaping (SendOutcome) -> Void) {
        let form = bodyFields
            .map { "\(encode($0.key))=\(encode($0.value))" }
            .joined(separator: "&")

        let urlString = config.baseUrl + path
        let started = Date()

        guard let url = URL(string: urlString) else {
            completion(SendOutcome(label: label, url: urlString, authorization: authorization,
                                   bodyFields: bodyFields, status: -1, responseBody: "",
                                   transportError: "URL 无效", elapsedMs: 0))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(clientSdk, forHTTPHeaderField: "Client-SDK")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("AdjustDemo/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.httpBody = form.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let elapsed = Int(Date().timeIntervalSince(started) * 1000)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            completion(SendOutcome(label: label, url: urlString, authorization: authorization,
                                   bodyFields: bodyFields, status: status, responseBody: text,
                                   transportError: error?.localizedDescription, elapsedMs: elapsed))
        }
        task.resume()
    }
}
