import SwiftUI
import AppKit

/// A single row in the downloads list showing thumbnail, title, format badge, progress bar,
/// status details, Finder button, and an expandable real-time yt-dlp log viewer.
struct DownloadProgressView: View {
    let item: DownloadItem
    let manager: DownloadManager

    // MARK: - Derived style

    private var accentColor: Color {
        switch item.status {
        case .waiting:      return .yellow
        case .downloading:  return Color(red: 0.40, green: 0.55, blue: 1.0)
        case .processing:   return .orange
        case .completed:    return .green
        case .failed:       return Color(red: 1.0, green: 0.35, blue: 0.35)
        }
    }

    private var statusIcon: String {
        switch item.status {
        case .waiting:      return "clock.fill"
        case .downloading:  return "arrow.down.circle.fill"
        case .processing:   return "gearshape.2.fill"
        case .completed:    return "checkmark.circle.fill"
        case .failed:       return "xmark.circle.fill"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            mainRow

            // Progress bar (while downloading or processing)
            progressBarView

            // Expandable Real-time Log Console
            if item.isLogExpanded {
                logConsoleView
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Main Row

    private var mainRow: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail preview
            thumbnailView

            // Meta info (title, format, status)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .help(item.title)

                HStack(spacing: 6) {
                    // Format badge
                    Text(item.format.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.18), in: Capsule())
                        .foregroundStyle(accentColor)

                    // Status text
                    Text(item.statusText)
                        .font(.caption)
                        .foregroundStyle(item.status == .waiting ? .secondary : accentColor)
                        .lineLimit(1)

                    if let done = item.completedAt {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(done, format: .relative(presentation: .named))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 8) {
                // Logs toggle button
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        manager.toggleLog(for: item.id)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "terminal")
                            .font(.caption2)
                        Text(item.logs.isEmpty ? "Logs" : "Logs (\(item.logs.count))")
                            .font(.caption2)
                        Image(systemName: item.isLogExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(item.isLogExpanded ? .purple.opacity(0.25) : .white.opacity(0.06))
                    )
                    .foregroundStyle(item.isLogExpanded ? Color(red: 0.7, green: 0.6, blue: 1.0) : .secondary)
                }
                .buttonStyle(.plain)
                .help("View real-time yt-dlp logs")

                // "Show in Finder" for completed downloads
                if case .completed(let path) = item.status {
                    Button {
                        manager.revealInFinder(path: path)
                    } label: {
                        Image(systemName: "folder.fill")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.45, green: 0.75, blue: 1.0))
                            .padding(6)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")
                }
            }
        }
    }

    // MARK: - Thumbnail View

    private var thumbnailView: some View {
        Group {
            if let thumbURLStr = item.thumbnailURL, let thumbURL = URL(string: thumbURLStr) {
                AsyncImage(url: thumbURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 86, height: 52)
                            .clipped()
                            .cornerRadius(8)
                    case .failure, .empty:
                        thumbnailPlaceholder
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.22),
                            Color(red: 0.08, green: 0.08, blue: 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: item.format.icon)
                .font(.body)
                .foregroundStyle(accentColor.opacity(0.7))
        }
        .frame(width: 86, height: 52)
    }

    // MARK: - Progress Bar

    @ViewBuilder
    private var progressBarView: some View {
        switch item.status {
        case .downloading(let progress, _, _):
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.30, blue: 1.0),
                                    Color(red: 0.30, green: 0.55, blue: 1.0),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * progress))
                        .animation(.spring(duration: 0.35), value: progress)
                }
            }
            .frame(height: 5)
        case .processing:
            ProgressView()
                .progressViewStyle(.linear)
                .tint(.orange)
                .frame(height: 4)
        default:
            EmptyView()
        }
    }

    // MARK: - Log Console

    private var logConsoleView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("yt-dlp console logs")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    manager.copyLogs(for: item.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption2)
                    .foregroundStyle(Color(red: 0.65, green: 0.75, blue: 1.0))
                }
                .buttonStyle(.plain)
                .help("Copy logs to clipboard")
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        if item.logs.isEmpty {
                            Text("No output received yet…")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach(Array(item.logs.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(colorForLogLine(line))
                                    .textSelection(.enabled)
                                    .id(index)
                            }
                        }
                    }
                    .padding(8)
                }
                .frame(height: 120)
                .background(Color.black.opacity(0.45))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                )
                .onAppear {
                    if !item.logs.isEmpty {
                        proxy.scrollTo(item.logs.count - 1, anchor: .bottom)
                    }
                }
                .onChange(of: item.logs.count) {
                    if !item.logs.isEmpty {
                        proxy.scrollTo(item.logs.count - 1, anchor: .bottom)
                    }
                }
            }
        }
        .padding(.top, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func colorForLogLine(_ line: String) -> Color {
        if line.contains("ERROR:") || line.hasPrefix("ERROR") {
            return Color(red: 1.0, green: 0.35, blue: 0.35)
        } else if line.contains("WARNING:") || line.hasPrefix("WARNING") {
            return Color(red: 1.0, green: 0.85, blue: 0.35)
        } else if line.contains("[Merger]") || line.contains("[ExtractAudio]") {
            return Color(red: 0.40, green: 0.90, blue: 0.50)
        } else if line.contains("[download]") {
            return Color(red: 0.45, green: 0.75, blue: 1.0)
        } else {
            return Color.white.opacity(0.8)
        }
    }
}
