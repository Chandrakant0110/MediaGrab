import Foundation
import SwiftUI
import AppKit

/// Video quality preference for yt-dlp downloads.
enum VideoQualityPreference: String, CaseIterable, Identifiable, Codable {
    case best   = "Best Available"
    case p1080  = "1080p (Full HD)"
    case p720   = "720p (HD)"
    case p480   = "480p (SD)"

    var id: String { rawValue }

    var sortArgument: String {
        switch self {
        case .best:
            return "vcodec:h264,lang,quality,res,fps,hdr:12,acodec:aac"
        case .p1080:
            return "res:1080,vcodec:h264,lang,quality,fps,hdr:12,acodec:aac"
        case .p720:
            return "res:720,vcodec:h264,lang,quality,fps,hdr:12,acodec:aac"
        case .p480:
            return "res:480,vcodec:h264,lang,quality,fps,hdr:12,acodec:aac"
        }
    }
}

/// Theme appearance preference.
enum AppThemeMode: String, CaseIterable, Identifiable, Codable {
    case system = "System"
    case dark   = "Dark"
    case light  = "Light"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark:   return .dark
        case .light:  return .light
        }
    }
}

/// Central user configuration with persistent UserDefaults backing.
@Observable
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - Keys
    private enum Keys {
        static let themeMode               = "mg_themeMode"
        static let videoSaveLocation       = "mg_videoSaveLocation"
        static let audioSaveLocation       = "mg_audioSaveLocation"
        static let useSeparateFolders      = "mg_useSeparateFolders"
        static let defaultFormat           = "mg_defaultFormat"
        static let videoQuality            = "mg_videoQuality"
        static let autoPasteClipboard      = "mg_autoPasteClipboard"
        static let playNotificationSound   = "mg_playNotificationSound"
        static let sendSystemNotification  = "mg_sendSystemNotification"
    }

    // MARK: - Stored Properties with UserDefaults backing

    var themeMode: AppThemeMode {
        didSet {
            UserDefaults.standard.set(themeMode.rawValue, forKey: Keys.themeMode)
            applySystemAppearance()
        }
    }

    var videoSaveLocation: String {
        didSet { UserDefaults.standard.set(videoSaveLocation, forKey: Keys.videoSaveLocation) }
    }

    var audioSaveLocation: String {
        didSet { UserDefaults.standard.set(audioSaveLocation, forKey: Keys.audioSaveLocation) }
    }

    var useSeparateFolders: Bool {
        didSet { UserDefaults.standard.set(useSeparateFolders, forKey: Keys.useSeparateFolders) }
    }

    var defaultFormat: DownloadFormat {
        didSet { UserDefaults.standard.set(defaultFormat.rawValue, forKey: Keys.defaultFormat) }
    }

    var videoQuality: VideoQualityPreference {
        didSet { UserDefaults.standard.set(videoQuality.rawValue, forKey: Keys.videoQuality) }
    }

    var autoPasteClipboard: Bool {
        didSet { UserDefaults.standard.set(autoPasteClipboard, forKey: Keys.autoPasteClipboard) }
    }

    var playNotificationSound: Bool {
        didSet { UserDefaults.standard.set(playNotificationSound, forKey: Keys.playNotificationSound) }
    }

    var sendSystemNotification: Bool {
        didSet { UserDefaults.standard.set(sendSystemNotification, forKey: Keys.sendSystemNotification) }
    }

    // MARK: - Init

    private init() {
        let defaults = UserDefaults.standard
        let home = FileManager.default.homeDirectoryForCurrentUser

        // Smart default: check if workspace exists for local dev, otherwise ~/Downloads/MediaGrab
        let workspaceRoot = home.appendingPathComponent("chandrakant_bot")
        let isWorkspace = FileManager.default.fileExists(atPath: workspaceRoot.path)

        let defaultVideo = isWorkspace
            ? workspaceRoot.appendingPathComponent("outputs/videos").path
            : home.appendingPathComponent("Downloads/MediaGrab/videos").path

        let defaultAudio = isWorkspace
            ? workspaceRoot.appendingPathComponent("outputs/audio").path
            : home.appendingPathComponent("Downloads/MediaGrab/audio").path

        self.videoSaveLocation = defaults.string(forKey: Keys.videoSaveLocation) ?? defaultVideo
        self.audioSaveLocation = defaults.string(forKey: Keys.audioSaveLocation) ?? defaultAudio

        if let rawTheme = defaults.string(forKey: Keys.themeMode),
           let mode = AppThemeMode(rawValue: rawTheme) {
            self.themeMode = mode
        } else {
            self.themeMode = .system
        }

        self.useSeparateFolders = defaults.object(forKey: Keys.useSeparateFolders) as? Bool ?? true

        if let rawFormat = defaults.string(forKey: Keys.defaultFormat),
           let format = DownloadFormat(rawValue: rawFormat) {
            self.defaultFormat = format
        } else {
            self.defaultFormat = .video
        }

        if let rawQuality = defaults.string(forKey: Keys.videoQuality),
           let quality = VideoQualityPreference(rawValue: rawQuality) {
            self.videoQuality = quality
        } else {
            self.videoQuality = .best
        }

        self.autoPasteClipboard = defaults.object(forKey: Keys.autoPasteClipboard) as? Bool ?? true
        self.playNotificationSound = defaults.object(forKey: Keys.playNotificationSound) as? Bool ?? true
        self.sendSystemNotification = defaults.object(forKey: Keys.sendSystemNotification) as? Bool ?? true

        applySystemAppearance()
    }

    /// Synchronizes the global macOS application appearance with the user's theme selection.
    func applySystemAppearance() {
        switch themeMode {
        case .system:
            NSApp?.appearance = nil
        case .dark:
            NSApp?.appearance = NSAppearance(named: .darkAqua)
        case .light:
            NSApp?.appearance = NSAppearance(named: .aqua)
        }
    }

    // MARK: - Path Resolution

    /// Returns the target directory for a download based on format and user preferences.
    func effectiveSavePath(for format: DownloadFormat) -> String {
        if !useSeparateFolders {
            return videoSaveLocation
        }
        return format.isAudio ? audioSaveLocation : videoSaveLocation
    }

    /// Reset folders back to standard factory defaults.
    func resetPathsToDefault() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let workspaceRoot = home.appendingPathComponent("chandrakant_bot")
        let isWorkspace = FileManager.default.fileExists(atPath: workspaceRoot.path)

        if isWorkspace {
            videoSaveLocation = workspaceRoot.appendingPathComponent("outputs/videos").path
            audioSaveLocation = workspaceRoot.appendingPathComponent("outputs/audio").path
        } else {
            videoSaveLocation = home.appendingPathComponent("Downloads/MediaGrab/videos").path
            audioSaveLocation = home.appendingPathComponent("Downloads/MediaGrab/audio").path
        }
    }

    /// Select folder using native NSOpenPanel.
    func chooseFolder(forVideo: Bool) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"
        panel.message = forVideo ? "Select default folder for Video downloads" : "Select default folder for Audio downloads"

        let current = URL(fileURLWithPath: forVideo ? videoSaveLocation : audioSaveLocation)
        if FileManager.default.fileExists(atPath: current.path) {
            panel.directoryURL = current
        }

        if panel.runModal() == .OK, let selectedURL = panel.url {
            if forVideo {
                videoSaveLocation = selectedURL.path
            } else {
                audioSaveLocation = selectedURL.path
            }
        }
    }
}
