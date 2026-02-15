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
│   ├── CleansiApp.swift         # App entry point and Preferences UI
│   ├── AppDelegate.swift          # Menu bar setup and app lifecycle
│   ├── ClipboardMonitor.swift     # Clipboard monitoring and URL cleaning
│   ├── Info.plist                 # App metadata and configuration
│   └── Cleansi.entitlements     # App permissions
├── .vscode/                       # VSCode configuration
│   ├── tasks.json                 # Build tasks
│   ├── settings.json              # Editor settings
│   └── extensions.json            # Recommended extensions
├── .github/workflows/             # GitHub Actions CI
└── README.md                      # User documentation
```

### Key Files Explained

| File                     | Purpose                                                                  |
| ------------------------ | ------------------------------------------------------------------------ |
| `CleansiApp.swift`       | App entry point (`@main`) and SwiftUI Preferences view                   |
| `AppDelegate.swift`      | Manages the menu bar icon, menu items, and preferences window            |
| `ClipboardMonitor.swift` | Core logic: Service definitions, clipboard monitoring, and URL cleaning  |
| `Info.plist`             | Configuration file that tells macOS about the app (name, version, etc.) |
| `*.entitlements`         | Declares what system features the app needs access to                    |

---

## Building with Xcode (Recommended)

This is the easiest method for beginners.

### Step 1: Open the Project

1. Navigate to the project folder
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

Look for a clipboard icon in your menu bar at the top of the screen. Click it to see the menu.

### Common Xcode Warnings You Can Ignore

- "The signing certificate is not valid" → See [Code Signing](#code-signing) below
- "Update to recommended settings" → Click "Perform Changes" if prompted

---

## Building from Command Line

For developers who prefer terminal-based workflows.

### Quick Build

```bash
# Navigate to project directory
cd /path/to/Cleansi

# Build the app
xcodebuild -scheme Cleansi \
           -configuration Release \
           -derivedDataPath build

# The built app will be at:
# build/Build/Products/Release/Cleansi.app
```

### Run the Built App

```bash
open build/Build/Products/Release/Cleansi.app
```

### Using VSCode Tasks

If you're using VSCode with the recommended Swift extension, use the built-in tasks:

- **Build Debug** (`Cmd+Shift+B`): Build debug configuration
- **Build Release**: Build release configuration
- **Clean**: Clean build artifacts
- **Lint**: Run SwiftLint
- **Run App**: Build and launch the app

---

## Understanding the Code

### Architecture Overview

The app uses a data-driven architecture where services are defined declaratively:

```swift
// In ClipboardMonitor.swift
struct Service: Identifiable {
    let id: String
    let name: String
    let description: String
    let hosts: Set<String>        // Empty = universal filter
    let trackingParams: Set<String>
    let removeAllParams: Bool
    let defaultEnabled: Bool
}

static let services: [Service] = [
    Service(id: "youtube", name: "YouTube", ...),
    Service(id: "spotify", name: "Spotify", ...),
    // Adding a new service is just adding to this array
]
```

### How Clipboard Monitoring Works

```swift
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

    // Get the text content and clean URLs
    guard let content = pasteboard.string(forType: .string) else { return }
    let (cleanedContent, serviceName) = cleanURLs(in: content)

    // If something changed, update the clipboard
    if cleanedContent != content {
        pasteboard.clearContents()
        pasteboard.setString(cleanedContent, forType: .string)
    }
}
```

### How URL Cleaning Works

The app uses `NSDataDetector` to find URLs and `URLComponents` to parse/modify them:

```swift
private func cleanURLs(in content: String) -> (String, String?) {
    // Find all URLs using NSDataDetector
    let matches = detector.matches(in: content, options: [], range: range)

    for match in matches.reversed() {
        guard let url = match.url else { continue }

        // Find matching service and collect params to remove
        var paramsToRemove = Set<String>()

        if let service = hostServices.first(where: { $0.matches(host: host) }) {
            paramsToRemove.formUnion(service.trackingParams)
        }

        // Universal filters (UTM, fbclid) combine with host-specific
        for service in fallbackServices where serviceEnabled(service.id) {
            paramsToRemove.formUnion(service.trackingParams)
        }

        // Use URLComponents to filter query params
        if let cleaned = cleanURL(url, removing: paramsToRemove) {
            result.replaceSubrange(matchRange, with: cleaned)
        }
    }
    return (result, serviceName)
}
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

- Make sure filtering is enabled (click "Resume Filtering" in the menu)
- Check that the individual services are enabled in Preferences

---

## Modifying the App

### Adding a New Service

Adding a new service is simple - just add to the `services` array in `ClipboardMonitor.swift`:

```swift
Service(
    id: "twitter",
    name: "Twitter/X",
    description: "Removes tracking parameters from Twitter and X URLs.",
    hosts: ["twitter.com", "x.com"],
    trackingParams: ["s", "t", "ref_src"]
)
```

That's it! The UI and filtering logic automatically pick up the new service.

### Adding a Universal Filter

For filters that apply to any URL (like UTM or fbclid), use empty hosts:

```swift
Service(
    id: "mytracker",
    name: "My Tracker",
    description: "Removes my_tracker param from any URL.",
    hosts: [],  // Empty = applies to all URLs
    trackingParams: ["my_tracker"],
    defaultEnabled: false  // Opt-in
)
```

### Changing the Menu Bar Icon

In `AppDelegate.swift`, find:

```swift
button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Cleansi")
```

Change `"doc.on.clipboard"` to any [SF Symbol](https://developer.apple.com/sf-symbols/) name.

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
