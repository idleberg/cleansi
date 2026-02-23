import Cocoa
import SwiftUI
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
	private static let appName = "Cleansi"
	private static let settingsLabel: String = {
		if #available(macOS 13, *) { return "Settings…" } else { return "Preferences…" }
	}()

	private var statusItem: NSStatusItem!
	private var clipboardMonitor: ClipboardMonitor!
	private var preferencesWindow: NSWindow?
	private var aboutWindow: NSWindow?

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
		observeCleanedCount()
		if notificationsEnabled {
			requestNotificationAuthorization()
		}
	}

	private func requestNotificationAuthorization() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
	}

	private var cleanedCountObserver: NSObjectProtocol?

	private func observeCleanedCount() {
		cleanedCountObserver = NotificationCenter.default.addObserver(
			forName: UserDefaults.didChangeNotification,
			object: nil,
			queue: .main
		) { [weak self] _ in
			self?.updateMenu()
		}
	}

	private func setupStatusItem() {
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

		if let button = statusItem.button {
			button.image = NSImage(
				systemSymbolName: "doc.on.clipboard", accessibilityDescription: Self.appName)
		}

		updateMenu()
	}

	private func updateMenu() {
		let menu = NSMenu()

		// Statistics
		let statsItem = NSMenuItem(
			title: "URLs Cleaned: \(ClipboardMonitor.cleanedCount)",
			action: nil,
			keyEquivalent: ""
		)
		statsItem.isEnabled = false
		menu.addItem(statsItem)

		menu.addItem(NSMenuItem.separator())

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
			title: Self.settingsLabel,
			action: #selector(showPreferences),
			keyEquivalent: ","
		)
		preferencesItem.target = self
		menu.addItem(preferencesItem)

		// About
		let aboutItem = NSMenuItem(
			title: "About",
			action: #selector(showAbout),
			keyEquivalent: ""
		)
		aboutItem.target = self
		menu.addItem(aboutItem)

		menu.addItem(NSMenuItem.separator())

		// Quit
		let quitItem = NSMenuItem(
			title: "Quit \(Self.appName)", action: #selector(quitApp), keyEquivalent: "q")
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
			button.image = NSImage(
				systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Cleaned")

			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
				button.image = originalImage
			}
		}
	}

	private func sendNotification(serviceName: String) {
		guard notificationsEnabled else { return }

		let content = UNMutableNotificationContent()
		content.title = "URL Cleaned"
		content.body = "\(serviceName) URL has been cleaned"

		let request = UNNotificationRequest(
			identifier: UUID().uuidString,
			content: content,
			trigger: nil
		)

		UNUserNotificationCenter.current().add(request)
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

	private func makeWindow<Content: View>(title: String, content: Content) -> NSWindow {
		let hostingView = NSHostingView(rootView: content)
		hostingView.setFrameSize(hostingView.fittingSize)

		let window = NSWindow(
			contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
			styleMask: [.titled, .closable],
			backing: .buffered,
			defer: false
		)
		window.title = title
		window.contentView = hostingView
		window.center()
		window.isReleasedWhenClosed = false
		window.delegate = self
		return window
	}

	private func showWindow(_ window: NSWindow) {
		NSApp.setActivationPolicy(.regular)
		window.makeKeyAndOrderFront(nil)
		NSApp.activate(ignoringOtherApps: true)
	}

	@objc private func showPreferences() {
		if preferencesWindow == nil {
			preferencesWindow = makeWindow(
				title: "\(Self.appName) \(Self.settingsLabel)", content: PreferencesView())
		}
		showWindow(preferencesWindow!)
	}

	func windowWillClose(_ notification: Notification) {
		if let window = notification.object as? NSWindow,
			window == preferencesWindow || window == aboutWindow {
			NSApp.setActivationPolicy(.accessory)
		}
	}

	@objc private func showAbout() {
		if aboutWindow == nil {
			aboutWindow = makeWindow(title: "About", content: AboutView())
			aboutWindow?.initialFirstResponder = nil
		}
		showWindow(aboutWindow!)
		aboutWindow?.makeFirstResponder(nil)
	}

	@objc private func quitApp() {
		NSApplication.shared.terminate(nil)
	}
}
