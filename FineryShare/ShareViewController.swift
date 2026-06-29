import UIKit
import SwiftUI

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            cancel(); return
        }

        if provider.hasItemConformingToTypeIdentifier("public.text") {
            provider.loadItem(forTypeIdentifier: "public.text") { [weak self] item, _ in
                let text = item as? String
                DispatchQueue.main.async {
                    if let text {
                        self?.showParseResult(text)
                    } else {
                        self?.cancel()
                    }
                }
            }
        } else {
            cancel()
        }
    }

    private func showParseResult(_ text: String) {
        let parsed = SMSParser.parse(text)
        let vc = UIHostingController(
            rootView: ShareParseView(
                parsed: parsed,
                originalText: text,
                onSave:   { [weak self] tx in self?.saveTransaction(tx) },
                onCancel: { [weak self] in self?.cancel() }
            )
        )
        addChild(vc)
        view.addSubview(vc.view)
        vc.view.frame = view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.didMove(toParent: self)
    }

    private func saveTransaction(_ transaction: ParsedTransaction) {
        let defaults = UserDefaults(suiteName: "group.com.tkachev.finery")
        var pending = defaults?.array(forKey: "pending_transactions")
            as? [[String: Any]] ?? []
        pending.append([
            "amount":      transaction.amount,
            "direction":   transaction.direction,
            "description": transaction.description,
            "category":    transaction.category,
            "date":        ISO8601DateFormatter().string(from: Date())
        ])
        defaults?.set(pending, forKey: "pending_transactions")
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancel() {
        extensionContext?.cancelRequest(
            withError: NSError(domain: "FineryShare", code: 0))
    }
}
