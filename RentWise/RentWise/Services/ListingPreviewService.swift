import Foundation
import LinkPresentation

@MainActor
final class ListingPreviewService {
    private var cache: [URL: LPLinkMetadata] = [:]
    private var pending: [URL: Task<LPLinkMetadata?, Never>] = [:]

    func metadata(for url: URL) async -> LPLinkMetadata? {
        if let cached = cache[url] { return cached }
        if let task = pending[url] { return await task.value }
        let task = Task { @MainActor () -> LPLinkMetadata? in
            let provider = LPMetadataProvider()
            provider.timeout = 10
            return try? await provider.startFetchingMetadata(for: url)
        }
        pending[url] = task
        let result = await task.value
        pending[url] = nil
        if let result { cache[url] = result }
        return result
    }
}
