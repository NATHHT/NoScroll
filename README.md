# NoScroll - Anti-Doomscrolling iOS App

NoScroll is an iOS application designed to help users stop doomscrolling by providing smart detection and location-based blocking features.

## Features

### Smart Doomscroll Detection
- Auto-starts when opening selected social apps (via Shortcuts integration)
- Asks user intent: "Socializing" or "Browsing" when session starts
- Customizable time limits per app (5-120 minutes)
- Tracks usage patterns over time
- Customizable extensions before hard lock (default: 3)
- Passcode protection to unlock

### Location-Based Blocking
- **Bluetooth mode**: Detects nearby devices (HomePod, Apple TV, etc.)
- **GPS mode**: Geofencing for specific locations
- **Customizable range**: Slider from 1-100 meters
- **Real-time feedback**: Shows live distance during setup
- **Grace period**: Optional (1-10 minutes)
- **Multiple devices/locations** supported

### Safety & Overrides
- Passcode protection (4+ digits)
- Emergency QR code (8-character code)
- Panic button for quick override

## Project Structure

```
NoScroll/
├── NoScroll/
│   ├── Models/
│   │   └── AppModels.swift
│   ├── Views/
│   │   ├── MainTabView.swift
│   │   ├── HomeView.swift
│   │   ├── BlockingView.swift
│   │   ├── SessionsView.swift
│   │   ├── SettingsView.swift
│   │   └── SetupView.swift
│   └── Services/
│       ├── LocationManager.swift
│       └── BluetoothManager.swift
├── Info.plist
└── README.md
```

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Permissions Required

- **Location Access**: For GPS-based blocking
- **Bluetooth Access**: For device detection

## Installation

1. Clone the repository
2. Open `NoScroll.xcodeproj` in Xcode
3. Build and run on a physical device (Bluetooth requires real hardware)

## Usage

1. Launch the app
2. Select an app to monitor
3. Choose your purpose (Socializing or Browsing)
4. Set a time limit
5. Start your session

## Configuration

- Add monitored apps in Settings
- Configure location rules in Blocking tab
- Set passcode and emergency code in Settings

## License

MIT License
