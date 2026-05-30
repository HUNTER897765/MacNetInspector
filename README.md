# MacNet Inspector 🛜

A powerful macOS network monitoring utility built with SwiftUI.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## Screenshots

> Coming soon

## Features

### Network Tab

- 🌍 **External IP** — your public IP address with one-click copy
- 📡 **IPv4 / IPv6** — local network addresses
- 🖥️ **Active Interface** — Wi-Fi, Ethernet or VPN detection
- 🔒 **VPN Detection** — detects VPN tunnel via default route (no false positives from iCloud/AirDrop)
- 🖧 **DNS Servers** — currently active DNS resolvers
- 🛡️ **DNS Leak Test** — checks if your DNS leaks through ISP when VPN is active
- 📊 **External Network Analysis** — probability-based VPN/hosting detection using multiple data sources
- ⚡ **Response Time** — TCP latency to Google, Cloudflare and Apple (works through VPN)
- 🚀 **Speed Test** — download speed test via Cloudflare

### Connections Tab

- 📋 Terminal command to view all active connections with app names and remote IPs

## How it works

### VPN Detection

MacNet Inspector uses **default route analysis** via `netstat` instead of simply checking for `utun` interfaces. This means:

- ✅ Correctly detects real VPN tunnels
- ✅ No false positives from iCloud Private Relay, AirDrop or Xcode
- ✅ Works with router-level VPN setups

### Router VPN Detection

Uses a probability scoring system (0–100%) based on multiple signals:

- Provider name matches known VPN services (+40%)
- `hosting: true` flag from ip-api.com (+35%)
- Country mismatch with system timezone (+35%)
- Known datacenter ASN (+20%)
- Hosting keywords in provider name (+30%)
- VPN hub country (NL, CH, Panama, Iceland…) (+15%)
- IPv6 unavailable with IPv4 present (+10%)
- Residential ISP detected (-30%)

### DNS Leak Detection

Compares active DNS servers against a known list of privacy DNS providers (Cloudflare, Google, Quad9, etc.) and cross-references with VPN status.

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later

## Installation

1. Clone the repository

```bash
git clone https://github.com/HUNTER897765/MacNetInspector.git
```

1. Open `MacNetInspector.xcodeproj` in Xcode
1. Add color assets to `Assets.xcassets`:

|Name          |Hex      |
|--------------|---------|
|`bgTop`       |`#0D0F14`|
|`bgBottom`    |`#131720`|
|`accentBlue`  |`#4DA6FF`|
|`accentTeal`  |`#2DD4BF`|
|`accentPurple`|`#A78BFA`|
|`accentGreen` |`#34D399`|
|`accentOrange`|`#FB923C`|
|`accentRed`   |`#F87171`|

1. In **Signing & Capabilities → App Sandbox**, enable:
- ✅ Outgoing Connections (Client)
- ✅ Incoming Connections (Server)
1. Press `⌘R` to build and run

## Data Sources

- [ip-api.com](https://ip-api.com) — IP geolocation and hosting detection
- [ipapi.co](https://ipapi.co) — fallback IP info
- [ipwhois.io](https://ipwhois.io) — fallback IP info
- [Cloudflare Speed](https://speed.cloudflare.com) — download speed test
- [ipify.org](https://api.ipify.org) — external IP detection

## Roadmap

- [ ] Menu bar icon with quick status
- [ ] IP change notifications
- [ ] Response time history graph
- [ ] Whois lookup
- [ ] IP blacklist check
- [ ] Export report (PDF/JSON)
- [ ] Mihomo/Clash config support

## Privacy

MacNet Inspector makes network requests only to:

- Public IP detection services (ipify, icanhazip, amazonaws)
- IP geolocation services (ip-api.com, ipwhois.io)
- Cloudflare speed test endpoint

No data is collected or stored outside your device.

## License

MIT License — feel free to use, modify and distribute.

-----

Built with ❤️ using SwiftUI
