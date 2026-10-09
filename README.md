# MediaGrab 🎬

A native macOS application for downloading videos and audio from YouTube, Instagram, and hundreds of other platforms using `yt-dlp` and `ffmpeg`.

![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![License MIT](https://img.shields.io/badge/license-MIT-green)

---

## ✨ Features

- **Universal Platform Support**: Download reels, videos, and music from YouTube, Instagram, Twitter/X, TikTok, and more.
- **Video & Audio Modes**:
  - High quality MP4 (encoded with H.264 + AAC for universal compatibility with QuickTime and macOS).
  - High quality MP3 audio extraction.
- **Native SwiftUI Design**: Clean, fluid macOS interface with system vibrancy, dark mode support, and micro-interactions.
- **Real-Time Progress & Logs**: Live percentage, download speed, ETA indicators, and collapsible terminal logs.
- **Embedded Dependency Resolution**:
  - Automatically detects system installations (`/opt/homebrew/bin`, `/usr/local/bin`, etc.).
  - Includes a 1-click yt-dlp installer downloading directly to Application Support if missing.
- **Finder Integration**: One-click "Show in Finder" to instantly open downloaded files.

---

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 (Ventura) or later
- [Xcode 15+](https://developer.apple.com/xcode/) or Swift Command Line Tools
- `yt-dlp` and `ffmpeg` (MediaGrab will automatically look in standard Homebrew paths or offer to download yt-dlp)

```bash
brew install yt-dlp ffmpeg
```

### Building & Running

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd MediaGrab
   ```

2. Build and run via Swift Package Manager:
   ```bash
   swift run
   ```

Or build an optimized release binary:
   ```bash
   swift build -c release
   ```

---

## 🗺️ Roadmap

- [ ] **Custom Settings Panel**: User-configurable default download directories for audio and video.
- [ ] **Persistent Download History**: State-backed download history with re-download and file quick-access.
- [ ] **Clipboard Auto-Detect**: Automatically populate input when a valid media URL is copied.
- [ ] **Quality Selector**: Choose between 1080p, 4K, or lowest file size before downloading.

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
