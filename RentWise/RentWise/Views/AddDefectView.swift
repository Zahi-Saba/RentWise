import SwiftUI
import PhotosUI

struct AddDefectView: View {
    @ObservedObject var viewModel: RentWiseViewModel
    let propertyID: UUID
    let roomID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var severity: DefectSeverity = .minor
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photo: Data?
    @State private var photoError = ""
    @State private var isLoadingPhoto = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Describe the defect", text: $description, axis: .vertical)
                        .lineLimit(3...8).accessibilityLabel("Defect description")
                    Picker("Severity", selection: $severity) {
                        ForEach(DefectSeverity.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Photo (optional)") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose photo", systemImage: "photo")
                    }
                    if isLoadingPhoto { ProgressView("Loading photo") }
                    if !photoError.isEmpty { Text(photoError).foregroundStyle(.red) }
                    if let photo, let image = UIImage(data: photo) {
                        Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 240)
                            .accessibilityLabel("Selected defect photo")
                    }
                    if selectedPhoto != nil {
                        Button("Remove photo", role: .destructive) {
                            selectedPhoto = nil; photo = nil; photoError = ""; isLoadingPhoto = false
                        }
                    }
                }
                Section {
                    Button("Save defect") {
                        if viewModel.recordRoomDefect(propertyID: propertyID, roomID: roomID,
                                                      description: description, severity: severity, photo: photo) { dismiss() }
                    }
                    .disabled(isLoadingPhoto || !photoError.isEmpty || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage).foregroundStyle(.red)
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto else { isLoadingPhoto = false; return }
                isLoadingPhoto = true; photo = nil; photoError = ""
                defer { if !Task.isCancelled { isLoadingPhoto = false } }
                do {
                    guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
                        throw DefectPhotoService.PhotoError.unreadable
                    }
                    try Task.checkCancellation()
                    let prepared = try DefectPhotoService.prepare(data)
                    try Task.checkCancellation()
                    photo = prepared
                } catch {
                    guard !Task.isCancelled else { return }
                    photoError = error.localizedDescription
                }
            }
            .navigationTitle("Record defect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
