import SwiftUI

struct ContentView: View {
    @State private var manager = DownloadManager()
    @State private var showSettingsPopover = false

    var body: some View {
        ZStack {
            // ── Dark gradient background ──
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.11),
                    Color(red: 0.04, green: 0.04, blue: 0.09),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView(manager: manager, showSettings: $showSettingsPopover)

                // Missing dependency prompt if yt-dlp is not yet installed
                if !manager.dependencyManager.isReady {
                    DependencyNoticeBanner(depManager: manager.dependencyManager)
                }

                ScrollView {
                    VStack(spacing: 20) {
                        URLInputView(manager: manager)

                        if manager.downloads.isEmpty {
                            EmptyStateView()
                        } else {
                            DownloadsSection(manager: manager)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 540, minHeight: 480)
    }
}

// MARK: - Header

struct HeaderView: View {
    let manager: DownloadManager
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.65, green: 0.40, blue: 1.0),
                            Color(red: 0.35, green: 0.55, blue: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 1) {
                Text("MediaGrab")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("Universal Video & Audio Downloader")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Dependency Status Badge
            Button {
                showSettings.toggle()
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(manager.dependencyManager.isReady ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)

                    Text(dependencyBadgeText)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.06), in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings) {
                DependencySettingsPopover(depManager: manager.dependencyManager)
            }
            .help("Click to view dependency status and settings")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.35))
    }

    private var dependencyBadgeText: String {
        let dm = manager.dependencyManager
        if dm.isReady && dm.hasFFmpeg {
            return "yt-dlp + ffmpeg ready"
        } else if dm.isReady {
            return "yt-dlp ready"
        } else {
            return "Dependencies needed"
        }
    }
}

// MARK: - Dependency Notice Banner

struct DependencyNoticeBanner: View {
    @Bindable var depManager: DependencyManager

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("yt-dlp is required to download media")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(depManager.isInstalling
                     ? depManager.installProgressText
                     : "Install the official standalone binary with 1-click or via Homebrew.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if depManager.isInstalling {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button("Install yt-dlp (1-Click)") {
                    Task {
                        await depManager.installYTDLP()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.purple)
                .font(.caption)
                .fontWeight(.medium)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

// MARK: - Dependency Settings Popover

struct DependencySettingsPopover: View {
    @Bindable var depManager: DependencyManager
    @State private var updateResult: String?
    @State private var isUpdating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Environment & Dependencies")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    depManager.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Refresh")
            }

            Divider().background(.white.opacity(0.1))

            // yt-dlp info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(depManager.isReady ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("yt-dlp")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if let ver = depManager.ytdlpVersion {
                        Text(ver)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let path = depManager.ytdlpPath {
                    Text(path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Not found on system")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // ffmpeg info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(depManager.hasFFmpeg ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text("ffmpeg")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if let ver = depManager.ffmpegVersion {
                        Text(ver)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let path = depManager.ffmpegPath {
                    Text(path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Not detected (recommended for audio extraction & merging)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider().background(.white.opacity(0.1))

            // Actions
            HStack(spacing: 10) {
                if !depManager.isReady {
                    Button(depManager.isInstalling ? "Installing…" : "Auto-Install yt-dlp") {
                        Task { await depManager.installYTDLP() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(depManager.isInstalling)
                } else {
                    Button(isUpdating ? "Checking…" : "Update yt-dlp") {
                        isUpdating = true
                        Task {
                            updateResult = await depManager.updateYTDLP()
                            isUpdating = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isUpdating)
                }

                Spacer()
            }

            if let result = updateResult {
                Text(result)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(18)
        .frame(width: 360)
        .background(Color(red: 0.10, green: 0.10, blue: 0.15))
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.to.line")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.4), .blue.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("No downloads yet")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("Paste a URL above to get started")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Downloads section

struct DownloadsSection: View {
    let manager: DownloadManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Downloads")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                if manager.downloads.contains(where: { !$0.status.isActive }) {
                    Button("Clear Done") {
                        withAnimation(.spring(duration: 0.3)) {
                            manager.clearCompleted()
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                }
            }

            ForEach(manager.downloads) { item in
                DownloadProgressView(item: item, manager: manager)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        )
                    )
            }
        }
    }
}
