import SwiftUI
import AppKit

enum MainNavigationTab: String, CaseIterable, Identifiable {
    case download = "Downloader"
    case history  = "History"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .download: return "arrow.down.circle"
        case .history:  return "clock.arrow.circlepath"
        }
    }
}

extension Notification.Name {
    static let toggleSettings = Notification.Name("MediaGrab.toggleSettings")
}

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var manager = DownloadManager()
    @State private var historyManager = HistoryManager.shared
    @State private var selectedTab: MainNavigationTab = .download
    @State private var showSettingsSheet = false
    @State private var showDependencyPopover = false

    var body: some View {
        ZStack {
            // Adaptive gradient background
            Theme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                MainHeaderView(
                    manager: manager,
                    selectedTab: $selectedTab,
                    showSettingsSheet: $showSettingsSheet,
                    showDependencyPopover: $showDependencyPopover
                )

                // Missing dependency prompt if yt-dlp is not yet installed
                if !manager.dependencyManager.isReady {
                    DependencyNoticeBanner(depManager: manager.dependencyManager)
                }

                // Main content
                VStack(spacing: 0) {
                    switch selectedTab {
                    case .download:
                        downloaderContent
                    case .history:
                        historyContent
                    }
                }
            }
        }
        .frame(minWidth: 560, minHeight: 520)
        .preferredColorScheme(manager.settings.themeMode.colorScheme)
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
                .preferredColorScheme(manager.settings.themeMode.colorScheme)
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSettings)) { _ in
            showSettingsSheet.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            manager.checkClipboard()
        }
    }

    // MARK: - Tab: Downloader

    private var downloaderContent: some View {
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

    // MARK: - Tab: History

    private var historyContent: some View {
        HistoryView(manager: manager)
            .padding(20)
    }
}

// MARK: - Main Header

struct MainHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    let manager: DownloadManager
    @State private var historyManager = HistoryManager.shared
    @Binding var selectedTab: MainNavigationTab
    @Binding var showSettingsSheet: Bool
    @Binding var showDependencyPopover: Bool

    var body: some View {
        HStack(spacing: 14) {
            brandingView
            Spacer()
            navigationSegments
            Spacer()
            actionButtons
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.45 : 0.75))
        .overlay(alignment: .bottom) {
            Divider().opacity(colorScheme == .dark ? 0.3 : 0.6)
        }
    }

    private var brandingView: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.accentGradient)

            VStack(alignment: .leading, spacing: 1) {
                Text("MediaGrab")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("Universal Downloader")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var navigationSegments: some View {
        HStack(spacing: 4) {
            ForEach(MainNavigationTab.allCases) { tab in
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        selectedTab = tab
                    }
                } label: {
                    tabButtonLabel(tab: tab)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1)
        )
    }

    private func tabButtonLabel(tab: MainNavigationTab) -> some View {
        let isSelected = selectedTab == tab
        let selectedBg = colorScheme == .dark ? Color.white.opacity(0.14) : Color.white
        let selectedShadow = colorScheme == .light ? Color.black.opacity(0.08) : Color.clear

        return HStack(spacing: 6) {
            Image(systemName: tab.icon)
                .font(.caption2)

            Text(tab.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)

            if tab == .history && !historyManager.items.isEmpty {
                Text("\(historyManager.items.count)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(
                        colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08),
                        in: Capsule()
                    )
            } else if tab == .download && manager.isDownloading {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? selectedBg : Color.clear)
                .shadow(color: selectedShadow, radius: 2, y: 1)
        )
        .foregroundStyle(isSelected ? Color.primary : Color.secondary)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Dependency Status Badge
            Button {
                showDependencyPopover.toggle()
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
                .background(Theme.controlBackground(for: colorScheme), in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDependencyPopover) {
                DependencySettingsPopover(depManager: manager.dependencyManager)
            }
            .help("Environment & dependencies status")

            // Settings Button (Gear)
            Button {
                showSettingsSheet = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body)
                    .foregroundStyle(Color.primary.opacity(0.8))
                    .padding(7)
                    .background(Theme.controlBackground(for: colorScheme), in: Circle())
                    .overlay(Circle().strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Settings & Preferences (⌘,)")
        }
    }

    private var dependencyBadgeText: String {
        let dm = manager.dependencyManager
        if dm.isReady && dm.hasFFmpeg {
            return "Engines ready"
        } else if dm.isReady {
            return "yt-dlp ready"
        } else {
            return "Setup needed"
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
                Text("yt-dlp engine is required to download media")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(depManager.isInstalling
                     ? depManager.installProgressText
                     : "Install the standalone binary with 1-click or via Homebrew.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if depManager.isInstalling {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button("Install Engines (1-Click)") {
                    Task {
                        await depManager.installAllDependencies()
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

// MARK: - Dependency Popover

struct DependencySettingsPopover: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var depManager: DependencyManager
    @State private var updateResult: String?
    @State private var isUpdating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Environment Status")
                    .font(.headline)
                    .foregroundStyle(.primary)
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

            Divider().opacity(0.5)

            // yt-dlp info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Circle()
                        .fill(depManager.isReady ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("yt-dlp")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
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
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Not installed")
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
                        .foregroundStyle(.primary)
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
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Not detected (recommended for audio extraction & merging)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider().opacity(0.5)

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
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.to.line")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .blue.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("No downloads yet")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text("Paste a video or audio URL above to begin")
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
                Text("Downloads Queue")
                    .font(.headline)
                    .foregroundStyle(.primary)

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
