import UIKit

final class DemoViewController: UIViewController {

    private let textView = UITextView()
    private let config: DemoConfig
    private let startupResult: String

    init(config: DemoConfig, startupResult: String) {
        self.config = config
        self.startupResult = startupResult
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = config.appName
        view.backgroundColor = .systemBackground
        buildLayout()
        append("Adjust SDK：\(config.adjustSdkVersion)")
        append("Signature Library：\(config.nativeVersion)")
        append("environment：\(config.environment)")
        append("启动 deep link：\(config.startupDeeplink)")
        append("")
        append(startupResult)
        append("请通过 Reqable 查看 SDK 实际生成的 session、sdk_click 和归因请求。")
    }

    private func buildLayout() {
        textView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func append(_ line: String) {
        textView.text.append(line + "\n")
        let end = NSRange(location: textView.text.count, length: 0)
        textView.scrollRangeToVisible(end)
    }
}
