import UIKit
import ImageIO

/// Downsample before decoding a full-resolution library photo into memory.
enum DefectPhotoService {
    enum PhotoError: LocalizedError {
        case unreadable
        var errorDescription: String? { "Couldn't load this photo. Please choose another image." }
    }

    static func prepare(_ data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1400,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary),
              let jpeg = UIImage(cgImage: thumbnail).jpegData(compressionQuality: 0.75) else {
            throw PhotoError.unreadable
        }
        guard jpeg.count <= 5_000_000 else { throw RoomInspectionError.photoTooLarge }
        return jpeg
    }
}
