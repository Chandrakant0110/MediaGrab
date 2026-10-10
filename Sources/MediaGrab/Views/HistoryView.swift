import SwiftUI
import AppKit

struct HistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let manager: DownloadManager
    @State private var historyManager = HistoryManager.shared
    @State private var itemToDelete: HistoryItem? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 16) {
            // Search and filter toolbar
            toolbarView

            if historyManager.filteredItems.isEmpty {
                emptyHistoryView
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(historyManager.filteredItems) { item in
                            HistoryRowView(
                                item: item,
                                onReDownload: { url in
                                    manager.currentURL = url
                                },
                                onDelete: {
                                    itemToDelete = item
                                    showDeleteConfirm = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .confirmationDialog(
            "Delete from History",
            isPresented: $showDeleteConfirm
        ) {
            if let item = itemToDelete {
                Button("Remove from History Only", role: .destructive) {
                    withAnimation {
                        historyManager.remove(id: item.id)
                    }
                }
                if item.fileExistsOnDisk {
                    Button("Delete File and Remove from History", role: .destructive) {
                        withAnimation {
                            historyManager.deleteFileAndHistory(item: item)
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let item = itemToDelete {
                Text("Choose whether to remove \"\(item.title)\" from your history list or also delete the downloaded file from disk.")
            }
        }
    }

    // MARK: - Toolbar View

    private var toolbarView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.caption)

                    TextField("Search downloads by title or URL…", text: $historyManager.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    if !historyManager.searchQuery.isEmpty {
                        Button {
                            historyManager.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.inputBackground(for: colorScheme))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))

                // Format filter
                Picker("", selection: $historyManager.selectedFilter) {
                    ForEach(HistoryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            // Summary bar
            HStack {
                Text("\(historyManager.filteredItems.count) items · \(historyManager.totalFormattedSize) total")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if !historyManager.items.isEmpty {
                    Button("Clear History") {
                        withAnimation {
                            historyManager.clearAll()
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Empty State

    private var emptyHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: historyManager.searchQuery.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass")
                .font(.system(size: 36, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.4), .blue.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(historyManager.searchQuery.isEmpty ? "No downloads in history" : "No matches found")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text(historyManager.searchQuery.isEmpty
                 ? "Completed downloads will be saved here automatically."
                 : "Try searching with a different keyword.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - History Row View

struct HistoryRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let item: HistoryItem
    let onReDownload: (String) -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            thumbnailView

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .help(item.title)

                HStack(spacing: 6) {
                    // Format badge
                    Text(item.format.shortName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.format.isAudio
                                    ? Color.purple.opacity(colorScheme == .dark ? 0.25 : 0.12)
                                    : Color.blue.opacity(colorScheme == .dark ? 0.25 : 0.12),
                                    in: Capsule())
                        .foregroundStyle(item.format.isAudio ? Color.purple : Color.blue)

                    Text(item.formattedSize)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(item.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    // File availability dot
                    HStack(spacing: 3) {
                        Circle()
                            .fill(item.fileExistsOnDisk ? Color.green : Color.orange)
                            .frame(width: 5, height: 5)
                        Text(item.fileExistsOnDisk ? "On Disk" : "Moved")
                            .font(.system(size: 10))
                            .foregroundStyle(item.fileExistsOnDisk ? Color.green : Color.orange)
                    }
                }
            }

            Spacer()

            // Quick actions
            HStack(spacing: 6) {
                if item.fileExistsOnDisk {
                    Button {
                        HistoryManager.shared.openFile(item: item)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.40, green: 0.60, blue: 1.0))
                    }
                    .buttonStyle(.plain)
                    .help("Play / Open File")

                    Button {
                        HistoryManager.shared.revealInFinder(item: item)
                    } label: {
                        Image(systemName: "folder.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Theme.controlBackground(for: colorScheme), in: Circle())
                            .overlay(Circle().strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")
                }

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.url, forType: .string)
                } label: {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .background(Theme.controlBackground(for: colorScheme), in: Circle())
                        .overlay(Circle().strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Copy Video URL")

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.85))
                        .padding(6)
                        .background(Theme.controlBackground(for: colorScheme), in: Circle())
                        .overlay(Circle().strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Delete Item")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovering
                      ? (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.03))
                      : Theme.cardFill(for: colorScheme))
                .shadow(color: Theme.cardShadow(for: colorScheme), radius: 3, y: 1)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
        )
        .onHover { h in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = h
            }
        }
    }

    private var thumbnailView: some View {
        Group {
            if let thumb = item.thumbnailURL, let url = URL(string: thumb) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 76, height: 46)
                            .clipped()
                            .cornerRadius(6)
                    case .failure, .empty:
                        fallbackThumbnail
                    @unknown default:
                        fallbackThumbnail
                    }
                }
            } else {
                fallbackThumbnail
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
    }

    private var fallbackThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.thumbnailPlaceholder(for: colorScheme))
            Image(systemName: item.format.icon)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 76, height: 46)
    }
}
