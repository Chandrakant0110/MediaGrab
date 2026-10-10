import Foundation

/// Represents a persistently saved download history record.
struct HistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let url: String
    let formatRaw: String
    var filePath: String
    var thumbnailURL: String?
    var fileSizeBytes: Int64?
    let downloadedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        format: DownloadFormat,
        filePath: String,
        thumbnailURL: String? = nil,
        fileSizeBytes: Int64? = nil,
        downloadedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.formatRaw = format.rawValue
        self.filePath = filePath
        self.thumbnailURL = thumbnailURL
        self.fileSizeBytes = fileSizeBytes
        self.downloadedAt = downloadedAt
    }

    var format: DownloadFormat {
        DownloadFormat(rawValue: formatRaw) ?? .video
    }

    /// Checks if the physical file is still present on the filesystem.
    var fileExistsOnDisk: Bool {
        FileManager.default.fileExists(atPath: filePath)
    }

    /// Returns human-readable file size (e.g., "14.2 MB").
    var formattedSize: String {
        if let bytes = fileSizeBytes, bytes > 0 {
            return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        }
        // Try reading live from filesystem
        if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
           let size = attrs[.size] as? Int64, size > 0 {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        return "Unknown size"
    }

    /// Formatted relative or short date.
    var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(downloadedAt) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if Calendar.current.isDateInYesterday(downloadedAt) {
            formatter.dateFormat = "'Yesterday at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, yyyy · h:mm a"
        }
        return formatter.string(from: downloadedAt)
    }
}
