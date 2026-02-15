import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
	private static let appName = "Cleansi"

	private var statusItem: NSStatusItem!
	private var clipboardMonitor: ClipboardMonitor!
	private var preferencesWindow: NSWindow?

	// User preferences stored in UserDefaults
	@AppStorage("monitoringEnabled") private var monitoringEnabled = true
	@AppStorage("notificationsEnabled") private var notificationsEnabled = false
	@AppStorage("cleanUrlsInText") private var cleanUrlsInText = false

	// Dynamic service enabled lookup - reads from UserDefaults based on service ID
	private func isServiceEnabled(_ serviceId: String) -> Bool {
		let service = ClipboardMonitor.services.first { $0.id == serviceId }
		let defaultValue = service?.defaultEnabled ?? true
		return UserDefaults.standard.object(forKey: "\(serviceId)Enabled") as? Bool ?? defaultValue
	}

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
			title: monitoringEnabled ? "Pause Filtering" : "Resume Filtering",
			action: #selector(toggleMonitoring),
			keyEquivalent: "m"
		)
		monitoringItem.image = NSImage(
			systemSymbolName: monitoringEnabled ? "pause.fill" : "play.fill",
			accessibilityDescription: monitoringEnabled ? "Pause" : "Resume"
		)
		monitoringItem.target = self
		menu.addItem(monitoringItem)

		menu.addItem(NSMenuItem.separator())

		// Preferences
		let preferencesItem = NSMenuItem(
			title: "Preferences...",
			action: #selector(showPreferences),
			keyEquivalent: ","
		)
		preferencesItem.target = self
		menu.addItem(preferencesItem)

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
			serviceEnabled: { [weak self] serviceId in self?.isServiceEnabled(serviceId) ?? false },
			cleanUrlsInText: { [weak self] in self?.cleanUrlsInText ?? false },
			onClean: { [weak self] (serviceName: String) in
				self?.updateMenu()
				self?.showIconFeedback()
				self?.sendNotification(serviceName: serviceName)
			}
		)
		clipboardMonitor.startMonitoring()
	}

	private func showIconFeedback() {
		if let button = statusItem.button {
			// Flash the icon to indicate cleaning occurred
			let originalImage = button.image
			button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Cleaned")

			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
				button.image = originalImage
			}
		}
	}

	private func sendNotification(serviceName: String) {
		guard notificationsEnabled else { return }

		let center = UNUserNotificationCenter.current()
		center.requestAuthorization(options: [.alert]) { granted, _ in
			guard granted else { return }

			let content = UNMutableNotificationContent()
			content.title = "URL Cleaned"
			content.body = "\(serviceName) URL has been cleaned"

			let request = UNNotificationRequest(
				identifier: UUID().uuidString,
				content: content,
				trigger: nil
			)

			center.add(request)
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

	@objc private func showPreferences() {
		if preferencesWindow == nil {
			let hostingView = NSHostingView(rootView: PreferencesView())
			hostingView.setFrameSize(hostingView.fittingSize)

			preferencesWindow = NSWindow(
				contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
				styleMask: [.titled, .closable],
				backing: .buffered,
				defer: false
			)
			preferencesWindow?.title = "\(Self.appName) Preferences"
			preferencesWindow?.contentView = hostingView
			preferencesWindow?.center()
			preferencesWindow?.isReleasedWhenClosed = false
			preferencesWindow?.delegate = self
		}

		NSApp.setActivationPolicy(.regular)
		preferencesWindow?.makeKeyAndOrderFront(nil)
		NSApp.activate(ignoringOtherApps: true)
	}

	func windowWillClose(_ notification: Notification) {
		if notification.object as? NSWindow == preferencesWindow {
			NSApp.setActivationPolicy(.accessory)
		}
	}

	@objc private func quitApp() {
		NSApplication.shared.terminate(nil)
	}
}
