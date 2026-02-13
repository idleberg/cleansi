import Cocoa

class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    
    // Closure properties for checking enabled states
    private let isEnabled: () -> Bool
    private let youtubeEnabled: () -> Bool
    private let spotifyEnabled: () -> Bool
    private let instagramEnabled: () -> Bool
    private let onClean: () -> Void
    
    // Statistics
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
        self.youtubeEnabled = youtubeEnabled
        self.spotifyEnabled = spotifyEnabled
        self.instagramEnabled = instagramEnabled
        self.onClean = onClean
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        // Poll clipboard every 0.5 seconds
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
        
        // Only process if clipboard has changed
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // Get clipboard content
        guard let content = pasteboard.string(forType: .string) else { return }
        
        // Try to clean the content
        let cleanedContent = cleanURLs(in: content)
        
        // If content was modified, update clipboard
        if cleanedContent != content {
            pasteboard.clearContents()
            pasteboard.setString(cleanedContent, forType: .string)
            lastChangeCount = pasteboard.changeCount
            
            ClipboardMonitor.cleanedCount += 1
            onClean()
        }
    }
    
    private func cleanURLs(in content: String) -> String {
        var result = content
        
        if youtubeEnabled() {
            result = cleanYouTubeURLs(in: result)
        }
        
        if spotifyEnabled() {
            result = cleanSpotifyURLs(in: result)
        }
        
        if instagramEnabled() {
            result = cleanInstagramURLs(in: result)
        }
        
        return result
    }
    
    // MARK: - YouTube URL Cleaning

    /// Known YouTube tracking parameters to remove
    private static let youtubeTrackingParams: Set<String> = ["si", "feature", "app", "pp", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"]

    private func cleanYouTubeURLs(in content: String) -> String {
        var result = content

        // Pattern to match YouTube URLs (various formats)
        let youtubePatterns = [
            #"https?://(www\.)?youtube\.com/watch\?[^\s]+"#,
            #"https?://youtu\.be/[a-zA-Z0-9_-]+(\?[^\s]*)?"#,
            #"https?://(www\.)?youtube\.com/shorts/[a-zA-Z0-9_-]+(\?[^\s]*)?"#,
            #"https?://(www\.)?youtube\.com/playlist\?[^\s]+"#
        ]

        for pattern in youtubePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                let matches = regex.matches(in: result, options: [], range: range)

                // Process matches in reverse to preserve string indices
                for match in matches.reversed() {
                    if let matchRange = Range(match.range, in: result) {
                        let urlString = String(result[matchRange])
                        if let cleanedURL = cleanYouTubeURL(urlString) {
                            result.replaceSubrange(matchRange, with: cleanedURL)
                        }
                    }
                }
            }
        }

        return result
    }

    /// Cleans a single YouTube URL by removing only tracking parameters
    private func cleanYouTubeURL(_ urlString: String) -> String? {
        guard var components = URLComponents(string: urlString) else { return nil }

        // Filter out tracking parameters, keep legitimate ones (v, t, list, index, etc.)
        if let queryItems = components.queryItems {
            let filteredItems = queryItems.filter { !Self.youtubeTrackingParams.contains($0.name.lowercased()) }
            components.queryItems = filteredItems.isEmpty ? nil : filteredItems
        }

        return components.string
    }
    
    // MARK: - Spotify URL Cleaning

    /// Known Spotify tracking parameters to remove
    private static let spotifyTrackingParams: Set<String> = ["si", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term", "nd", "context"]

    private func cleanSpotifyURLs(in content: String) -> String {
        var result = content

        // Pattern for Spotify URLs
        let spotifyPatterns = [
            #"https?://open\.spotify\.com/(track|album|playlist|artist|episode|show)/[a-zA-Z0-9]+(\?[^\s]*)?"#,
            #"https?://spotify\.link/[a-zA-Z0-9]+(\?[^\s]*)?"#
        ]

        for pattern in spotifyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                let matches = regex.matches(in: result, options: [], range: range)

                for match in matches.reversed() {
                    if let matchRange = Range(match.range, in: result) {
                        let urlString = String(result[matchRange])
                        if let cleanedURL = cleanSpotifyURL(urlString) {
                            result.replaceSubrange(matchRange, with: cleanedURL)
                        }
                    }
                }
            }
        }

        return result
    }

    /// Cleans a single Spotify URL by removing only tracking parameters
    private func cleanSpotifyURL(_ urlString: String) -> String? {
        guard var components = URLComponents(string: urlString) else { return nil }

        if let queryItems = components.queryItems {
            let filteredItems = queryItems.filter { !Self.spotifyTrackingParams.contains($0.name.lowercased()) }
            components.queryItems = filteredItems.isEmpty ? nil : filteredItems
        }

        return components.string
    }
    
    // MARK: - Instagram URL Cleaning

    /// Known Instagram tracking parameters to remove
    private static let instagramTrackingParams: Set<String> = ["igsh", "igshid", "utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"]

    private func cleanInstagramURLs(in content: String) -> String {
        var result = content

        // Pattern for Instagram URLs
        let instagramPatterns = [
            #"https?://(www\.)?instagram\.com/(p|reel|reels|stories|tv)/[a-zA-Z0-9_-]+/?(\?[^\s]*)?"#,
            #"https?://(www\.)?instagram\.com/[a-zA-Z0-9_.]+/?(\?[^\s]*)?"#
        ]

        for pattern in instagramPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(result.startIndex..., in: result)
                let matches = regex.matches(in: result, options: [], range: range)

                for match in matches.reversed() {
                    if let matchRange = Range(match.range, in: result) {
                        let urlString = String(result[matchRange])
                        if let cleanedURL = cleanInstagramURL(urlString) {
                            result.replaceSubrange(matchRange, with: cleanedURL)
                        }
                    }
                }
            }
        }

        return result
    }

    /// Cleans a single Instagram URL by removing only tracking parameters
    private func cleanInstagramURL(_ urlString: String) -> String? {
        guard var components = URLComponents(string: urlString) else { return nil }

        if let queryItems = components.queryItems {
            let filteredItems = queryItems.filter { !Self.instagramTrackingParams.contains($0.name.lowercased()) }
            components.queryItems = filteredItems.isEmpty ? nil : filteredItems
        }

        return components.string
    }
}
