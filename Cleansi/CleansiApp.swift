import SwiftUI

struct ServiceToggleRow: View {
	let service: Service
	@State private var isEnabled: Bool

	init(service: Service) {
		self.service = service
		// Initialize from UserDefaults with service's default value
		let storedValue = UserDefaults.standard.object(forKey: "\(service.id)Enabled") as? Bool
		_isEnabled = State(initialValue: storedValue ?? service.defaultEnabled)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Toggle(service.name, isOn: $isEnabled)
				.onChange(of: isEnabled) { newValue in
					UserDefaults.standard.set(newValue, forKey: "\(service.id)Enabled")
				}
			Text(service.description)
				.font(.callout)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
		}
	}
}

struct GeneralToggle: View {
	let title: String
	let description: String
	@Binding var isOn: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Toggle(title, isOn: $isOn)
			Text(description)
				.font(.callout)
				.foregroundStyle(.secondary)
				.fixedSize(horizontal: false, vertical: true)
		}
	}
}

struct PreferencesView: View {
	@AppStorage("notificationsEnabled") private var notificationsEnabled = false
	@AppStorage("cleanUrlsInText") private var cleanUrlsInText = false
	@AppStorage("cleanedCount") private var cleanedCount = 0

	var body: some View {
		Form {
			Section(header: Text("General")) {
				GeneralToggle(
					title: "Clean URLs in Text",
					description: "Also clean links embedded in text, not just standalone URLs.",
					isOn: $cleanUrlsInText
				)

				GeneralToggle(
					title: "Notifications",
					description: "Show a notification when a URL has been cleaned.",
					isOn: $notificationsEnabled
				)
			}

			Section(header: Text("Services")) {
				ForEach(ClipboardMonitor.services) { service in
					ServiceToggleRow(service: service)
				}
			}

			Section(header: Text("Statistics")) {
				HStack {
					Text("URLs Cleaned: \(cleanedCount)")
					Spacer()
					Button("Reset") {
						cleanedCount = 0
					}
				}
			}
		}
		.formStyle(.grouped)
		.frame(width: 400)
		.fixedSize()
	}
}

@main
struct CleansiApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		Settings {
			PreferencesView()
		}
	}
}
