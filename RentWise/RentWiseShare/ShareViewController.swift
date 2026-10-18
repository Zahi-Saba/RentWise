//
//  ShareViewController.swift
//  RentWiseShare
//
//  Created by Zahi Saba 
//

import UIKit
import Social
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {

    private var isSaving = false

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Save to Rentwise"
        placeholder = "Save this listing, then return to Rentwise."
    }

    override func isContentValid() -> Bool {
        !isSaving && urlProvider() != nil
    }

    override func didSelectPost() {
        guard !isSaving else {
            return
        }

        guard let provider = urlProvider() else {
            showError("Please share a webpage link from Safari.")
            return
        }

        guard FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier:
                SharedRentalLinkData.appGroup
        ) != nil else {
            showError(
                "Shared storage is unavailable. Check that both "
                + "targets have the same App Group enabled."
            )
            return
        }

        isSaving = true
        validateContent()

        provider.loadItem(
            forTypeIdentifier: UTType.url.identifier,
            options: nil
        ) { [weak self] item, error in

            let sharedURL: URL?

            if let url = item as? URL {
                sharedURL = url
            } else if let text = item as? String {
                sharedURL = URL(string: text)
            } else {
                sharedURL = nil
            }

            DispatchQueue.main.async {
                guard let self else {
                    return
                }

                guard error == nil, let url = sharedURL else {
                    self.showError("The shared link could not be read.")
                    return
                }

                guard
                    let scheme = url.scheme?.lowercased(),
                    ["http", "https"].contains(scheme),
                    let host = url.host,
                    !host.isEmpty
                else {
                    self.showError("Please share a valid website link.")
                    return
                }

                SharedRentalLinkData.saveLink(url.absoluteString)

                self.extensionContext?.completeRequest(
                    returningItems: nil,
                    completionHandler: nil
                )
            }
        }
    }

    private func urlProvider() -> NSItemProvider? {
        let items =
            extensionContext?.inputItems as? [NSExtensionItem] ?? []

        return items
            .flatMap { $0.attachments ?? [] }
            .first {
                $0.hasItemConformingToTypeIdentifier(
                    UTType.url.identifier
                )
            }
    }

    private func showError(_ message: String) {
        isSaving = false
        validateContent()

        let alert = UIAlertController(
            title: "Could not save listing",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "OK", style: .default)
        )

        present(alert, animated: true)
    }
}
