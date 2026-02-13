import SwiftUI

struct ServiceToggle: View {
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
	@AppStorage("youtubeEnabled") private var youtubeEnabled = true
	@AppStorage("spotifyEnabled") private var spotifyEnabled = true
	@AppStorage("instagramEnabled") private var instagramEnabled = true
	@AppStorage("amazonEnabled") private var amazonEnabled = true

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			ServiceToggle(
				title: "YouTube",
				description: "Removes tracking parameters (si, feature, utm_*) from video, shorts, and playlist URLs.",
				isOn: $youtubeEnabled
			)

			ServiceToggle(
				title: "Spotify",
				description: "Removes tracking parameters (si, nd, context, utm_*) from track, album, playlist, and artist URLs.",
				isOn: $spotifyEnabled
			)

			ServiceToggle(
				title: "Instagram",
				description: "Removes tracking parameters (igsh, igshid, utm_*) from post, reel, and story URLs.",
				isOn: $instagramEnabled
			)

			ServiceToggle(
				title: "Amazon",
				description: "Removes all query parameters from product URLs. Supports all international Amazon domains.",
				isOn: $amazonEnabled
			)
		}
		.padding(20)
		.frame(width: 380)
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
