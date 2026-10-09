import SwiftUI
import AppKit

struct URLInputView: View {
    @Bindable var manager: DownloadManager
    @State private var isHovering = false
    @FocusState private var isURLFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            urlField
            formatPicker
            saveLocationRow
            downloadButton
        }
        .padding(20)
        .background(cardBackground)
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
                .foregroundStyle(.white)
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
                .foregroundStyle(Color(red: 0.65, green: 0.75, blue: 1.0))
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
        let focusedGradient = LinearGradient(
            colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
            startPoint: .leading, endPoint: .trailing
        )
        let idleGradient = LinearGradient(
            colors: [.white.opacity(0.12), .white.opacity(0.08)],
            startPoint: .leading, endPoint: .trailing
        )

        RoundedRectangle(cornerRadius: 12)
            .fill(.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isURLFocused ? focusedGradient : idleGradient,
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
            .foregroundStyle(Color(red: 0.45, green: 0.60, blue: 1.0))
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
        let activeGradient = LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.30, blue: 1.0),
                Color(red: 0.30, green: 0.50, blue: 1.0),
            ],
            startPoint: .leading, endPoint: .trailing
        )
        let disabledGradient = LinearGradient(
            colors: [.gray.opacity(0.25), .gray.opacity(0.18)],
            startPoint: .leading, endPoint: .trailing
        )

        return HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
            Text("Download")
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEmpty ? disabledGradient : activeGradient)
        )
        .foregroundStyle(isEmpty ? Color.secondary : Color.white)
    }

    // MARK: - Card background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.07), lineWidth: 1)
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
        let selectedFill = LinearGradient(
            colors: [.purple.opacity(0.28), .blue.opacity(0.22)],
            startPoint: .leading, endPoint: .trailing
        )
        let idleFill = LinearGradient(
            colors: [.white.opacity(0.06), .white.opacity(0.03)],
            startPoint: .leading, endPoint: .trailing
        )

        return HStack(spacing: 5) {
            Image(systemName: format.icon)
                .font(.caption2)
            Text(format.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? selectedFill : idleFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? .purple.opacity(0.45) : .clear,
                            lineWidth: 1
                        )
                )
        )
        .foregroundStyle(isSelected ? .white : .secondary)
    }
}
