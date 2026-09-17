import SwiftUI

private struct EndpointPreset: Identifiable {
    let id: String
    let title: String
    let url: String
    let useGET: Bool

    init(_ title: String, _ url: String, useGET: Bool = false) {
        self.id = url
        self.title = title
        self.url = url
        self.useGET = useGET
    }
}

struct ContentView: View {

    @State private var urlString = "https://httpbin.org/post"
    @State private var method = "POST"
    @State private var bodyText = """
    {"source":"NetDemo","msg":"hello from iPhone"}
    """
    @State private var output = "点击发送开始测试。"
    @State private var isSending = false
    @State private var lastOK: Bool?

    private let client = NetworkClient()

    private let presets: [EndpointPreset] = [
        EndpointPreset("httpbin 回显", "https://httpbin.org/post"),
        EndpointPreset("postman-echo 回显", "https://postman-echo.com/post"),
        EndpointPreset("Apple 连通性检测", "https://captive.apple.com/hotspot-detect.html", useGET: true)
    ]

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("https://example.com/api", text: $urlString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    Picker("方法", selection: $method) {
                        Text("GET").tag("GET")
                        Text("POST").tag("POST")
                        Text("PUT").tag("PUT")
                    }
                    .pickerStyle(.segmented)

                    Menu("填入预设地址") {
                        ForEach(presets) { preset in
                            Button(preset.title) {
                                urlString = preset.url
                                method = preset.useGET ? "GET" : "POST"
                            }
                        }
                    }
                } header: {
                    Text("目标")
                }

                if method != "GET" {
                    Section {
                        TextEditor(text: $bodyText)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(minHeight: 110)
                    } header: {
                        Text("请求体 (JSON)")
                    }
                }

                Section {
                    Button(action: send) {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView().padding(.trailing, 6)
                            }
                            Text(isSending ? "发送中" : "发送")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(isSending)
                }

                Section {
                    ScrollView {
                        Text(output)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(minHeight: 200)
                } header: {
                    HStack {
                        Text("结果")
                        Spacer()
                        if let ok = lastOK {
                            Text(ok ? "成功" : "失败")
                                .foregroundColor(ok ? .green : .red)
                                .bold()
                        }
                    }
                }
            }
            .navigationTitle("NetDemo")
        }
        .navigationViewStyle(.stack)
    }

    private func send() {
        isSending = true
        output = "请求中…"
        let url = urlString
        let m = method
        let body = bodyText

        Task {
            let result = await client.send(urlString: url, method: m, body: body)
            await MainActor.run {
                output = result.detail
                lastOK = result.ok
                isSending = false
            }
        }
    }
}
