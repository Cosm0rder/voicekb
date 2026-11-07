import UIKit

final class KeyboardViewController: UIInputViewController {

    private let barHeight: CGFloat = 58

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        setupBar()
        setHeight()
    }

    private func setHeight() {
        let c = NSLayoutConstraint(item: view as Any, attribute: .height, relatedBy: .equal,
                                   toItem: nil, attribute: .notAnAttribute, multiplier: 1.0,
                                   constant: barHeight)
        c.priority = .required
        view.addConstraint(c)
    }

    private func makeButton(title: String, action: Selector, primary: Bool = false) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: primary ? 17 : 16, weight: primary ? .semibold : .regular)
        b.backgroundColor = primary ? .systemBlue : .tertiarySystemBackground
        if primary { b.setTitleColor(.white, for: .normal) }
        b.layer.cornerRadius = 10
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    private func setupBar() {
        let mic = makeButton(title: "🎤 録音", action: #selector(openRecorder), primary: true)
        let paste = makeButton(title: "貼り付け", action: #selector(pasteFromClipboard))
        let del = makeButton(title: "⌫", action: #selector(deleteBackward))
        let ret = makeButton(title: "⏎", action: #selector(insertReturn))
        let globe = makeButton(title: "🌐", action: #selector(switchKeyboard))

        let stack = UIStackView(arrangedSubviews: [mic, paste, del, ret, globe])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        mic.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.30).isActive = true
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
        ])
    }

    @objc private func openRecorder() {
        guard let url = URL(string: "voicekb://record") else { return }
        // キーボード拡張からホストアプリを開く (レスポンダチェーン経由)
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = r.next
        }
    }

    @objc private func pasteFromClipboard() {
        guard hasFullAccess else { return }
        if let text = UIPasteboard.general.string, !text.isEmpty {
            textDocumentProxy.insertText(text)
        }
    }

    @objc private func deleteBackward() {
        textDocumentProxy.deleteBackward()
    }

    @objc private func insertReturn() {
        textDocumentProxy.insertText("\n")
    }

    @objc private func switchKeyboard() {
        advanceToNextInputMode()
    }
}
