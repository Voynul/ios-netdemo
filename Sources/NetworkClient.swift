import Foundation

struct SendResult {
    let ok: Bool
    let detail: String
}

final class NetworkClient {

    private let session: URLSession

    init() {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 40
        session = URLSession(configuration: cfg)
    }

    func send(urlString: String, method: String, body: String) async -> SendResult {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host?.isEmpty == false
        else {
            return SendResult(ok: false, detail: "URL 无效，需要以 http:// 或 https:// 开头的完整地址。")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("NetDemo/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        if method != "GET" {
            let payload = body.trimmingCharacters(in: .whitespacesAndNewlines)
            if !payload.isEmpty {
                request.httpBody = Data(payload.utf8)
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }
        }

        let started = Date()
        do {
            let (data, response) = try await session.data(for: request)
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let header = "\(method) \(url.absoluteString)\nHTTP \(code)  \(ms) ms  \(data.count) bytes"
            return SendResult(ok: (200..<300).contains(code),
                              detail: header + "\n\n" + Self.preview(data))
        } catch {
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            let ns = error as NSError
            let header = "\(method) \(url.absoluteString)\n发送失败  \(ms) ms"
            let detail = "\(ns.domain) \(ns.code)\n\(ns.localizedDescription)"
            return SendResult(ok: false, detail: header + "\n\n" + detail)
        }
    }

    private static func preview(_ data: Data) -> String {
        guard !data.isEmpty else { return "<空响应体>" }
        if let text = String(data: data.prefix(4000), encoding: .utf8) {
            return text
        }
        return "<\(data.count) 字节二进制数据，非 UTF-8 文本>"
    }
}

