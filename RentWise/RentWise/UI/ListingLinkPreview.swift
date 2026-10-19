import SwiftUI
import LinkPresentation

struct ListingLinkPreview: View {
    let url: URL
    let service: ListingPreviewService
    @State private var metadata: LPLinkMetadata?
    var body: some View {
        Group {
            if let metadata {
                NativeListingPreview(metadata: metadata)
            } else {
                ZStack {
                    Color(uiColor: .secondarySystemBackground)
                    Image(systemName: "house.fill").font(.largeTitle).foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: url) { metadata = await service.metadata(for: url) }
    }
}
private struct NativeListingPreview: UIViewRepresentable {
    let metadata: LPLinkMetadata
    func makeUIView(context: Context) -> LPLinkView {
        let view = LPLinkView(metadata: metadata)
        view.isUserInteractionEnabled = false
        return view
    }
    func updateUIView(_ uiView: LPLinkView, context: Context) { uiView.metadata = metadata }
}
