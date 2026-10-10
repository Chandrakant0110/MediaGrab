import Foundation

/// The output format for a download.
enum DownloadFormat: String, CaseIterable, Identifiable, Codable {
    case video    = "Video (MP4)"
    case audioMP3 = "Audio (MP3)"
    case audioM4A = "Audio (M4A)"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .video:    return "MP4"
        case .audioMP3: return "MP3"
        case .audioM4A: return "M4A"
        }
    }

    var icon: String {
        switch self {
        case .video:               return "film"
        case .audioMP3, .audioM4A: return "music.note"
        }
    }

    var isAudio: Bool {
        self == .audioMP3 || self == .audioM4A
    }

    /// Subfolder name matching workspace rules and standard media conventions.
    var defaultSubfolder: String {
        isAudio ? "audio" : "videos"
    }

    /// Default arguments for yt-dlp using best quality.
    var ytdlpArguments: [String] {
        arguments(quality: .best)
    }

    /// Generates yt-dlp arguments taking user quality preference into account.
    func arguments(quality: VideoQualityPreference = .best) -> [String] {
        switch self {
        case .video:
            return [
                "--no-playlist",
                "-S", quality.sortArgument,
                "--merge-output-format", "mp4",
                "--recode-video", "mp4",
                "--windows-filenames"
            ]
        case .audioMP3:
            return [
                "--no-playlist",
                "-x",
                "--audio-format", "mp3",
                "--audio-quality", "0",
                "--windows-filenames"
            ]
        case .audioM4A:
            return [
                "--no-playlist",
                "-x",
                "--audio-format", "m4a",
                "--windows-filenames"
            ]
        }
    }
}
