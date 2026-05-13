# Unsync Reader

**A free, private, local PDF tool by UnSync Software**

> Your files. Your device. Nobody else.

Unsync Reader is a free desktop PDF reader and editor that runs entirely on your machine. No cloud uploads. No subscriptions. No data leaving your device. Ever.

Built as a legitimate alternative to expensive PDF subscriptions — everything most people actually need from a PDF tool, completely free.

---

## Download

**[⬇ Download for Windows — v1.0.0](https://github.com/unsyncsoftware/unsync-reader/releases/tag/v1.0.0)**

macOS and Linux builds coming soon.

---

## Features

| Feature | Status |
|---|---|
| View PDF with sharp PDFium rendering | ✅ |
| Zoom in/out with toolbar or Ctrl+scroll | ✅ |
| Page navigation | ✅ |
| Merge multiple PDFs into one | ✅ |
| Split PDF into separate pages | ✅ |
| Convert images (JPG/PNG) to PDF | ✅ |
| Convert PDF pages to images (PNG) | ✅ |
| Rotate pages | ✅ |
| Dark theme with page inversion | ✅ |
| Recent files (persists across sessions) | ✅ |
| Annotations — highlight, text, shapes | 🔜 Phase 2 |
| Cryptographic document signing | 🔜 Phase 2 |
| Signature verification (QR audit trail) | 🔜 Phase 2 |

---

## Why Unsync Reader?

Most people pay for Adobe Acrobat or iLovePDF just to merge a few PDFs or convert some images. That's a subscription for a task that takes a computer a fraction of a second.

Unsync Reader gives you the core PDF operations for free — locally, privately, with no account required.

**What makes it different:**
- **100% local** — files never leave your machine
- **No account required** — open and use immediately
- **No telemetry** — no usage tracking, no analytics
- **No subscription** — free forever for core features
- **Open source** — inspect the code yourself

---

## Privacy

Unsync Reader processes all files locally on your device. No files are uploaded to any server. No usage data is collected. The app makes zero network calls during normal operation.

This is the foundation of the UnSync Software philosophy — your data belongs to you.

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| UI Framework | Flutter 3.41 | Cross-platform desktop UI |
| PDF Rendering | pdfrx (PDFium) | Sharp, Chrome-quality rendering |
| PDF Processing | Syncfusion Flutter PDF | Merge, split, rotate, convert |
| State Management | Riverpod | App state |
| File Dialogs | file_picker | Open/save operations |
| Persistence | shared_preferences | Recent files |

---

## Build From Source

**Prerequisites**
- Flutter SDK 3.10+
- Dart 3.0+
- Windows: Visual Studio 2019+ with C++ tools
- macOS: Xcode 14+
- Linux: Standard build tools

**Run**
```bash
git clone https://github.com/unsyncsoftware/unsync-reader.git
cd unsync-reader
flutter pub get
flutter run -d windows   # or macos, linux
```

**Build Release**
```bash
flutter build windows --release
```

**Create Installer (Windows)**

Install [Inno Setup](https://jrsoftware.org/isdl.php) then compile `installer.iss` from the project root.

---

## Project Structure

```
lib/
├── main.dart                   # Entry point, loads recent files
├── app/
│   └── app.dart                # App root + routing
├── theme/
│   └── app_theme.dart          # Dark/light theme tokens
├── models/
│   ├── pdf_document.dart       # Document model
│   └── annotation.dart         # Annotation model (Phase 2)
├── providers/
│   └── pdf_provider.dart       # Riverpod state providers
├── screens/
│   └── home_screen.dart        # Main layout
├── widgets/
│   ├── sidebar.dart            # Left panel + tool list
│   ├── toolbar.dart            # Top toolbar
│   ├── pdf_viewer_area.dart    # PDFium viewer + annotation layer
│   └── drop_zone.dart          # Empty state / welcome screen
└── services/
    ├── pdf_service.dart        # All PDF operations
    └── storage_service.dart    # Recent files persistence
```

---

## Roadmap

**Phase 1 — Local PDF Tool** ✅ Current
- Core viewer and file operations
- Windows installer

**Phase 1.5 — Polish**
- Annotation coordinate mapping fix
- PDF → Images quality settings
- macOS and Linux builds

**Phase 2 — Unsync Sign**
- Cryptographic document signing
- Hash-based verification
- QR code audit trail
- 3 free signs per year
- Premium unlimited tier

**Phase 3 — Unsync Network**
- Integration with the broader UnSync ecosystem
- Unsync Messenger
- Unsync Browser

---

## Part of UnSync Software

Unsync Reader is part of the UnSync Software ecosystem — a suite of privacy-first tools built for people who believe their data belongs to them.

- **Unsync Messenger** — Private P2P messaging
- **Unsync Reader** — Private local PDF tool ← you are here
- **Unsync Browser** — Private browsing (roadmap)

**unsyncsoftware.com** · **unsync.uk**

---

## License

GPL v3 — UnSync Software

Built by an architect in Antipolo, Philippines with AI as a coding partner.
