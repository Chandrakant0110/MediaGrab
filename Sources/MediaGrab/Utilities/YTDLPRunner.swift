import Foundation

/// Wraps yt-dlp CLI execution, streaming progress updates and logs back to the caller.
enum YTDLPRunner {

    // MARK: - Path resolution

    /// Resolves yt-dlp by scanning common install locations (self-contained, no MainActor dependency).
    static var ytdlpPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundledBin = appSupport.appendingPathComponent("MediaGrab/bin/yt-dlp").path

        let candidates = [
            bundledBin,
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/opt/local/bin/yt-dlp",
            "\(home)/.local/bin/yt-dlp",
            "\(home)/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        return candidates.first {
            FileManager.default.isExecutableFile(atPath: $0)
        } ?? candidates[1] // fallback to Homebrew path
    }

    /// Resolves ffmpeg by scanning common install locations (self-contained, no MainActor dependency).
    static var ffmpegPath: String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundledBin = appSupport.appendingPathComponent("MediaGrab/bin/ffmpeg").path

        let candidates = [
            bundledBin,
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/opt/local/bin/ffmpeg",
            "\(home)/.local/bin/ffmpeg",
            "\(home)/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        return candidates.first {
            FileManager.default.isExecutableFile(atPath: $0)
        }
    }

    /// Prepares process environment including MediaGrab bundled bin directory and Homebrew paths.
    static var environmentWithBins: [String: String] {
        var env = ProcessInfo.processInfo.environment
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundledBin = appSupport.appendingPathComponent("MediaGrab/bin").path
        let extra = "\(bundledBin):/opt/homebrew/bin:/usr/local/bin:/opt/local/bin"
        env["PATH"] = extra + ":" + (env["PATH"] ?? "/usr/bin:/bin")
        return env
    }

    // MARK: - Metadata Fetching

    /// Fetches title and thumbnail URL quickly before or during download.
    static func fetchMetadata(url: String) async -> (title: String?, thumbnailURL: String?) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: ytdlpPath)
                process.arguments = [
                    "--no-playlist",
                    "--print", "%(title)s\t%(thumbnail)s",
                    url
                ]

                    process.environment = environmentWithBins

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe() // discard errors

                do {
                    try process.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()

                    if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        let parts = output.components(separatedBy: "\t")
                        let title = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let thumb = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : nil
                        continuation.resume(returning: (title: title?.isEmpty == false ? title : nil,
                                                        thumbnailURL: thumb?.isEmpty == false ? thumb : nil))
                        return
                    }
                } catch {
                    // Ignore errors during metadata fetch
                }
                continuation.resume(returning: (title: nil, thumbnailURL: nil))
            }
        }
    }

    // MARK: - Progress model

    struct ProgressUpdate {
        var rawLine: String
        var percentage: Double?
        var speed: String?
        var eta: String?
        var title: String?
        var finalFilePath: String?
        var processingStage: String?
        var statusLine: String
        var isComplete: Bool = false
        var error: String?
    }

    // MARK: - Download Stream

    /// Starts a yt-dlp process and yields progress and log updates as an async stream.
    static func download(
        url: String,
        format: DownloadFormat,
        outputDir: String,
        quality: VideoQualityPreference = .best
    ) -> AsyncThrowingStream<ProgressUpdate, Error> {
        AsyncThrowingStream { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Ensure output directory exists
                    try FileManager.default.createDirectory(
                        atPath: outputDir,
                        withIntermediateDirectories: true
                    )

                    // Build arguments
                    var arguments = format.arguments(quality: quality)

                    if let ffmpeg = ffmpegPath {
                        arguments += ["--ffmpeg-location", ffmpeg]
                    }

                    arguments += [
                        "-o", "\(outputDir)/%(title).100s [%(id)s].%(ext)s",
                        "--force-overwrites",
                        "--newline",       // one progress line per update
                        "--no-colors",     // strip ANSI escapes
                        "--progress",
                        url
                    ]

                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: ytdlpPath)
                    process.arguments = arguments

                    process.environment = environmentWithBins

                    let stdoutPipe = Pipe()
                    let stderrPipe = Pipe()
                    process.standardOutput = stdoutPipe
                    process.standardError  = stderrPipe

                    let serialQueue = DispatchQueue(label: "com.mediagrab.runner.queue")
                    var stdoutBuffer = ""
                    var stderrBuffer = ""
                    var lastDetectedFile: String?
                    var recordedStderrLines: [String] = []

                    func processLine(_ raw: String, isStderr: Bool) {
                        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !line.isEmpty else { return }

                        if isStderr {
                            recordedStderrLines.append(line)
                        }

                        let update = parseLine(line, isStderr: isStderr)
                        if let filePath = update.finalFilePath {
                            lastDetectedFile = filePath
                        }
                        continuation.yield(update)
                    }

                    // ── Stream stdout ──
                    stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                        let data = handle.availableData
                        guard !data.isEmpty,
                              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else { return }

                        serialQueue.async {
                            stdoutBuffer += text
                            while let idx = stdoutBuffer.firstIndex(of: "\n") {
                                let line = String(stdoutBuffer[stdoutBuffer.startIndex..<idx])
                                stdoutBuffer = String(stdoutBuffer[stdoutBuffer.index(after: idx)...])
                                processLine(line, isStderr: false)
                            }
                        }
                    }

                    // ── Stream stderr ──
                    stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                        let data = handle.availableData
                        guard !data.isEmpty,
                              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else { return }

                        serialQueue.async {
                            stderrBuffer += text
                            while let idx = stderrBuffer.firstIndex(of: "\n") {
                                let line = String(stderrBuffer[stderrBuffer.startIndex..<idx])
                                stderrBuffer = String(stderrBuffer[stderrBuffer.index(after: idx)...])
                                processLine(line, isStderr: true)
                            }
                        }
                    }

                    // ── Cancellation ──
                    continuation.onTermination = { @Sendable _ in
                        if process.isRunning { process.terminate() }
                    }

                    try process.run()
                    process.waitUntilExit()

                    stdoutPipe.fileHandleForReading.readabilityHandler = nil
                    stderrPipe.fileHandleForReading.readabilityHandler = nil

                    // Read any leftover buffered bytes
                    let remainingOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    if let text = String(data: remainingOut, encoding: .utf8) ?? String(data: remainingOut, encoding: .isoLatin1), !text.isEmpty {
                        stdoutBuffer += text
                    }
                    let remainingErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    if let text = String(data: remainingErr, encoding: .utf8) ?? String(data: remainingErr, encoding: .isoLatin1), !text.isEmpty {
                        stderrBuffer += text
                    }

                    // Flush remaining lines
                    serialQueue.sync {
                        if !stdoutBuffer.isEmpty {
                            for line in stdoutBuffer.components(separatedBy: "\n") {
                                processLine(line, isStderr: false)
                            }
                        }
                        if !stderrBuffer.isEmpty {
                            for line in stderrBuffer.components(separatedBy: "\n") {
                                processLine(line, isStderr: true)
                            }
                        }
                    }

                    if process.terminationStatus != 0 {
                        // Find specific ERROR: line if available
                        let errorMsg: String
                        if let errLine = recordedStderrLines.first(where: { $0.contains("ERROR:") }) {
                            errorMsg = errLine
                        } else if let last = recordedStderrLines.last(where: { !$0.isEmpty }) {
                            errorMsg = last
                        } else {
                            errorMsg = "yt-dlp exited with code \(process.terminationStatus)"
                        }

                        continuation.yield(ProgressUpdate(
                            rawLine: errorMsg,
                            statusLine: errorMsg,
                            isComplete: false,
                            error: errorMsg
                        ))
                        continuation.finish(throwing: DownloadError.processError(errorMsg))
                    } else {
                        continuation.yield(ProgressUpdate(
                            rawLine: "Download complete",
                            percentage: 1.0,
                            finalFilePath: lastDetectedFile,
                            statusLine: "Download complete",
                            isComplete: true
                        ))
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Line parser

    /// Extracts progress percentage, speed, ETA, title, or processing status from a line.
    static func parseLine(_ line: String, isStderr: Bool) -> ProgressUpdate {
        var update = ProgressUpdate(rawLine: line, statusLine: line)

        // Error detection
        if isStderr && (line.contains("ERROR:") || line.hasPrefix("ERROR")) {
            update.error = line
            return update
        }

        // Title & Path: [download] Destination: /path/to/Title [id].ext
        if line.contains("[download] Destination: ") {
            let parts = line.components(separatedBy: "Destination: ")
            if parts.count > 1 {
                let path = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                var rawTitle = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
                // If it ends with format id like .f137 or .fdash-1838887640404600v, strip it
                if let range = rawTitle.range(of: #"\.f(dash-)?[\w-]+$"#, options: .regularExpression) {
                    rawTitle.removeSubrange(range)
                }
                update.title = rawTitle

                // If not an intermediate .f... or .part file, track as final
                if !path.contains(".f") && !path.hasSuffix(".part") {
                    update.finalFilePath = path
                }
            }
        }

        // Final merged file: [Merger] Merging formats into "/path/to/Title.mp4"
        if line.contains("[Merger] Merging formats into") {
            update.processingStage = "Merging formats into MP4…"
            if let start = line.range(of: "\""),
               let end = line.range(of: "\"", range: start.upperBound..<line.endIndex) {
                let path = String(line[start.upperBound..<end.lowerBound])
                update.finalFilePath = path
            }
        }

        // Post-processing stages
        if line.contains("[ExtractAudio]") {
            update.processingStage = "Extracting audio…"
            if line.contains("Destination: ") {
                let parts = line.components(separatedBy: "Destination: ")
                if parts.count > 1 {
                    update.finalFilePath = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        } else if line.contains("[VideoConvertor]") || line.contains("[recode]") {
            update.processingStage = "Converting video to MP4…"
        } else if line.contains("[FixupM3u8]") || line.contains("[FixupM4a]") {
            update.processingStage = "Fixing container…"
        } else if line.contains("[ffmpeg]") {
            update.processingStage = "Processing with ffmpeg…"
        }

        // Percentage, Speed, ETA
        // Example: [download]  45.2% of ~123.45MiB at 2.34MiB/s ETA 00:42
        if line.contains("%") {
            if let range = line.range(of: #"\d+\.?\d*%"#, options: .regularExpression) {
                let numStr = line[range].replacingOccurrences(of: "%", with: "")
                if let value = Double(numStr) {
                    update.percentage = min(value / 100.0, 1.0)
                }
            }
            if let range = line.range(of: #"at\s+([~]?[\d\.]+[A-Za-z/]+)"#, options: .regularExpression) {
                let speedPart = line[range].replacingOccurrences(of: "at ", with: "").trimmingCharacters(in: .whitespaces)
                update.speed = speedPart
            }
            if let range = line.range(of: #"ETA\s+([\d:]+)"#, options: .regularExpression) {
                let etaPart = line[range].replacingOccurrences(of: "ETA ", with: "").trimmingCharacters(in: .whitespaces)
                update.eta = etaPart
            }
        }

        // Already downloaded (or overwriting)
        if line.contains("has already been downloaded") {
            update.percentage = 1.0
            update.statusLine = "Already downloaded"
            if let start = line.range(of: "[download] ") {
                let rest = String(line[start.upperBound...])
                let parts = rest.components(separatedBy: " has already been downloaded")
                if let path = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    update.finalFilePath = path
                }
            }
        }

        return update
    }
}

// MARK: - Errors

enum DownloadError: Error, LocalizedError {
    case processError(String)
    case ytdlpNotFound
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .processError(let msg): return msg
        case .ytdlpNotFound:         return "yt-dlp not found. Install via in-app installer or brew install yt-dlp"
        case .invalidURL:            return "Please enter a valid URL"
        }
    }
}
