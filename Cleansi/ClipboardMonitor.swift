import Cocoa

struct Service {
	let id: String
	let hosts: Set<String>
	let trackingParams: Set<String>
	let removeAllParams: Bool

	init(id: String, hosts: Set<String>, trackingParams: Set<String> = [], removeAllParams: Bool = false) {
		self.id = id
		self.hosts = hosts
		self.trackingParams = trackingParams
		self.removeAllParams = removeAllParams
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

	private static let services: [Service] = [
		Service(
			id: "youtube",
			hosts: ["youtube.com", "youtu.be"],
			trackingParams: ["si", "feature", "app", "pp", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"]
		),
		Service(
			id: "spotify",
			hosts: ["spotify.com", "spotify.link"],
			trackingParams: ["si", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "nd", "context"]
		),
		Service(
			id: "instagram",
			hosts: ["instagram.com"],
			trackingParams: ["igsh", "igshid", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"]
		),
		Service(
			id: "amazon",
			hosts: [
				"amazon.com", "amazon.co.uk", "amazon.de", "amazon.fr", "amazon.it", "amazon.es",
				"amazon.ca", "amazon.com.au", "amazon.co.jp", "amazon.in", "amazon.com.br",
				"amazon.com.mx", "amazon.nl", "amazon.pl", "amazon.se", "amazon.sg",
				"amazon.ae", "amazon.sa", "amazon.com.tr", "amazon.eg", "amazon.com.be", "amazon.cn"
			],
			removeAllParams: true
		)
	]

	static var cleanedCount: Int {
		get { UserDefaults.standard.integer(forKey: "cleanedCount") }
		set { UserDefaults.standard.set(newValue, forKey: "cleanedCount") }
	}

	init(
		isEnabled: @escaping () -> Bool,
		youtubeEnabled: @escaping () -> Bool,
		spotifyEnabled: @escaping () -> Bool,
		instagramEnabled: @escaping () -> Bool,
		amazonEnabled: @escaping () -> Bool,
		cleanUrlsInText: @escaping () -> Bool,
		onClean: @escaping (String) -> Void
	) {
		self.isEnabled = isEnabled
		self.cleanUrlsInText = cleanUrlsInText
		self.onClean = onClean
		self.urlDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
		self.lastChangeCount = pasteboard.changeCount

		// Map service IDs to their enabled closures
		let enabledMap: [String: () -> Bool] = [
			"youtube": youtubeEnabled,
			"spotify": spotifyEnabled,
			"instagram": instagramEnabled,
			"amazon": amazonEnabled
		]
		self.serviceEnabled = { enabledMap[$0]?() ?? false }
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

		// Determine what to clean based on mode
		let contentToClean: String
		if cleanUrlsInText() {
			// Clean URLs anywhere in text
			contentToClean = content
		} else {
			// Only clean if entire content is a single URL
			guard let url = URL(string: trimmedContent),
				  url.scheme != nil,
				  url.host != nil else { return }
			contentToClean = trimmedContent
		}

		let (cleanedContent, serviceName) = cleanURLs(in: contentToClean)

		if cleanedContent != contentToClean, let serviceName = serviceName {
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

		// Process in reverse to preserve string indices
		for match in matches.reversed() {
			guard let url = match.url,
					let host = url.host?.lowercased(),
					let matchRange = Range(match.range, in: result) else { continue }

			// Find matching service
			guard let service = Self.services.first(where: { $0.matches(host: host) }),
					serviceEnabled(service.id) else { continue }

			// Clean the URL
			if let cleaned = cleanURL(url, service: service) {
				result.replaceSubrange(matchRange, with: cleaned)
				cleanedServiceName = service.id.capitalized
			}
		}

		return (result, cleanedServiceName)
	}

	private func cleanURL(_ url: URL, service: Service) -> String? {
		guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

		guard let queryItems = components.queryItems, !queryItems.isEmpty else {
			return nil // No query params to clean
		}

		if service.removeAllParams {
			components.queryItems = nil
			return components.string
		}

		let filtered = queryItems.filter { !service.trackingParams.contains($0.name.lowercased()) }

		// Only return if we actually removed something
		guard filtered.count < queryItems.count else { return nil }

		components.queryItems = filtered.isEmpty ? nil : filtered
		return components.string
	}
}
