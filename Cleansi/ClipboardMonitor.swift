import Cocoa

struct Service: Identifiable {
	let id: String
	let name: String
	let description: String
	let hosts: Set<String>
	let trackingParams: Set<String>
	let removeAllParams: Bool
	let defaultEnabled: Bool

	init(
		id: String,
		name: String,
		description: String,
		hosts: Set<String>,
		trackingParams: Set<String> = [],
		removeAllParams: Bool = false,
		defaultEnabled: Bool = true
	) {
		self.id = id
		self.name = name
		self.description = description
		self.hosts = hosts
		self.trackingParams = trackingParams
		self.removeAllParams = removeAllParams
		self.defaultEnabled = defaultEnabled
	}

	func matches(host: String) -> Bool {
		hosts.contains { host == $0 || host.hasSuffix(".\($0)") }
	}
}

class ClipboardMonitor {
	private var timer: Timer?
	private var lastChangeCount: Int = 0
	private let pasteboard = NSPasteboard.general
	private let urlDetector: NSDataDetector?

	private let isEnabled: () -> Bool
	private let serviceEnabled: (String) -> Bool
	private let cleanUrlsInText: () -> Bool
	private let onClean: (String) -> Void

	// UTM params defined once - used by "utm" service and can be referenced elsewhere
	static let utmParams: Set<String> = [
		"utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "utm_id",
	]

	// All services defined in one place with full metadata
	static let services: [Service] = [
		Service(
			id: "amazon",
			name: "Amazon",
			description:
				"Removes all query parameters from product URLs.",
			hosts: [
				"amazon.com", "amazon.co.uk", "amazon.de", "amazon.fr", "amazon.it", "amazon.es",
				"amazon.ca", "amazon.com.au", "amazon.co.jp", "amazon.in", "amazon.com.br",
				"amazon.com.mx", "amazon.nl", "amazon.pl", "amazon.se", "amazon.sg",
				"amazon.ae", "amazon.sa", "amazon.com.tr", "amazon.eg", "amazon.com.be", "amazon.cn",
			],
			removeAllParams: true
		),
		Service(
			id: "facebook",
			name: "Facebook",
			description: "Removes Facebook Click Identifiers from any URL.",
			hosts: [],
			trackingParams: ["fbclid"]
		),
		Service(
			id: "utm",
			name: "Google Analytics",
			description: "Removes UTM tracking parameters from any URL.",
			hosts: [],  // Empty hosts means it matches any URL as fallback
			trackingParams: utmParams
		),
		Service(
			id: "instagram",
			name: "Instagram",
			description: "Removes tracking parameters from post, reel, and story URLs.",
			hosts: ["instagram.com"],
			trackingParams: ["igsh", "igshid"]
		),
		Service(
			id: "spotify",
			name: "Spotify",
			description: "Removes tracking parameters from track, album, playlist, and artist URLs.",
			hosts: ["spotify.com", "spotify.link"],
			trackingParams: ["si", "nd", "pt", "context"]
		),
		Service(
			id: "youtube",
			name: "YouTube",
			description: "Removes tracking parameters from video, shorts, and playlist URLs.",
			hosts: ["youtube.com", "youtu.be"],
			trackingParams: ["si", "feature", "app", "pp"]
		),
	]

	static var cleanedCount: Int {
		get { UserDefaults.standard.integer(forKey: "cleanedCount") }
		set { UserDefaults.standard.set(newValue, forKey: "cleanedCount") }
	}

	init(
		isEnabled: @escaping () -> Bool,
		serviceEnabled: @escaping (String) -> Bool,
		cleanUrlsInText: @escaping () -> Bool,
		onClean: @escaping (String) -> Void
	) {
		self.isEnabled = isEnabled
		self.serviceEnabled = serviceEnabled
		self.cleanUrlsInText = cleanUrlsInText
		self.onClean = onClean
		self.urlDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
		self.lastChangeCount = pasteboard.changeCount
	}

	func startMonitoring() {
		timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
			self?.checkClipboard()
		}
	}

	func stopMonitoring() {
		timer?.invalidate()
		timer = nil
	}

	private func checkClipboard() {
		guard isEnabled() else { return }

		let currentChangeCount = pasteboard.changeCount
		guard currentChangeCount != lastChangeCount else { return }
		lastChangeCount = currentChangeCount

		guard let content = pasteboard.string(forType: .string) else { return }

		let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

		// In single-URL mode, only clean if entire content is a URL
		if !cleanUrlsInText() {
			guard let url = URL(string: trimmedContent),
				url.scheme != nil,
				url.host != nil
			else { return }
		}

		let (cleanedContent, serviceName) = cleanURLs(in: content)

		if cleanedContent != content, let serviceName = serviceName {
			pasteboard.clearContents()
			pasteboard.setString(cleanedContent, forType: .string)
			lastChangeCount = pasteboard.changeCount

			ClipboardMonitor.cleanedCount += 1
			onClean(serviceName)
		}
	}

	private func cleanURLs(in content: String) -> (String, String?) {
		guard let detector = urlDetector else { return (content, nil) }

		var result = content
		var cleanedServiceName: String?
		let range = NSRange(content.startIndex..., in: content)
		let matches = detector.matches(in: content, options: [], range: range)

		let hostServices = Self.services.filter { !$0.hosts.isEmpty }
		let fallbackServices = Self.services.filter { $0.hosts.isEmpty }

		// Process in reverse to preserve string indices
		for match in matches.reversed() {
			guard let url = match.url,
				let host = url.host?.lowercased(),
				let matchRange = Range(match.range, in: result)
			else { continue }

			var paramsToRemove = Set<String>()
			var removeAllParams = false
			var matchedServiceName: String?

			// Check host-specific service
			if let service = hostServices.first(where: { $0.matches(host: host) && serviceEnabled($0.id) }
			) {
				if service.removeAllParams {
					removeAllParams = true
				} else {
					paramsToRemove.formUnion(service.trackingParams)
				}
				matchedServiceName = service.name
			}

			// Combine with fallback services (like UTM) unless removeAllParams is set
			if !removeAllParams {
				for service in fallbackServices where serviceEnabled(service.id) {
					paramsToRemove.formUnion(service.trackingParams)
					if matchedServiceName == nil {
						matchedServiceName = service.name
					}
				}
			}

			// Apply cleaning if we have params to remove or removeAll is set
			if removeAllParams || !paramsToRemove.isEmpty {
				if let cleaned = cleanURL(url, removing: paramsToRemove, removeAll: removeAllParams) {
					result.replaceSubrange(matchRange, with: cleaned)
					cleanedServiceName = matchedServiceName
				}
			}
		}

		return (result, cleanedServiceName)
	}

	private func cleanURL(_ url: URL, removing paramsToRemove: Set<String>, removeAll: Bool = false)
		-> String?
	{
		guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			return nil
		}

		guard let queryItems = components.queryItems, !queryItems.isEmpty else {
			return nil
		}

		if removeAll {
			components.queryItems = nil
			return components.string
		}

		let filtered = queryItems.filter { !paramsToRemove.contains($0.name.lowercased()) }

		guard filtered.count < queryItems.count else { return nil }

		components.queryItems = filtered.isEmpty ? nil : filtered
		return components.string
	}
}
