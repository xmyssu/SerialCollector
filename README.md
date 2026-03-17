# SerialCollector (iOS)

An iOS app that finds **serial numbers from photos**, asks whether the device is **returning to storage** or **going out to someone** (with a name), and keeps a **history log** you can **copy/export**.

## Features

- **Scan from camera or photo library**
- **OCR text recognition** (Apple Vision)
- **Serial extraction** with a configurable pattern (defaults work for many devices)
- **Check-in / check-out flow**
  - Returning to storage
  - Going out to someone (requires a name)
- **Local history** stored on-device (JSON in app Documents)
- **Export**
  - Copy as CSV to clipboard
  - Share CSV via iOS share sheet

## Requirements

- Xcode 15+ recommended
- iOS 16+ (uses `PhotosPicker`)

## Open & run

1. Open `SerialCollector.xcodeproj` in Xcode.
2. Select an iOS Simulator or your iPhone.
3. Run.

## Notes

- Camera scanning requires a real device or a simulator with camera support.
- OCR accuracy depends on lighting, focus, and text contrast. The app shows multiple candidates and lets you edit before saving.

