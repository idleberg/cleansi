import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private static let appName = "Cleansi"

    private var statusItem: NSStatusItem!
    private var clipboardMonitor: ClipboardMonitor!
    private var preferencesWindow: NSWindow?

    // User preferences stored in UserDefaults
    @AppStorage("youtubeEnabled") private var youtubeEnabled = true
    @AppStorage("spotifyEnabled") private var spotifyEnabled = true
    @AppStorage("instagramEnabled") private var instagramEnabled = true
    @AppStorage("monitoringEnabled") private var monitoringEnabled = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupClipboardMonitor()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: Self.appName)
        }
        
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // Main toggle
        let monitoringItem = NSMenuItem(
            title: monitoringEnabled ? "✓ Monitoring Active" : "○ Monitoring Paused",
            action: #selector(toggleMonitoring),
            keyEquivalent: "m"
        )
        monitoringItem.target = self
        menu.addItem(monitoringItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Service toggles header
        let servicesHeader = NSMenuItem(title: "Services:", action: nil, keyEquivalent: "")
        servicesHeader.isEnabled = false
        menu.addItem(servicesHeader)
        
        // YouTube toggle
        let youtubeItem = NSMenuItem(
            title: youtubeEnabled ? "  ✓ YouTube" : "  ○ YouTube",
            action: #selector(toggleYouTube),
            keyEquivalent: "y"
        )
        youtubeItem.target = self
        menu.addItem(youtubeItem)
        
        // Spotify toggle
        let spotifyItem = NSMenuItem(
            title: spotifyEnabled ? "  ✓ Spotify" : "  ○ Spotify",
            action: #selector(toggleSpotify),
            keyEquivalent: "s"
        )
        spotifyItem.target = self
        menu.addItem(spotifyItem)
        
        // Instagram toggle
        let instagramItem = NSMenuItem(
            title: instagramEnabled ? "  ✓ Instagram" : "  ○ Instagram",
            action: #selector(toggleInstagram),
            keyEquivalent: "i"
        )
        instagramItem.target = self
        menu.addItem(instagramItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Statistics
        let statsItem = NSMenuItem(
            title: "URLs Cleaned: \(ClipboardMonitor.cleanedCount)",
            action: nil,
            keyEquivalent: ""
        )
        statsItem.isEnabled = false
        menu.addItem(statsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit \(Self.appName)", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    private func setupClipboardMonitor() {
        clipboardMonitor = ClipboardMonitor(
            isEnabled: { [weak self] in self?.monitoringEnabled ?? false },
            youtubeEnabled: { [weak self] in self?.youtubeEnabled ?? true },
            spotifyEnabled: { [weak self] in self?.spotifyEnabled ?? true },
            instagramEnabled: { [weak self] in self?.instagramEnabled ?? true },
            onClean: { [weak self] in
                self?.updateMenu()
                self?.showNotification()
            }
        )
        clipboardMonitor.startMonitoring()
    }
    
    private func showNotification() {
        if let button = statusItem.button {
            // Flash the icon to indicate cleaning occurred
            let originalImage = button.image
            button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Cleaned")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                button.image = originalImage
            }
        }
    }
    
    @objc private func toggleMonitoring() {
        monitoringEnabled.toggle()
        updateMenu()
        
        // Update status bar icon
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: monitoringEnabled ? "doc.on.clipboard" : "doc.on.clipboard.fill",
                accessibilityDescription: Self.appName
            )
        }
    }
    
    @objc private func toggleYouTube() {
        youtubeEnabled.toggle()
        updateMenu()
    }
    
    @objc private func toggleSpotify() {
        spotifyEnabled.toggle()
        updateMenu()
    }
    
    @objc private func toggleInstagram() {
        instagramEnabled.toggle()
        updateMenu()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
