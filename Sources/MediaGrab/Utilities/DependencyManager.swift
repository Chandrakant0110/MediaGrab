import Foundation
import SwiftUI

/// Manages resolution, health checks, and 1-click automatic installation
/// for yt-dlp and ffmpeg so the app works seamlessly for any user on macOS.
@Observable
@MainActor
final class DependencyManager {
    static let shared = DependencyManager()

    var ytdlpPath: String?
    var ytdlpVersion: String?

    var ffmpegPath: String?
    var ffmpegVersion: String?

    var isChecking: Bool = false
    var isInstalling: Bool = false
    var installProgressText: String = ""
    var installError: String?

    var isReady: Bool {
        ytdlpPath != nil
    }

    var hasFFmpeg: Bool {
        ffmpegPath != nil
    }

    var appSupportBinDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("MediaGrab/bin", isDirectory: true)
    }

    init() {
        refresh()
    }

    /// Refresh detection of yt-dlp and ffmpeg binaries.
    func refresh() {
        isChecking = true
        ytdlpPath = findYTDLP()
        ffmpegPath = findFFmpeg()

        if let yt = ytdlpPath {
            ytdlpVersion = getVersion(path: yt)
        } else {
            ytdlpVersion = nil
        }

        if let ff = ffmpegPath {
            ffmpegVersion = getVersion(path: ff)
        } else {
            ffmpegVersion = nil
        }

        isChecking = false
    }

    // MARK: - Path Resolution

    private func findYTDLP() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let localBin = appSupportBinDir.appendingPathComponent("yt-dlp").path

        let candidates = [
            localBin,
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/opt/local/bin/yt-dlp",
            "\(home)/.local/bin/yt-dlp",
            "\(home)/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        // Try `which yt-dlp` in inherited PATH
        if let whichPath = runWhich("yt-dlp") {
            return whichPath
        }

        return nil
    }

    private func findFFmpeg() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let localBin = appSupportBinDir.appendingPathComponent("ffmpeg").path

        let candidates = [
            localBin,
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/opt/local/bin/ffmpeg",
            "\(home)/.local/bin/ffmpeg",
            "\(home)/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        if let whichPath = runWhich("ffmpeg") {
            return whichPath
        }

        return nil
    }

    private func runWhich(_ binary: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [binary]

        var env = ProcessInfo.processInfo.environment
        let extra = "/opt/homebrew/bin:/usr/local/bin:/opt/local/bin"
        env["PATH"] = extra + ":" + (env["PATH"] ?? "/usr/bin:/bin")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   FileManager.default.isExecutableFile(atPath: path) {
                    return path
                }
            }
        } catch {}
        return nil
    }

    private func getVersion(path: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = path.contains("ffmpeg") ? ["-version"] : ["--version"]

        var env = ProcessInfo.processInfo.environment
        let extra = "/opt/homebrew/bin:/usr/local/bin"
        env["PATH"] = extra + ":" + (env["PATH"] ?? "/usr/bin:/bin")
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let firstLine = output.components(separatedBy: "\n").first ?? output
                if path.contains("ffmpeg") {
                    // Extract e.g. "ffmpeg version 8.1"
                    if let range = firstLine.range(of: #"version\s+[\d\.]+"#, options: .regularExpression) {
                        return String(firstLine[range])
                    }
                    return String(firstLine.prefix(30))
                }
                return firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {}
        return nil
    }

    // MARK: - 1-Click Installer for yt-dlp

    /// Downloads the official standalone universal macOS binary of yt-dlp directly
    /// from GitHub Releases and places it in ~/Library/Application Support/MediaGrab/bin/yt-dlp.
    func installYTDLP() async {
        isInstalling = true
        installError = nil
        installProgressText = "Downloading official yt-dlp binary…"

        let targetDir = appSupportBinDir
        let targetFile = targetDir.appendingPathComponent("yt-dlp")

        do {
            try FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)

            guard let url = URL(string: "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos") else {
                throw NSError(domain: "MediaGrab", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
            }

            let (tempURL, response) = try await URLSession.shared.download(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "MediaGrab", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download failed from GitHub"])
            }

            // Remove existing if present
            if FileManager.default.fileExists(atPath: targetFile.path) {
                try FileManager.default.removeItem(at: targetFile)
            }

            try FileManager.default.moveItem(at: tempURL, to: targetFile)

            // Mark executable (chmod +x / 0o755)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: targetFile.path)

            installProgressText = "Verifying installation…"
            refresh()
            isInstalling = false
        } catch {
            installError = error.localizedDescription
            installProgressText = "Installation failed: \(error.localizedDescription)"
            isInstalling = false
        }
    }

    // MARK: - Update yt-dlp

    /// Runs `yt-dlp -U` to update to the latest version.
    func updateYTDLP() async -> String {
        guard let path = ytdlpPath else { return "yt-dlp is not installed" }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: path)
                process.arguments = ["-U"]

                var env = ProcessInfo.processInfo.environment
                let extra = "/opt/homebrew/bin:/usr/local/bin"
                env["PATH"] = extra + ":" + (env["PATH"] ?? "/usr/bin:/bin")
                process.environment = env

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Update completed"
                    Task { @MainActor in
                        self.refresh()
                    }
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(returning: "Error updating: \(error.localizedDescription)")
                }
            }
        }
    }
}
