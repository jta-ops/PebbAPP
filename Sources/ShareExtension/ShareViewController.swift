import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    private let purple = UIColor(red: 0.49, green: 0.44, blue: 0.80, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        extractContent()
    }

    // MARK: - UI
    private func buildUI() {
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 0.96)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.frame = view.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blur)

        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        card.layer.cornerRadius = 24
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        card.layer.borderWidth = 1
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let iconBg = UIView()
        iconBg.backgroundColor = purple.withAlphaComponent(0.15)
        iconBg.layer.cornerRadius = 16
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(named: "PebbLogo"))
        iconView.contentMode = .scaleAspectFill
        iconView.layer.cornerRadius = 10
        iconView.clipsToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconView)

        let title = UILabel()
        title.text = "Sending to Pebb…"
        title.font = .systemFont(ofSize: 17, weight: .bold)
        title.textColor = UIColor(red: 0.93, green: 0.92, blue: 0.97, alpha: 1)

        let subtitle = UILabel()
        subtitle.text = "Opening your chat"
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = UIColor(red: 0.43, green: 0.42, blue: 0.54, alpha: 1)

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = purple
        spinner.startAnimating()

        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        cancelBtn.setTitleColor(UIColor(red: 0.43, green: 0.42, blue: 0.54, alpha: 1), for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        for v in [iconBg, title, subtitle, spinner, cancelBtn] as [UIView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(v)
        }

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 280),

            iconBg.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            iconBg.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 52),
            iconBg.heightAnchor.constraint(equalToConstant: 52),
            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            title.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 16),
            title.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            subtitle.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            spinner.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            cancelBtn.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 20),
            cancelBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            cancelBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - Extract & Send
    private func extractContent() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else { done(); return }

        let attachments = item.attachments ?? []
        let bodyText = item.attributedContentText?.string ?? ""
        let group = DispatchGroup()
        var urlString: String?
        var imageData: Data?

        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                    if let url = item as? URL { urlString = url.absoluteString }
                    group.leave()
                }
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, _ in
                    if let img = item as? UIImage { imageData = img.jpegData(compressionQuality: 0.7) }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            let parts = [bodyText, urlString].compactMap { $0 }.filter { !$0.isEmpty }
            let message = parts.joined(separator: "\n")
            self.sendToAPI(text: message, imageData: imageData)
        }
    }

    private func sendToAPI(text: String, imageData: Data?) {
        let token = UserDefaults(suiteName: "group.dev.pebb.app")?.string(forKey: "pebb_token")
            ?? UserDefaults.standard.string(forKey: "pebb_token") ?? ""
        guard !token.isEmpty else { done(); return }

        var body: [String: Any] = ["token": token, "message": text.isEmpty ? "(shared content)" : text]

        guard let url = URL(string: "https://pebb.dev/webchat/api/chat"),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else { done(); return }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyData

        URLSession.shared.dataTask(with: req) { [weak self] _, _, _ in
            DispatchQueue.main.async { self?.done() }
        }.resume()
    }

    private func done() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    @objc private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "dev.pebb.share", code: 0))
    }
}
