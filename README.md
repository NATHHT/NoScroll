# NoScroll - Anti-Doomscrolling iOS App

NoScroll is an iOS application designed to help users stop doomscrolling by providing smart detection and location-based blocking features.

## Features

### 🎯 Smart Doomscroll Detection
- **Auto-start** when opening selected social apps (via Shortcuts integration)
- **Purpose selection**: Choose "Socializing" or "Browsing" when session starts
- **Customizable time limits** per app (5-120 minutes)
- **Usage tracking** over time
- **Extensions**: Get 3 extensions before hard lock (configurable)
- **Passcode protection** to unlock

### 📍 Location-Based Blocking
- **Bluetooth mode**: Detects nearby devices (HomePod, Apple TV, etc.)
- **GPS mode**: Geofencing for specific locations
- **Customizable range**: Slider from 1-100 meters
- **Real-time feedback**: Shows live distance during setup
- **Grace period**: Optional (1-10 minutes)
- **Multiple devices/locations** supported

### 🔒 Safety & Overrides
- **Passcode protection** (4+ digits)
- **Emergency QR code** (8-character code)
- **Panic button** for quick override

## Project Structure

```
NoScroll/
├── NoScroll/
│   ├── Base.lproj/
│   │   └── LaunchScreen.storyboard
│   ├── Models/
│   │   └── AppModels.swift          # Data models and state
│   ├── Views/
│   │   ├── MainTabView.swift        # Tab navigation
│   │   ├── HomeView.swift           # Home screen with app grid
│   │   ├── BlockingView.swift       # Location/Bluetooth rules
│   │   ├── SessionsView.swift       # Usage history
│   │   ├── SettingsView.swift        # Configuration
│   │   └── SetupView.swift          # Initial setup
│   └── Services/
│       ├── LocationManager.swift    # GPS geofencing
│       └── BluetoothManager.swift   # Bluetooth detection
├── Info.plist                         # App permissions
├── Package.swift                      # Swift Package Manager
└── README.md
```

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Permissions Required

- **Location Access**: For GPS-based blocking (When In Use)
- **Bluetooth Access**: For device detection

## Installation

### Option 1: Open in Xcode

1. Clone this repository:
   ```bash
   git clone https://github.com/NATHHT/NoScroll.git
   cd NoScroll
   ```

2. Open the project in Xcode:
   - Launch Xcode
   - Select "File > Open"
   - Navigate to the `NoScroll` folder and select it
   - Xcode will automatically detect the Swift Package

3. Build and run:
   - Select your device or simulator
   - Click the Run button (▶)
   - **Note**: Bluetooth features require a physical device

### Option 2: Swift Package Manager

1. In Xcode, create a new iOS project
2. Go to "File > Add Package Dependencies..."
3. Enter the repository URL: `https://github.com/NATHHT/NoScroll.git`
4. Add the package to your project

## Usage

### Starting a Session

1. Launch NoScroll
2. Tap on an app icon (Instagram, TikTok, etc.)
3. Choose your purpose:
   - **Socializing**: For conversations and interactions
   - **Browsing**: For casual scrolling
4. The session starts automatically
5. When time is up, you'll be locked out

### Extending a Session

- You can extend your session up to 3 times (configurable in Settings)
- After max extensions, the app locks
- Enter your passcode to unlock

### Location-Based Blocking

1. Go to the **Blocking** tab
2. Tap "Add GPS Rule" or "Add Bluetooth Rule"
3. For GPS: Set a location and range
4. For Bluetooth: Select a device to monitor
5. When you're near the location/device, apps will be blocked

### Emergency Override

If you forget your passcode:
1. On the locked screen, tap "Emergency Override"
2. Enter the emergency code shown in Settings
3. The app will unlock

## Configuration

### Settings

- **Max Extensions**: Set how many times you can extend a session (1-10)
- **Grace Period**: Optional delay before blocking starts (1-10 minutes)
- **Passcode**: Change your unlock passcode
- **Emergency Code**: View your emergency override code
- **Monitored Apps**: Enable/disable apps and set time limits

### Adding Custom Apps

1. Go to **Setup** tab
2. Tap "Apps"
3. Tap "Add Custom App"
4. Enter the app name and bundle ID
5. Set a default time limit
6. Choose an icon

## Architecture

### Models
- `AppData`: Main observable object managing app state
- `MonitoredApp`: Apps to track with time limits
- `DoomscrollSession`: Active session tracking
- `LocationRule`: GPS and Bluetooth blocking rules
- `BlockSettings`: Configuration for blocking behavior
- `UsageRecord`: History of app usage

### Services
- `LocationManager`: Handles GPS tracking and geofencing
- `BluetoothManager`: Scans for and monitors Bluetooth devices

### Views
- Built with SwiftUI
- Uses MVVM pattern
- EnvironmentObject for state sharing

## Tips

- **For best results**: Use on a physical iPhone (Bluetooth doesn't work on simulator)
- **Set realistic limits**: Start with shorter limits and adjust as needed
- **Use location blocking**: Set up rules for places where you want to focus (work, home, etc.)
- **Emergency code**: Write it down and keep it safe

## Troubleshooting

### Bluetooth not working?
- Make sure Bluetooth is enabled on your device
- Ensure the device you're looking for is discoverable
- Use a physical iPhone (simulator doesn't support Bluetooth)

### Location not working?
- Check that Location Services are enabled
- Grant "When In Use" permission to NoScroll
- Make sure you're in an area with GPS signal

### App not blocking?
- Check that the app is enabled in Monitored Apps
- Verify your session hasn't ended
- Ensure you haven't exceeded max extensions

## License

MIT License

## Contributing

Contributions are welcome! Please open an issue or pull request.
