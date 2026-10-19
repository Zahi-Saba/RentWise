import Foundation

enum ImportSharedPropertyError: LocalizedError {
    case invalidURL
    var errorDescription: String? { "Please share a valid website URL." }
}
struct ImportSharedPropertyUseCase {
    let repository: RentalPropertyRepository

    static func validatedURL(_ link: String) throws -> URL {
        guard var components = URLComponents(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty else { throw ImportSharedPropertyError.invalidURL }
        components.fragment = nil
        guard let url = components.url else { throw ImportSharedPropertyError.invalidURL }
        return url
    }

    func execute(link: String, title: String?, weeklyRent: Double? = nil) throws -> RentalProperty {
        let url = try Self.validatedURL(link)
        if var existing = try repository.fetchRentalProperties().first(where: { $0.sourceURL == url.absoluteString }) {
            if let weeklyRent, weeklyRent.isFinite, weeklyRent > 0 {
                existing.weeklyRent = weeklyRent
                try repository.update(existing)
            }
            return existing
        }
        let cleanedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let property = RentalProperty(
            address: cleanedTitle.flatMap { $0.isEmpty ? nil : $0 } ?? "Listing from \(url.host ?? "website")",
            weeklyRent: weeklyRent.flatMap { $0.isFinite && $0 > 0 ? $0 : nil } ?? 0,
            sourceURL: url.absoluteString
        )
        try repository.save(property)
        return property
    }
}
