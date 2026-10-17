//
//  SharedPropertyPreviewView.swift
//  RentWise
//
//  Created by Zahi Saba on 3/10/2026.
//

import SwiftUI
import LinkPresentation

struct SharedPropertyPreviewView: View {

    @State private var sharedLinks: [String] = []

    var body: some View {

        ZStack {

                            RentWiseTheme.background
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {

                    SectionTitle(
                        title: "Shared Properties"
                    )

                    Text(
                        "Rental listings shared from Safari appear here."
                    )
                    .foregroundColor(
                                        RentWiseTheme.secondaryText
                    )

                    if sharedLinks.isEmpty {

                        VStack(spacing: 12) {

                            Image(
                                systemName:
                                    "square.and.arrow.down"
                            )
                            .font(.system(size: 40))
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )

                            Text(
                                "No rental properties have been shared yet."
                            )
                            .foregroundColor(
                                                RentWiseTheme.secondaryText
                            )
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(30)
                        .background(
                                            RentWiseTheme.card
                        )
                        .cornerRadius(15)

                    } else {

                        ForEach(
                            sharedLinks,
                            id: \.self
                        ) { link in

                            SharedPropertyCard(
                                link: link,
                                onRemove: {

                                    removeSharedLink(
                                        link
                                    )
                                }
                            )
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("Shared Properties")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {

            sharedLinks =
                SharedRentalLinkData.loadLinks()
        }
        .preferredColorScheme(.dark)
    }

    private func removeSharedLink(
        _ link: String
    ) {

        SharedRentalLinkData.removeLink(
            link
        )

        sharedLinks =
            SharedRentalLinkData.loadLinks()
    }
}

struct SharedPropertyCard: View {

    let link: String
    let onRemove: () -> Void

    @State private var metadata: LPLinkMetadata?

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            if let metadata = metadata {

                LinkPreview(
                    metadata: metadata
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: 300
                )

            } else {

                ProgressView(
                    "Loading property..."
                )
                .foregroundColor(
                                    RentWiseTheme.mainText
                )
                .frame(
                    maxWidth: .infinity
                )
                .padding(40)
            }

            Button {

                onRemove()

            } label: {

                HStack {

                    Image(
                        systemName: "trash"
                    )

                    Text("Remove Property")
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(
                            RentWiseTheme.card
        )
        .cornerRadius(15)
        .onAppear {
            loadPreview()
        }
    }

    private func loadPreview() {

        if let url = URL(
            string: link
        ) {

            let provider =
                LPMetadataProvider()

            provider.startFetchingMetadata(
                for: url
            ) { metadata, error in

                if let metadata = metadata {

                    DispatchQueue.main.async {

                        self.metadata =
                            metadata
                    }
                }
            }
        }
    }
}

struct LinkPreview: UIViewRepresentable {

    let metadata: LPLinkMetadata

    func makeUIView(
        context: Context
    ) -> LPLinkView {

        let linkView = LPLinkView()

        linkView.metadata = metadata

        return linkView
    }

    func updateUIView(
        _ uiView: LPLinkView,
        context: Context
    ) {

        uiView.metadata = metadata
    }
}
