import Foundation

/// The output format for a download.
enum DownloadFormat: String, CaseIterable, Identifiable {
    case video    = "Video"
    case audioMP3 = "MP3"
    case audioM4A = "M4A"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .video:               return "film"
        case .audioMP3, .audioM4A: return "music.note"
        }
    }

    var isAudio: Bool {
        self == .audioMP3 || self == .audioM4A
    }

    /// Subfolder name that matches the workspace download-media skill layout.
    var defaultSubfolder: String {
        isAudio ? "audio" : "videos"
    }

    /// Extra yt-dlp flags for this format.
    /// Video uses standard H.264/AAC MP4 profile compatible with macOS QuickTime & Finder.
    var ytdlpArguments: [String] {
        switch self {
        case .video:
            return [
                "--no-playlist",
                "-S", "vcodec:h264,lang,quality,res,fps,hdr:12,acodec:aac",
                "--merge-output-format", "mp4",
                "--recode-video", "mp4",
                "--windows-filenames"
            ]
        case .audioMP3:
            return [
                "--no-playlist",
                "-x",
                "--audio-format", "mp3",
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
