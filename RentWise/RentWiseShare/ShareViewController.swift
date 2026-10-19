import UIKit
import Social
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {
    private var saving = false
    override func isContentValid() -> Bool { !saving }
    override func didSelectPost() {
        guard !saving else { return }
        saving = true
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        let enteredTitle = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackTitle = items.first?.attributedContentText?.string ?? ""
        if let pageProvider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.propertyList.identifier) }) {
            pageProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier, options: nil) { [weak self] item, _ in
                let dictionary = item as? NSDictionary
                let page = dictionary?[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any]
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let text = page?["url"] as? String, let url = URL(string: text) {
                        let title = enteredTitle.isEmpty ? (page?["title"] as? String ?? fallbackTitle) : enteredTitle
                        self.save(url: url, title: title, weeklyRent: (page?["weeklyRent"] as? NSNumber)?.doubleValue)
                    } else { self.loadURL(providers, title: enteredTitle.isEmpty ? fallbackTitle : enteredTitle) }
                }
            }
        } else { loadURL(providers, title: enteredTitle.isEmpty ? fallbackTitle : enteredTitle) }
    }
    private func loadURL(_ providers: [NSItemProvider], title: String) {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) else {
            showError("No webpage URL was supplied. Share the open listing from Safari."); return
        }
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] value, _ in
            let url = (value as? URL) ?? (value as? String).flatMap(URL.init(string:))
            DispatchQueue.main.async {
                guard let self else { return }
                guard let url else { self.showError("The shared item is not a valid web URL."); return }
                self.save(url: url, title: title, weeklyRent: nil)
            }
        }
    }
    private func save(url: URL, title: String, weeklyRent: Double?) {
        guard ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { showError("The shared item is not a valid web URL."); return }
        do {
            try SharedRentalLinkData.saveListing(SharedListing(url: url.absoluteString, title: title, weeklyRent: weeklyRent))
            extensionContext?.completeRequest(returningItems: nil)
        } catch { showError(error.localizedDescription) }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Save to Rentwise"
        placeholder = "Optional listing title. Return to Rentwise after saving."
    }
    private func showError(_ text: String) {
        saving = false
        validateContent()
        let alert = UIAlertController(title: "Could not save listing", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
