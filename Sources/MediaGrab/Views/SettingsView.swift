import SwiftUI
import AppKit

enum SettingsTab: String, CaseIterable, Identifiable {
    case general      = "General"
    case folders      = "Folders"
    case quality      = "Quality"
    case system       = "Dependencies"
    case storage      = "Storage & Data"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: return "paintpalette"
        case .folders: return "folder.badge.gearshape"
        case .quality: return "slider.horizontal.3"
        case .system:  return "cpu"
        case .storage: return "externaldrive"
        }
    }
}

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    @State private var depManager = DependencyManager.shared
    @State private var historyManager = HistoryManager.shared

    @State private var selectedTab: SettingsTab = .general
    @State private var showClearConfirm = false
    @State private var updateResult: String?
    @State private var isUpdating = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            settingsHeader

            Divider().opacity(colorScheme == .dark ? 0.3 : 0.6)

            // Tab bar
            tabBar

            Divider().opacity(colorScheme == .dark ? 0.3 : 0.6)

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .general:
                        generalTabContent
                    case .folders:
                        foldersTabContent
                    case .quality:
                        qualityTabContent
                    case .system:
                        systemTabContent
                    case .storage:
                        storageTabContent
                    }
                }
                .padding(24)
            }

            Divider().opacity(colorScheme == .dark ? 0.3 : 0.6)

            // Footer
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Color.purple)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.04))
        }
        .frame(width: 580, height: 530)
        .background(Theme.settingsSheetBackground(for: colorScheme))
    }

    // MARK: - Header

    private var settingsHeader: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.title3)
                .foregroundStyle(Theme.accentGradient)

            Text("Settings & Preferences")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(SettingsTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected
                                  ? (colorScheme == .dark ? Color.white.opacity(0.12) : Color.white)
                                  : Color.clear)
                            .shadow(color: colorScheme == .light && isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 2, y: 1)
                    )
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.black.opacity(0.20) : Color.black.opacity(0.04))
    }

    // MARK: - General Tab

    private var generalTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(title: "Appearance & Theme", subtitle: "Choose whether MediaGrab follows your macOS system appearance or stays in a preferred theme.")

            // Appearance Picker
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ForEach(AppThemeMode.allCases) { mode in
                        let isSelected = settings.themeMode == mode
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                settings.themeMode = mode
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: modeIcon(for: mode))
                                    .font(.caption)
                                Text(mode.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .semibold : .medium)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected
                                          ? (colorScheme == .dark ? Color.purple.opacity(0.35) : Color.purple.opacity(0.12))
                                          : Theme.cardFill(for: colorScheme))
                                    .shadow(color: Theme.cardShadow(for: colorScheme), radius: 2, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(
                                        isSelected ? Color.purple.opacity(0.6) : Theme.cardBorder(for: colorScheme),
                                        lineWidth: isSelected ? 1.5 : 1
                                    )
                            )
                            .foregroundStyle(isSelected ? (colorScheme == .dark ? Color.white : Color.purple) : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().opacity(colorScheme == .dark ? 0.3 : 0.6)

            sectionHeader(title: "Behavior & Notifications", subtitle: "Customize clipboard detection and completion alerts.")

            Toggle(isOn: $settings.autoPasteClipboard) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detect links on Clipboard")
                        .foregroundStyle(.primary)
                        .font(.subheadline)
                    Text("Show 1-click download banner when a media URL is copied")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .tint(Color.purple)

            Toggle(isOn: $settings.playNotificationSound) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Play sound when download finishes")
                        .foregroundStyle(.primary)
                        .font(.subheadline)
                    Text("Plays pleasant macOS chime upon completion")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .tint(Color.purple)

            Toggle(isOn: $settings.sendSystemNotification) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Send system notification on completion")
                        .foregroundStyle(.primary)
                        .font(.subheadline)
                    Text("Shows notification banner even when app is in background")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .tint(Color.purple)
        }
    }

    private func modeIcon(for mode: AppThemeMode) -> String {
        switch mode {
        case .system: return "circle.lefthalf.filled"
        case .dark:   return "moon.fill"
        case .light:  return "sun.max.fill"
        }
    }

    // MARK: - Folders Tab

    private var foldersTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(title: "Default Download Locations", subtitle: "Choose where MediaGrab automatically organizes your downloaded media.")

            // Separate folders toggle
            Toggle(isOn: $settings.useSeparateFolders) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Organize into separate Video & Audio folders")
                        .foregroundStyle(.primary)
                        .font(.subheadline)
                    Text("Keeps audio extractions organized separately from video files")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .tint(Color.purple)

            // Video location
            folderPickerRow(
                title: "Video Save Location",
                icon: "film",
                path: settings.videoSaveLocation,
                onBrowse: { settings.chooseFolder(forVideo: true) },
                onReveal: { revealFolder(settings.videoSaveLocation) }
            )

            // Audio location
            if settings.useSeparateFolders {
                folderPickerRow(
                    title: "Audio Save Location",
                    icon: "music.note",
                    path: settings.audioSaveLocation,
                    onBrowse: { settings.chooseFolder(forVideo: false) },
                    onReveal: { revealFolder(settings.audioSaveLocation) }
                )
            }

            HStack {
                Button("Reset Folders to Default") {
                    withAnimation {
                        settings.resetPathsToDefault()
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .buttonStyle(.link)

                Spacer()
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Quality Tab

    private var qualityTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(title: "Download Quality Preferences", subtitle: "Configure default media formats and video resolution limits.")

            VStack(alignment: .leading, spacing: 8) {
                Text("Default Format on Launch")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Picker("", selection: $settings.defaultFormat) {
                    ForEach(DownloadFormat.allCases) { fmt in
                        Text(fmt.rawValue).tag(fmt)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Maximum Video Quality")
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Picker("", selection: $settings.videoQuality) {
                    ForEach(VideoQualityPreference.allCases) { qual in
                        Text(qual.rawValue).tag(qual)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 240)

                Text("MediaGrab requests the highest stream within this limit and converts to standard H.264 MP4.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Info Card
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.green)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Universal Playability Guarantee")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("All downloads are remuxed with H.264 video and AAC/MP3 audio to ensure 100% compatibility with macOS Finder, QuickTime Player, iOS, and Final Cut Pro without third-party codecs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardFill(for: colorScheme))
                    .shadow(color: Theme.cardShadow(for: colorScheme), radius: 3, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - System / Dependencies Tab

    private var systemTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                sectionHeader(title: "System Engines & Tools", subtitle: "MediaGrab relies on yt-dlp and ffmpeg for media streaming and remuxing.")
                Spacer()
                Button {
                    depManager.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Refresh Status")
            }

            // yt-dlp card
            dependencyCard(
                name: "yt-dlp",
                isInstalled: depManager.isReady,
                version: depManager.ytdlpVersion,
                path: depManager.ytdlpPath,
                actionTitle: depManager.isReady ? "Check for Updates" : "Auto-Install (1-Click)",
                isBusy: depManager.isInstalling || isUpdating
            ) {
                if !depManager.isReady {
                    Task { await depManager.installYTDLP() }
                } else {
                    isUpdating = true
                    Task {
                        updateResult = await depManager.updateYTDLP()
                        isUpdating = false
                    }
                }
            }

            if let res = updateResult {
                Text(res)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            // ffmpeg card
            dependencyCard(
                name: "ffmpeg",
                isInstalled: depManager.hasFFmpeg,
                version: depManager.ffmpegVersion,
                path: depManager.ffmpegPath,
                actionTitle: depManager.hasFFmpeg ? nil : "Auto-Install (1-Click)",
                isBusy: depManager.isInstalling,
                action: depManager.hasFFmpeg ? nil : {
                    Task { await depManager.installFFmpeg() }
                }
            )
        }
    }

    // MARK: - Storage Tab

    private var storageTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(title: "History & Data Management", subtitle: "Inspect persistent download records and storage footprint.")

            HStack(spacing: 16) {
                storageStatCard(title: "Recorded Downloads", value: "\(historyManager.items.count)")
                storageStatCard(title: "Total Tracked Size", value: historyManager.totalFormattedSize)
            }

            Divider().opacity(colorScheme == .dark ? 0.3 : 0.6)

            VStack(alignment: .leading, spacing: 12) {
                Text("Actions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                HStack {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                            Text("Clear All Download History")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.red)
                    .disabled(historyManager.items.isEmpty)
                    .confirmationDialog("Clear Download History?", isPresented: $showClearConfirm) {
                        Button("Clear History Records", role: .destructive) {
                            withAnimation {
                                historyManager.clearAll()
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This will remove all entries from the history log. Downloaded files on your drive will remain safe.")
                    }

                    Spacer()

                    Button {
                        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                        let appDir = appSupport.appendingPathComponent("MediaGrab")
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: appDir.path)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "folder")
                            Text("Open App Data Folder")
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Helper UI Components

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func folderPickerRow(
        title: String,
        icon: String,
        path: String,
        onBrowse: @escaping () -> Void,
        onReveal: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                Text(prettifyPath(path))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.inputBackground(for: colorScheme))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))

                Button("Browse…", action: onBrowse)
                    .buttonStyle(.bordered)

                Button {
                    onReveal()
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .help("Reveal in Finder")
            }
        }
    }

    private func dependencyCard(
        name: String,
        isInstalled: Bool,
        version: String?,
        path: String?,
        actionTitle: String?,
        isBusy: Bool,
        action: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(isInstalled ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)

                Text(name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Spacer()

                if let ver = version {
                    Text(ver)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let p = path {
                Text(p)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text("Not detected on system")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if let title = actionTitle, let act = action {
                HStack {
                    Spacer()
                    Button(action: act) {
                        if isBusy {
                            ProgressView().controlSize(.small)
                        } else {
                            Text(title)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isBusy)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardFill(for: colorScheme))
                .shadow(color: Theme.cardShadow(for: colorScheme), radius: 3, y: 1)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
        )
    }

    private func storageStatCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.cardFill(for: colorScheme))
                .shadow(color: Theme.cardShadow(for: colorScheme), radius: 3, y: 1)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
        )
    }

    private func prettifyPath(_ path: String) -> String {
        path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }

    private func revealFolder(_ path: String) {
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
        }
    }
}
