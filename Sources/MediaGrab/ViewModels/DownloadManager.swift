import Foundation
import SwiftUI
import AppKit

/// Central state for the app — owns the download queue, user preferences, and dependency health.
@Observable
@MainActor
final class DownloadManager {

    // MARK: - State

    var downloads: [DownloadItem] = []
    var currentURL: String = ""
    var selectedFormat: DownloadFormat = .video
    var savePath: String
    var dependencyManager = DependencyManager.shared

    /// Computed: is any download currently in progress?
    var isDownloading: Bool {
        downloads.contains { $0.status.isActive }
    }

    /// Computed: is yt-dlp available on this machine?
    var ytdlpAvailable: Bool {
        dependencyManager.isReady
    }

    // MARK: - Init

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let workspaceOutputs = home.appendingPathComponent("chandrakant_bot/outputs/videos")

        // If running inside the workspace repository, follow the workspace file-saving rule
        if FileManager.default.fileExists(atPath: home.appendingPathComponent("chandrakant_bot").path) {
            self.savePath = workspaceOutputs.path
        } else {
            // General macOS user release default: ~/Downloads/MediaGrab/videos
            let defaultDownloads = home.appendingPathComponent("Downloads/MediaGrab/videos")
            self.savePath = defaultDownloads.path
        }
    }

    // MARK: - Actions

    /// Swap the trailing folder between "videos" and "audio" when the format changes.
    func updateSavePathForFormat() {
        let url = URL(fileURLWithPath: savePath)
        let last = url.lastPathComponent
        // Only auto-swap if the current leaf is one of our known folders
        if last == "videos" || last == "audio" {
            let parent = url.deletingLastPathComponent()
            savePath = parent
                .appendingPathComponent(selectedFormat.defaultSubfolder)
                .path
        }
    }

    /// Kick off a download for the current URL + format.
    func startDownload() {
        var raw = currentURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }

        // Auto-prefix https:// if user pasted without protocol
        if !raw.hasPrefix("http://") && !raw.hasPrefix("https://") {
            raw = "https://" + raw
        }

        var item = DownloadItem(url: raw, format: selectedFormat, savePath: savePath)
        item.status = .waiting
        downloads.insert(item, at: 0)
        currentURL = ""

        let itemID = item.id
        let format = item.format
        let dir    = item.savePath
        let url    = item.url

        // 1. Fetch metadata in background (clean title & thumbnail)
        Task {
            let meta = await YTDLPRunner.fetchMetadata(url: url)
            if let idx = self.downloads.firstIndex(where: { $0.id == itemID }) {
                if let t = meta.title, !t.isEmpty {
                    self.downloads[idx].title = t
                }
                if let thumb = meta.thumbnailURL, !thumb.isEmpty {
                    self.downloads[idx].thumbnailURL = thumb
                }
            }
        }

        // 2. Start streaming download
        Task {
            do {
                let stream = YTDLPRunner.download(url: url, format: format, outputDir: dir)

                for try await update in stream {
                    guard let idx = self.downloads.firstIndex(where: { $0.id == itemID }) else { break }

                    // Accumulate logs
                    if !update.rawLine.isEmpty {
                        self.downloads[idx].logs.append(update.rawLine)
                        if self.downloads[idx].logs.count > 400 {
                            self.downloads[idx].logs.removeFirst(50)
                        }
                    }

                    if let title = update.title {
                        self.downloads[idx].title = title
                    }
                    if let filePath = update.finalFilePath {
                        self.downloads[idx].finalFilePath = filePath
                    }

                    if let error = update.error {
                        self.downloads[idx].status = .failed(error: error)
                        self.downloads[idx].isLogExpanded = true
                    } else if update.isComplete {
                        let finalPath = update.finalFilePath ?? self.downloads[idx].finalFilePath ?? dir
                        self.downloads[idx].status = .completed(filePath: finalPath)
                        self.downloads[idx].completedAt = Date()
                    } else if let stage = update.processingStage {
                        self.downloads[idx].status = .processing(stage: stage)
                    } else if let pct = update.percentage {
                        self.downloads[idx].status = .downloading(
                            progress: pct,
                            speed: update.speed,
                            eta: update.eta
                        )
                    }
                }

                // Safety net: if stream exited normally
                if let idx = self.downloads.firstIndex(where: { $0.id == itemID }),
                   self.downloads[idx].status.isActive {
                    let finalPath = self.downloads[idx].finalFilePath ?? dir
                    self.downloads[idx].status = .completed(filePath: finalPath)
                    self.downloads[idx].completedAt = Date()
                }
            } catch {
                if let idx = self.downloads.firstIndex(where: { $0.id == itemID }) {
                    self.downloads[idx].status = .failed(error: error.localizedDescription)
                    self.downloads[idx].isLogExpanded = true
                }
            }
        }
    }

    /// Toggle logs disclosure for an item.
    func toggleLog(for id: UUID) {
        if let idx = downloads.firstIndex(where: { $0.id == id }) {
            downloads[idx].isLogExpanded.toggle()
        }
    }

    /// Copy logs for an item to the clipboard.
    func copyLogs(for id: UUID) {
        guard let item = downloads.first(where: { $0.id == id }) else { return }
        let logText = item.logs.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logText, forType: .string)
    }

    /// Remove finished (completed + failed) items from the list.
    func clearCompleted() {
        downloads.removeAll { !$0.status.isActive }
    }

    /// Show a native macOS folder picker.
    func chooseSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories    = true
        panel.canChooseFiles          = false
        panel.canCreateDirectories    = true
        panel.allowsMultipleSelection = false
        panel.prompt  = "Choose"
        panel.message = "Select download location"

        if panel.runModal() == .OK, let url = panel.url {
            savePath = url.path
        }
    }

    /// Open file or folder in Finder, selecting the exact file if it exists.
    func revealInFinder(path: String) {
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        } else {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
        }
    }

    /// Paste URL from the system clipboard.
    func pasteFromClipboard() {
        guard let raw = NSPasteboard.general.string(forType: .string) else { return }
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }

        if !cleaned.hasPrefix("http://") && !cleaned.hasPrefix("https://") {
            cleaned = "https://" + cleaned
        }
        currentURL = cleaned
    }
}
