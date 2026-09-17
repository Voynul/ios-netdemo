import UIKit

final class DemoViewController: UIViewController {

    private let textView = UITextView()
    private let runButton = UIButton(type: .system)
    private let config = DemoConfig.load()
    private var isRunning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = config.appName
        view.backgroundColor = .systemBackground
        buildLayout()
        append("签名库目标版本 \(config.nativeVersion)，client_sdk \(config.clientSdk)")
        append("点击按钮发送 session → sdk_click → attribution。")
        append("")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if config.autoSend && !isRunning && textView.text.contains("发包开始") == false {
            start()
        }
    }

    private func buildLayout() {
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.translatesAutoresizingMaskIntoConstraints = false

        runButton.setTitle("发包", for: .normal)
        runButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        runButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        runButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textView)
        view.addSubview(runButton)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            runButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            runButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            runButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            runButton.heightAnchor.constraint(equalToConstant: 46),
            runButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    @objc private func start() {
        guard !isRunning else { return }
        isRunning = true
        runButton.isEnabled = false

        let bundleId = Bundle.main.bundleIdentifier ?? config.bundleId
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
        let sessionCount = DemoState.nextSessionCount()

        let runner = DemoRunner(config: config,
                                bundleId: bundleId,
                                appVersion: appVersion,
                                sessionCount: sessionCount,
                                onLog: { [weak self] line in
                                    DispatchQueue.main.async { self?.append(line) }
                                },
                                onFinish: { [weak self] in
                                    DispatchQueue.main.async {
                                        self?.isRunning = false
                                        self?.runButton.isEnabled = true
                                    }
                                })
        DispatchQueue.global(qos: .userInitiated).async {
            runner.run()
        }
    }

    private func append(_ line: String) {
        textView.text.append(line + "\n")
        let end = NSRange(location: textView.text.count, length: 0)
        textView.scrollRangeToVisible(end)
    }
}

