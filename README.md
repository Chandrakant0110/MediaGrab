# MediaGrab 🎬

A modern, fluid native macOS application for downloading video and audio from Instagram, YouTube, Twitter/X, TikTok, and hundreds of other websites using `yt-dlp` and `ffmpeg`.

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift)
![License MIT](https://img.shields.io/badge/license-MIT-green)

---

## ✨ Features

- **Universal Platform Support**: Download reels, videos, stories, and songs from YouTube, Instagram, X (Twitter), TikTok, Facebook, Reddit, and 1000+ sites.
- **High Quality Formats**:
  - **Video (MP4)**: Remuxed with H.264 + AAC for universal compatibility with macOS Finder, QuickTime Player, iOS, and Final Cut Pro.
  - **Audio (MP3)**: Fast high-bitrate audio extraction.
- **⚡ 1-Click Zero-Config Engines Installer**:
  - No Homebrew or Terminal setup required for end users!
  - MediaGrab automatically downloads and configures official standalone `yt-dlp` and `ffmpeg` binaries with a single click.
- **Persistent Download History**:
  - Filter by video/audio, instant search by title/URL.
  - Quick action buttons: Play file, Reveal in Finder, Copy Link, and Delete with option to remove or keep disk file.
- **Customizable Preferences**:
  - Choose separate or unified download folders for Video vs. Audio.
  - Video quality preferences (Best Available, 1080p, 720p, 480p).
  - Native clipboard link auto-detection (1-click download chip).
  - Completion alerts & audio chimes.
- **Adaptive Light & Dark Theming**:
  - Human Interface Guidelines (HIG) compliant design tokens with elevated cards, soft shadows, and vibrant accents.
  - Built-in Appearance selector: **System**, **Dark**, or **Light**.
- **Real-Time Progress & Console**:
  - Live progress bar, speed, and ETA calculation.
  - Collapsible terminal viewer displaying real-time `yt-dlp` execution logs.

---

## 📥 Installation

### Download pre-built DMG (Recommended)

1. Go to the [Releases](https://github.com/Chandrakant0110/MediaGrab/releases) tab.
2. Download **`MediaGrab-v1.0.0.dmg`** (or `MediaGrab-v1.0.0.zip`).
3. Open the `.dmg` and drag **MediaGrab.app** into your **Applications** folder.

> [!NOTE]  
> Because MediaGrab is an open-source build without an Apple Developer paid certificate, macOS Gatekeeper may ask for confirmation on the very first launch.  
> Either right-click `MediaGrab.app` and choose **Open**, or run this one-line command in Terminal:
> ```bash
> xattr -cr /Applications/MediaGrab.app
> ```

---

## 🛠️ Building from Source

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15+ or Swift Command Line Tools

```bash
# Clone repository
git clone https://github.com/Chandrakant0110/MediaGrab.git
cd MediaGrab

# Run in development mode
swift run

# Or package into standalone MediaGrab.app & DMG
./scripts/package_app.sh
```

Distribution assets will be generated in `./dist/`:
- `MediaGrab.app`
- `MediaGrab-v1.0.0.dmg`
- `MediaGrab-v1.0.0.zip`

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
