import SwiftUI
import AppKit

struct URLInputView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var manager: DownloadManager
    @State private var isHovering = false
    @FocusState private var isURLFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Smart clipboard chip
            if let suggestion = manager.clipboardSuggestion {
                clipboardBanner(suggestion: suggestion)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            urlField
            formatPicker
            saveLocationRow
            downloadButton
        }
        .padding(20)
        .background(cardBackground)
        .onAppear {
            manager.checkClipboard()
        }
    }

    // MARK: - Clipboard Banner

    private func clipboardBanner(suggestion: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard.fill")
                .font(.caption)
                .foregroundStyle(Color(red: 0.60, green: 0.40, blue: 1.0))

            Text("Copied link detected:")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(suggestion)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button("Use Link") {
                withAnimation(.spring(duration: 0.3)) {
                    manager.applyClipboardSuggestion()
                    isURLFocused = true
                }
            }
            .buttonStyle(.plain)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Color.purple.opacity(colorScheme == .dark ? 0.35 : 0.15), in: Capsule())
            .foregroundStyle(Color.purple)

            Button {
                withAnimation(.spring(duration: 0.2)) {
                    manager.clipboardSuggestion = nil
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Theme.controlBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1))
    }

    // MARK: - URL text field

    @ViewBuilder
    private var urlField: some View {
        HStack(spacing: 10) {
            Image(systemName: "link")
                .foregroundStyle(.secondary)
                .font(.body)

            TextField("Paste YouTube, Instagram, or any video URL…", text: $manager.currentURL)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(.primary)
                .focused($isURLFocused)
                .onSubmit { submitIfReady() }

            if !manager.currentURL.isEmpty {
                clearButton
            }

            pasteButton
        }
        .padding(14)
        .background(urlFieldBackground)
        .animation(.easeInOut(duration: 0.2), value: isURLFocused)
    }

    private var pasteButton: some View {
        Button {
            manager.pasteFromClipboard()
            isURLFocused = true
        } label: {
            Image(systemName: "doc.on.clipboard")
                .foregroundStyle(Color.purple)
                .font(.body)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Paste from clipboard (⌘V)")
    }

    private var clearButton: some View {
        Button {
            manager.currentURL = ""
            isURLFocused = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.secondary)
                .font(.body)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Clear text")
        .transition(.scale.combined(with: .opacity))
    }

    @ViewBuilder
    private var urlFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Theme.inputBackground(for: colorScheme))
            .shadow(
                color: colorScheme == .light ? Color.black.opacity(0.04) : Color.clear,
                radius: 3, y: 1
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        Theme.inputBorder(for: colorScheme, isFocused: isURLFocused),
                        lineWidth: isURLFocused ? 1.5 : 1
                    )
            )
    }

    // MARK: - Format picker

    private var formatPicker: some View {
        HStack(spacing: 8) {
            ForEach(DownloadFormat.allCases) { fmt in
                FormatPill(
                    format: fmt,
                    isSelected: manager.selectedFormat == fmt
                ) {
                    withAnimation(.spring(duration: 0.3)) {
                        manager.selectedFormat = fmt
                        manager.updateSavePathForFormat()
                    }
                }
            }
            Spacer()
        }
    }

    // MARK: - Save location

    private var saveLocationRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(prettifyPath(manager.savePath))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button("Browse…") {
                manager.chooseSaveLocation()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(Color.blue)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Download button

    private var downloadButton: some View {
        Button { submitIfReady() } label: {
            downloadButtonLabel
        }
        .buttonStyle(.plain)
        .disabled(manager.currentURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .scaleEffect(isHovering && !manager.currentURL.isEmpty ? 1.015 : 1.0)
        .onHover { h in
            withAnimation(.spring(duration: 0.2)) { isHovering = h }
        }
    }

    private var downloadButtonLabel: some View {
        let isEmpty = manager.currentURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
            Text("Download")
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEmpty ? Theme.buttonDisabledGradient(for: colorScheme) : Theme.buttonGradient)
                .shadow(
                    color: isEmpty ? Color.clear : Color.purple.opacity(0.3),
                    radius: 6, y: 2
                )
        )
        .foregroundStyle(isEmpty ? Color.secondary : Color.white)
    }

    // MARK: - Card background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Theme.cardFill(for: colorScheme))
            .shadow(
                color: Theme.cardShadow(for: colorScheme),
                radius: 8, y: 2
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.cardBorder(for: colorScheme), lineWidth: 1)
            )
    }

    // MARK: - Helpers

    private func submitIfReady() {
        guard !manager.currentURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        withAnimation(.spring(duration: 0.4)) {
            manager.startDownload()
        }
    }

    private func prettifyPath(_ path: String) -> String {
        path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }
}

// MARK: - Format pill button

struct FormatPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let format: DownloadFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            pillLabel
        }
        .buttonStyle(.plain)
    }

    private var pillLabel: some View {
        HStack(spacing: 5) {
            Image(systemName: format.icon)
                .font(.caption2)
            Text(format.rawValue)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? AnyShapeStyle(Theme.pillSelectedFill(for: colorScheme)) : AnyShapeStyle(Theme.pillIdleFill(for: colorScheme)))
                .shadow(color: colorScheme == .light && isSelected ? Color.purple.opacity(0.12) : Color.clear, radius: 2, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.purple.opacity(0.6) : Theme.pillIdleBorder(for: colorScheme),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
        )
        .foregroundStyle(isSelected ? Theme.pillSelectedForeground(for: colorScheme) : Color.secondary)
    }
}
