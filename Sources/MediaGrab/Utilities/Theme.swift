import SwiftUI
import AppKit

/// Central design tokens and adaptive styling for both Light and Dark macOS modes.
enum Theme {

    // MARK: - Accent & Action Gradients

    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.65, green: 0.35, blue: 1.0),
            Color(red: 0.35, green: 0.55, blue: 1.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonGradient = LinearGradient(
        colors: [
            Color(red: 0.58, green: 0.28, blue: 1.0),
            Color(red: 0.28, green: 0.48, blue: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func buttonDisabledGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.05)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.91, blue: 0.94),
                    Color(red: 0.88, green: 0.89, blue: 0.92)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    // MARK: - Dynamic Canvas & Surfaces

    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.97, blue: 0.99),
                    Color(red: 0.92, green: 0.93, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Background fill for elevated cards.
    static func cardFill(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.17)
            : Color.white
    }

    /// Border stroke for cards.
    static func cardBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.09)
            : Color.black.opacity(0.08)
    }

    /// Soft elevation shadow for cards.
    static func cardShadow(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.black.opacity(0.35)
            : Color.black.opacity(0.05)
    }

    /// Background for text input fields.
    static func inputBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.06)
            : Color(red: 0.97, green: 0.98, blue: 0.99)
    }

    /// Border for input fields.
    static func inputBorder(for scheme: ColorScheme, isFocused: Bool) -> AnyShapeStyle {
        if isFocused {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.purple.opacity(0.85), Color.blue.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            return AnyShapeStyle(
                scheme == .dark
                    ? Color.white.opacity(0.12)
                    : Color.black.opacity(0.12)
            )
        }
    }

    // MARK: - Format Selection Pills

    static func pillIdleFill(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.06)
            : Color(red: 0.94, green: 0.95, blue: 0.97)
    }

    static func pillIdleBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    static func pillSelectedFill(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [Color.purple.opacity(0.40), Color.blue.opacity(0.32)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return LinearGradient(
                colors: [Color.purple.opacity(0.16), Color.blue.opacity(0.12)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    static func pillSelectedForeground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.78, green: 0.86, blue: 1.0)
            : Color(red: 0.45, green: 0.20, blue: 0.90)
    }

    // MARK: - Controls & Sheets

    static func controlBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.05)
    }

    static func settingsSheetBackground(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.11, blue: 0.15),
                    Color(red: 0.08, green: 0.08, blue: 0.11)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.93, green: 0.94, blue: 0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static func thumbnailPlaceholder(for scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.18, blue: 0.25),
                    Color(red: 0.10, green: 0.10, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.91, blue: 0.94),
                    Color(red: 0.84, green: 0.86, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
