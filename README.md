# Cleansi for macOS

> [!IMPORT]
>
> This project is 100% vibe-coded, use at your own risk.

A lightweight macOS menu bar application that automatically removes tracking/sharing IDs from YouTube, Spotify, and Instagram URLs when you copy them to your clipboard.

## Features

- 🔒 **Privacy-focused**: Automatically strips tracking parameters from URLs
- 📋 **Real-time monitoring**: Watches your clipboard continuously
- 🎛️ **Toggleable services**: Enable/disable cleaning for each platform individually
- 📊 **Statistics**: Track how many URLs have been cleaned
- 🖥️ **Menu bar app**: Runs silently in your menu bar without cluttering your dock

## Supported Platforms & URL Patterns

### YouTube

| Original URL                                                      | Cleaned URL                               |
| ----------------------------------------------------------------- | ----------------------------------------- |
| `https://youtu.be/dQw4w9WgXcQ?si=abc123`                          | `https://youtu.be/dQw4w9WgXcQ`            |
| `https://youtube.com/watch?v=dQw4w9WgXcQ&si=abc123&feature=share` | `https://youtube.com/watch?v=dQw4w9WgXcQ` |
| `https://youtube.com/shorts/abc123?si=xyz789`                     | `https://youtube.com/shorts/abc123`       |

### Spotify

| Original URL                                                   | Cleaned URL                             |
| -------------------------------------------------------------- | --------------------------------------- |
| `https://open.spotify.com/track/abc123?si=def456`              | `https://open.spotify.com/track/abc123` |
| `https://open.spotify.com/playlist/xyz?si=abc&utm_source=copy` | `https://open.spotify.com/playlist/xyz` |

### Instagram

| Original URL                                  | Cleaned URL                          |
| --------------------------------------------- | ------------------------------------ |
| `https://instagram.com/p/abc123/?igsh=xyz789` | `https://instagram.com/p/abc123/`    |
| `https://instagram.com/reel/abc123/?igsh=xyz` | `https://instagram.com/reel/abc123/` |

---

# Developer Documentation

This guide is written for developers who have never worked with Swift or Xcode before. Follow these steps carefully to build and run the application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Understanding the Project Structure](#understanding-the-project-structure)
3. [Building with Xcode (Recommended)](#building-with-xcode-recommended)
4. [Building from Command Line](#building-from-command-line)
5. [Understanding the Code](#understanding-the-code)
6. [Troubleshooting](#troubleshooting)
7. [Modifying the App](#modifying-the-app)

---

## Prerequisites

### System Requirements

- **macOS 13.0 (Ventura)** or later
- **Xcode 15.0** or later (free from the Mac App Store)

### Installing Xcode

1. Open the **Mac App Store** (click the Apple logo → App Store)
2. Search for "Xcode"
3. Click **Get** and then **Install** (it's a large download, ~12GB)
4. After installation, open Xcode once to accept the license agreement:
   ```bash
   sudo xcodebuild -license accept
   ```

### Installing Command Line Tools (Optional but Recommended)

Open Terminal (Applications → Utilities → Terminal) and run:

```bash
xcode-select --install
```

This installs command-line developer tools including `swift` and `xcodebuild`.

---

## Understanding the Project Structure

```
Cleansi/
├── Cleansi.xcodeproj/           # Xcode project file (like a .sln in Visual Studio)
│   └── project.pbxproj            # Project configuration
├── Cleansi/                     # Source code folder
│   ├── CleansiApp.swift         # App entry point (@main)
│   ├── AppDelegate.swift          # Menu bar setup and UI
│   ├── ClipboardMonitor.swift     # Clipboard monitoring and URL cleaning
│   ├── Info.plist                 # App metadata and configuration
│   └── Cleansi.entitlements     # App permissions
└── README.md                      # This file
```

### Key Files Explained

| File                        | Purpose                                                                         |
| --------------------------- | ------------------------------------------------------------------------------- |
| `CleansiApp.swift`        | The main entry point. Uses `@main` attribute to mark where the app starts.      |
| `AppDelegate.swift`         | Manages the menu bar icon, menu items, and user preferences.                    |
| `ClipboardMonitor.swift`    | Contains the core logic: monitors clipboard and cleans URLs.                    |
| `Info.plist`                | Configuration file that tells macOS about the app (name, version, permissions). |
| `*.entitlements`            | Declares what system features the app needs access to.                          |

---

## Building with Xcode (Recommended)

This is the easiest method for beginners.

### Step 1: Open the Project

1. Navigate to the `Cleansi` folder on your Desktop
2. Double-click `Cleansi.xcodeproj`
3. Xcode will open with the project loaded

### Step 2: Understanding the Xcode Interface

When Xcode opens, you'll see:

- **Navigator (left)**: File browser for your project
- **Editor (center)**: Where you view and edit code
- **Inspector (right)**: Properties panel (can be hidden)
- **Toolbar (top)**: Build and run buttons

### Step 3: Select Your Mac as the Target

1. Look at the top-left of the window, next to the Play (▶) button
2. You should see "Cleansi" and a device selector
3. Make sure "My Mac" is selected (not an iOS simulator)

### Step 4: Build and Run

1. Click the **Play button (▶)** in the top-left, or press `Cmd + R`
2. Xcode will compile the code (takes a few seconds the first time)
3. If successful, the app will launch and appear in your menu bar!

### Step 5: Find the App in Your Menu Bar

Look for a clipboard icon (📋) in your menu bar at the top of the screen. Click it to see the menu.

### Common Xcode Warnings You Can Ignore

- "The signing certificate is not valid" → See [Code Signing](#code-signing) below
- "Update to recommended settings" → Click "Perform Changes" if prompted

---

## Building from Command Line

For developers who prefer terminal-based workflows.

### Quick Build

```bash
# Navigate to project directory
cd ~/Desktop/Cleansi

# Build the app
xcodebuild -project Cleansi.xcodeproj \
           -scheme Cleansi \
           -configuration Release \
           -derivedDataPath build

# The built app will be at:
# build/Build/Products/Release/Cleansi.app
```

### Run the Built App

```bash
# Open the app
open build/Build/Products/Release/Cleansi.app
```

### Build with Verbose Output (for debugging)

```bash
xcodebuild -project Cleansi.xcodeproj \
           -scheme Cleansi \
           -configuration Debug \
           build 2>&1 | tee build.log
```

---

## Understanding the Code

### Swift Basics for Beginners

If you've never seen Swift before, here are the key concepts used in this project:

#### 1. Imports

```swift
import Cocoa    // macOS UI framework (like Windows Forms)
import SwiftUI  // Modern declarative UI framework
```

#### 2. Classes and Structs

```swift
// Classes are reference types (passed by reference)
class ClipboardMonitor { ... }

// Structs are value types (copied when passed)
struct CleansiApp: App { ... }
```

#### 3. Properties

```swift
// Stored property
private var timer: Timer?

// Property with UserDefaults storage (persists between app launches)
@AppStorage("youtubeEnabled") private var youtubeEnabled = true
```

#### 4. Optionals

Swift uses `?` to indicate a value might be nil (null):

```swift
var timer: Timer?     // timer can be nil
timer?.invalidate()   // Only calls invalidate() if timer is not nil
```

#### 5. Closures

Anonymous functions, similar to lambdas or arrow functions:

```swift
// Closure stored in a property
private let onClean: () -> Void

// Closure as a parameter
Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
    // This code runs every 0.5 seconds
}
```

### Core Logic Walkthrough

#### How Clipboard Monitoring Works

```swift
// In ClipboardMonitor.swift

func startMonitoring() {
    // Create a timer that fires every 0.5 seconds
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
        self?.checkClipboard()
    }
}

private func checkClipboard() {
    // Get current clipboard change count
    let currentChangeCount = pasteboard.changeCount

    // If it hasn't changed, do nothing
    guard currentChangeCount != lastChangeCount else { return }

    // Get the text content
    guard let content = pasteboard.string(forType: .string) else { return }

    // Clean the URLs
    let cleanedContent = cleanURLs(in: content)

    // If something changed, update the clipboard
    if cleanedContent != content {
        pasteboard.clearContents()
        pasteboard.setString(cleanedContent, forType: .string)
    }
}
```

#### How URL Cleaning Works

The app uses Regular Expressions (regex) to find and clean URLs:

```swift
// Example: Clean YouTube short URLs
let pattern = #"(https?://)?(youtu\.be/[a-zA-Z0-9_-]+)(\?[^\s]*)?"#
//             |            |                        |
//             |            |                        └── Group 3: Query params (to remove)
//             |            └── Group 2: The core URL (to keep)
//             └── Group 1: Protocol (to keep)

// Replace with just groups 1 and 2, dropping group 3
result = regex.stringByReplacingMatches(..., withTemplate: "$1$2")
```

---

## Code Signing

### For Personal Use (No Signing Required)

If you're building for yourself, you can run the app without code signing:

1. In Xcode, go to **Cleansi** target → **Signing & Capabilities**
2. Set **Team** to "None"
3. The app will run, but may show a security warning on first launch

### Bypassing macOS Security Warning

When you first run an unsigned app, macOS may block it:

1. Go to **System Preferences** → **Privacy & Security**
2. Scroll down and click **"Open Anyway"** next to the Cleansi message

### For Distribution (Signing Required)

To share the app with others, you need an Apple Developer account ($99/year):

1. Get a Developer ID from [developer.apple.com](https://developer.apple.com)
2. In Xcode, select your team in **Signing & Capabilities**
3. Use **Product** → **Archive** to create a distributable build
4. Notarize the app using `xcrun notarytool`

---

## Troubleshooting

### "No such module 'Cocoa'"

- Make sure you're building for macOS, not iOS
- Check that the scheme target is "My Mac"

### App doesn't appear in menu bar

- Look carefully at all menu bar icons (it might be hidden by the notch on newer Macs)
- Try clicking near the center of the menu bar
- Check Activity Monitor to see if the app is running

### "Permission Denied" errors

- The app may need Accessibility permissions
- Go to **System Preferences** → **Privacy & Security** → **Accessibility**
- Add Cleansi to the list

### Build fails with signing errors

- In Xcode, go to **Signing & Capabilities** and change Team to "None"
- Or sign in with your Apple ID in **Xcode** → **Preferences** → **Accounts**

### Clipboard not being monitored

- Make sure "Monitoring Active" is checked in the menu
- Check that the individual services (YouTube, Spotify, Instagram) are enabled

---

## Modifying the App

### Adding a New URL Pattern

1. Open `ClipboardMonitor.swift`
2. Add a new method similar to `cleanYouTubeURLs`:

```swift
private func cleanTwitterURLs(in content: String) -> String {
    var result = content

    // Remove tracking parameters from twitter.com and x.com
    let twitterPattern = #"(https?://)?(www\.)?(twitter\.com|x\.com)/[^\s?]+(\?[^\s]*)?"#

    if let regex = try? NSRegularExpression(pattern: twitterPattern, options: .caseInsensitive) {
        let range = NSRange(result.startIndex..., in: result)
        result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1$2$3")
    }

    return result
}
```

3. Add a toggle in `AppDelegate.swift`:

```swift
@AppStorage("twitterEnabled") private var twitterEnabled = true
```

4. Call your new method in `cleanURLs`:

```swift
if twitterEnabled() {
    result = cleanTwitterURLs(in: result)
}
```

### Changing the Menu Bar Icon

In `AppDelegate.swift`, find:

```swift
button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Cleansi")
```

Change `"doc.on.clipboard"` to any [SF Symbol](https://developer.apple.com/sf-symbols/) name.

### Adding Keyboard Shortcuts

Menu items already have keyboard shortcuts defined. Modify them in `updateMenu()`:

```swift
let youtubeItem = NSMenuItem(
    title: youtubeEnabled ? "  ✓ YouTube" : "  ○ YouTube",
    action: #selector(toggleYouTube),
    keyEquivalent: "y"  // ← Change this character
)
```

---

## Learning Resources

### Swift Language

- [Swift.org - Official Documentation](https://swift.org/documentation/)
- [Swift Playgrounds](https://www.apple.com/swift/playgrounds/) - Interactive learning
- [Hacking with Swift](https://www.hackingwithswift.com/) - Free tutorials

### macOS Development

- [Apple's macOS Documentation](https://developer.apple.com/documentation/macos)
- [AppKit Framework Reference](https://developer.apple.com/documentation/appkit)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

### Xcode

- [Xcode Help](https://help.apple.com/xcode/)
- [WWDC Videos](https://developer.apple.com/videos/) - Free sessions from Apple

---

## License

MIT License - Feel free to use, modify, and distribute this code.

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-platform`)
3. Commit your changes (`git commit -am 'Add support for new platform'`)
4. Push to the branch (`git push origin feature/new-platform`)
5. Create a Pull Request
