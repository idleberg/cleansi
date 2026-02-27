# Cleansi for macOS

> [!IMPORTANT]
>
> This project is 100% vibe-coded. There are probably a million alternatives to this tool, but personally, I think the contents of the clipboard is too private to share it with any random app. Cleansi works great for my personal needs!

A lightweight macOS menu bar application that automatically removes tracking parameters from URLs when you copy them to your clipboard. Supports YouTube, Spotify, Instagram, Amazon, and universal filters for Facebook Click IDs and Google Analytics UTM parameters.

Supports macOS 13 or later.

## Features

- 🔒 **Privacy-focused**: Automatically strips tracking parameters from URLs
- 📋 **Real-time monitoring**: Watches your clipboard continuously
- 🎛️ **Toggleable services**: Enable/disable cleaning for each platform individually
- 📊 **Statistics**: Track how many URLs have been cleaned
- 🖥️ **Menu bar app**: Runs silently in your menu bar without cluttering your dock

## Installation

> [!WARNING]
>
> If you're like me, you don't want to entrust a third-party app with access to the clipboard. Be reasonable, review the code and [build](#building-from-source) it yourself. Or ignore my advice, be foolish and install it from Homebrew.

```sh
brew install idleberg/asahi/cleansi
```

## Supported Platforms & URL Patterns

### YouTube

| Original URL                                                      | Cleaned URL                               |
| ----------------------------------------------------------------- | ----------------------------------------- |
| `https://youtu.be/dQw4w9WgXcQ?si=abc123`                          | `https://youtu.be/dQw4w9WgXcQ`            |
| `https://youtube.com/watch?v=dQw4w9WgXcQ&si=abc123&feature=share` | `https://youtube.com/watch?v=dQw4w9WgXcQ` |
| `https://youtube.com/shorts/abc123?si=xyz789`                     | `https://youtube.com/shorts/abc123`       |

### Spotify

| Original URL                                                    | Cleaned URL                               |
| --------------------------------------------------------------- | ----------------------------------------- |
| `https://open.spotify.com/track/abc123?si=def456`               | `https://open.spotify.com/track/abc123`   |
| `https://open.spotify.com/playlist/xyz?si=abc&nd=1&context=def` | `https://open.spotify.com/playlist/xyz`   |

### Instagram

| Original URL                                  | Cleaned URL                          |
| --------------------------------------------- | ------------------------------------ |
| `https://instagram.com/p/abc123/?igsh=xyz789` | `https://instagram.com/p/abc123/`    |
| `https://instagram.com/reel/abc123/?igsh=xyz` | `https://instagram.com/reel/abc123/` |

### Amazon

Removes **all** query parameters from Amazon product URLs. Supports all international Amazon domains.

| Original URL                                                           | Cleaned URL                                    |
| ---------------------------------------------------------------------- | ---------------------------------------------- |
| `https://amazon.com/dp/B08N5WRWNW?ref=abc&tag=xyz`                     | `https://amazon.com/dp/B08N5WRWNW`             |
| `https://amazon.de/gp/product/B08N5WRWNW?pf_rd_p=abc&linkCode=xyz`     | `https://amazon.de/gp/product/B08N5WRWNW`      |

### Facebook Click ID (Universal)

Removes `fbclid` parameter from **any URL**. Can be combined with service-specific filters.

| Original URL                                              | Cleaned URL                          |
| --------------------------------------------------------- | ------------------------------------ |
| `https://example.com/page?fbclid=abc123`                  | `https://example.com/page`           |
| `https://open.spotify.com/track/abc?si=def&fbclid=xyz`    | `https://open.spotify.com/track/abc` |

### Google Analytics UTM (Universal)

Removes UTM tracking parameters (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`, `utm_id`) from **any URL**. Can be combined with service-specific filters.

| Original URL                                                       | Cleaned URL                          |
| ------------------------------------------------------------------ | ------------------------------------ |
| `https://example.com/page?utm_source=twitter&utm_medium=social`    | `https://example.com/page`           |
| `https://youtu.be/abc?si=def&utm_campaign=summer`                  | `https://youtu.be/abc`               |


## Building from Source

Want to build your own version or contribute? See the [Developer Documentation](DEVELOPMENT.md) for:

- Prerequisites and setup instructions
- Building with Xcode or command line
- Architecture overview and code walkthrough
- How to add new services
- Troubleshooting common issues

## License

[The MIT License](LICENSE) - Feel free to use, modify, and distribute this code.
