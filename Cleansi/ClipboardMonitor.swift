import Cocoa

struct Service {
    let id: String
    let hosts: Set<String>
    let trackingParams: Set<String>

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
    private let onClean: () -> Void

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
        onClean: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.onClean = onClean
        self.urlDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        self.lastChangeCount = pasteboard.changeCount

        // Map service IDs to their enabled closures
        let enabledMap: [String: () -> Bool] = [
            "youtube": youtubeEnabled,
            "spotify": spotifyEnabled,
            "instagram": instagramEnabled
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

        let cleanedContent = cleanURLs(in: content)

        if cleanedContent != content {
            pasteboard.clearContents()
            pasteboard.setString(cleanedContent, forType: .string)
            lastChangeCount = pasteboard.changeCount

            ClipboardMonitor.cleanedCount += 1
            onClean()
        }
    }

    private func cleanURLs(in content: String) -> String {
        guard let detector = urlDetector else { return content }

        var result = content
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
            if let cleaned = cleanURL(url, removing: service.trackingParams) {
                result.replaceSubrange(matchRange, with: cleaned)
            }
        }

        return result
    }

    private func cleanURL(_ url: URL, removing trackingParams: Set<String>) -> String? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }

        guard let queryItems = components.queryItems, !queryItems.isEmpty else {
            return nil // No query params to clean
        }

        let filtered = queryItems.filter { !trackingParams.contains($0.name.lowercased()) }

        // Only return if we actually removed something
        guard filtered.count < queryItems.count else { return nil }

        components.queryItems = filtered.isEmpty ? nil : filtered
        return components.string
    }
}
