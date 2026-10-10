import Foundation
import SwiftUI
import AppKit

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all    = "All"
    case videos = "Videos"
    case audio  = "Audio"

    var id: String { rawValue }
}

/// Manages persistent download history saved to Application Support/MediaGrab/history.json.
@Observable
@MainActor
final class HistoryManager {
    static let shared = HistoryManager()

    var items: [HistoryItem] = []
    var searchQuery: String = ""
    var selectedFilter: HistoryFilter = .all

    private let fileURL: URL

    // MARK: - Init

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("MediaGrab", isDirectory: true)

        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("history.json")

        loadHistory()
    }

    // MARK: - Persistence

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode([HistoryItem].self, from: data)
            self.items = decoded.sorted { $0.downloadedAt > $1.downloadedAt }
        } catch {
            print("[HistoryManager] Failed to load history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[HistoryManager] Failed to save history: \(error)")
        }
    }

    // MARK: - Actions

    /// Records a completed download to history.
    func record(from item: DownloadItem, finalPath: String) {
        // Read file size if present
        var sizeBytes: Int64? = nil
        if let attrs = try? FileManager.default.attributesOfItem(atPath: finalPath),
           let s = attrs[.size] as? Int64 {
            sizeBytes = s
        }

        let historyItem = HistoryItem(
            title: item.title,
            url: item.url,
            format: item.format,
            filePath: finalPath,
            thumbnailURL: item.thumbnailURL,
            fileSizeBytes: sizeBytes,
            downloadedAt: item.completedAt ?? Date()
        )

        // Avoid exact duplicate within last 5 seconds
        if let first = items.first, first.url == item.url && abs(first.downloadedAt.timeIntervalSinceNow) < 5 {
            return
        }

        items.insert(historyItem, at: 0)
        saveHistory()
    }

    /// Remove a single item from the list.
    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        saveHistory()
    }

    /// Clear all items from history.
    func clearAll() {
        items.removeAll()
        saveHistory()
    }

    /// Delete physical file from disk and remove from history.
    func deleteFileAndHistory(item: HistoryItem) {
        if FileManager.default.fileExists(atPath: item.filePath) {
            try? FileManager.default.removeItem(atPath: item.filePath)
        }
        remove(id: item.id)
    }

    /// Open file in default system application (QuickTime, Music, etc.).
    func openFile(item: HistoryItem) {
        let url = URL(fileURLWithPath: item.filePath)
        if FileManager.default.fileExists(atPath: item.filePath) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Reveal file in Finder.
    func revealInFinder(item: HistoryItem) {
        let path = item.filePath
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        } else {
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: parent)
        }
    }

    // MARK: - Computed Statistics

    var totalSizeBytes: Int64 {
        items.compactMap { $0.fileSizeBytes }.reduce(0, +)
    }

    var totalFormattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSizeBytes, countStyle: .file)
    }

    // MARK: - Filtered items

    var filteredItems: [HistoryItem] {
        var result = items

        // Filter by format
        switch selectedFilter {
        case .all:
            break
        case .videos:
            result = result.filter { !$0.format.isAudio }
        case .audio:
            result = result.filter { $0.format.isAudio }
        }

        // Filter by search query
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.url.lowercased().contains(query)
            }
        }

        return result
    }
}
