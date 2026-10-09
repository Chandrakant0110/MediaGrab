import Foundation

/// The lifecycle state of a single download.
enum DownloadStatus: Equatable {
    case waiting
    case downloading(progress: Double, speed: String?, eta: String?)
    case processing(stage: String)
    case completed(filePath: String)
    case failed(error: String)

    var isActive: Bool {
        switch self {
        case .waiting, .downloading, .processing: return true
        default: return false
        }
    }
}

/// One row in the downloads list.
struct DownloadItem: Identifiable {
    let id = UUID()
    let url: String
    let format: DownloadFormat
    let savePath: String
    var title: String = "Fetching info…"
    var thumbnailURL: String? = nil
    var finalFilePath: String? = nil
    var status: DownloadStatus = .waiting
    var logs: [String] = []
    var isLogExpanded: Bool = false
    let startedAt = Date()
    var completedAt: Date? = nil

    var progressValue: Double {
        switch status {
        case .downloading(let p, _, _): return p
        case .completed, .processing:   return 1.0
        default:                         return 0
        }
    }

    var statusText: String {
        switch status {
        case .waiting:
            return "Waiting…"
        case .downloading(let p, let speed, let eta):
            var parts = ["\(Int(p * 100))%"]
            if let s = speed { parts.append(s) }
            if let e = eta { parts.append("ETA \(e)") }
            return parts.joined(separator: " · ")
        case .processing(let stage):
            return stage
        case .completed:
            return "Done"
        case .failed(let e):
            let lines = e.components(separatedBy: "\n")
            if let errLine = lines.first(where: { $0.contains("ERROR:") }) {
                return String(errLine.replacingOccurrences(of: "ERROR: ", with: "").prefix(80))
            }
            let short = lines.last(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? e
            return String(short.prefix(80))
        }
    }
}
