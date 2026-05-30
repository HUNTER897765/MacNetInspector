import SwiftUI

struct ContentView: View {
    @StateObject private var monitor = NetworkMonitor()
    @State private var isHoveringRefresh = false
    @State private var selectedTab: AppTab = .network

    enum AppTab { case network, connections }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("bgTop"), Color("bgBottom")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                // Tab picker
                HStack(spacing: 8) {
                    TabButton(title: "Network", icon: "antenna.radiowaves.left.and.right", isSelected: selectedTab == .network) {
                        selectedTab = .network
                    }
                    TabButton(title: "Connections", icon: "list.bullet.rectangle", isSelected: selectedTab == .connections) {
                        selectedTab = .connections
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                if selectedTab == .network {
                    NetworkTabView(monitor: monitor)
                } else {
                    ConnectionsTabView(monitor: monitor)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("accentBlue").opacity(0.2))
                        .frame(width: 38, height: 38)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color("accentBlue"))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("MacNet Inspector")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(lastUpdatedText)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(monitor.info.externalIP == "No connection" ? Color.red : Color.green)
                    .frame(width: 7, height: 7)
                    .shadow(color: monitor.info.externalIP == "No connection" ? .red : .green, radius: 4)
                Text(monitor.info.externalIP == "No connection" ? "Offline" : "Online")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.07))
            .clipShape(Capsule())

            Button(action: { Task { await monitor.refresh() } }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHoveringRefresh ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                    if monitor.info.isLoading {
                        ProgressView().scaleEffect(0.6).tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringRefresh = $0 }
        }
    }

    private var lastUpdatedText: String {
        guard let date = monitor.info.lastUpdated else { return "Never updated" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return "Updated \(f.localizedString(for: date, relativeTo: Date()))"
    }
}

// MARK: - TabButton

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.45))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color("accentBlue").opacity(0.3) : Color.white.opacity(isHovering ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color("accentBlue").opacity(0.5) : Color.clear, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - NetworkTabView

struct NetworkTabView: View {
    @ObservedObject var monitor: NetworkMonitor

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                InfoCard(
                    icon: "network",
                    title: "External IP",
                    value: monitor.info.externalIP,
                    isLoading: monitor.info.isLoading,
                    accent: Color("accentBlue")
                )
                HStack(spacing: 14) {
                    InfoCard(
                        icon: "4.circle",
                        title: "IPv4 (Local)",
                        value: monitor.info.ipv4,
                        isLoading: monitor.info.isLoading,
                        accent: Color("accentOrange")
                    )
                    InfoCard(
                        icon: "6.circle",
                        title: "IPv6 (Local)",
                        value: monitor.info.ipv6,
                        isLoading: monitor.info.isLoading,
                        accent: Color("accentPurple"),
                        valueFont: .system(size: 11, weight: .medium, design: .monospaced)
                    )
                }
                HStack(spacing: 14) {
                    InterfaceCard(info: monitor.info)
                    VPNCard(vpnActive: monitor.info.vpnActive, isLoading: monitor.info.isLoading)
                }
                HStack(spacing: 14) {
                    DNSCard(servers: monitor.info.dnsServers, isLoading: monitor.info.isLoading)
                    DNSLeakCard(result: monitor.dnsLeak)
                }
                IPInfoCard(ipInfo: monitor.ipInfo)
                PingCard(results: monitor.pingResults, isLoading: monitor.info.isLoading)
                SpeedTestCard(speedTest: monitor.speedTest) {
                    Task { await monitor.runSpeedTest() }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - ConnectionsTabView

struct ConnectionsTabView: View {
    @ObservedObject var monitor: NetworkMonitor
    @State private var copied = false

    let command = "lsof -i -n -P | grep ESTABLISHED | grep -v fe80 | grep -v '127.0.0.1'"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("accentOrange").opacity(0.15))
                                .frame(width: 34, height: 34)
                            Image(systemName: "info.circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("accentOrange"))
                        }
                        Text("About Connections")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                    Text("macOS sandbox restricts apps from monitoring other apps' network connections. To see active connections, use Terminal with the command below.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground(isHovering: false))

                // Command card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("accentPurple").opacity(0.15))
                                .frame(width: 34, height: 34)
                            Image(systemName: "terminal")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("accentPurple"))
                        }
                        Text("Terminal Command")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                            .textCase(.uppercase)
                            .tracking(0.8)
                        Spacer()
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(command, forType: .string)
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 10))
                                Text(copied ? "Copied!" : "Copy")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(copied ? Color("accentGreen") : .white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Text(command)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color("accentTeal"))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground(isHovering: false))

                // Steps card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("accentGreen").opacity(0.15))
                                .frame(width: 34, height: 34)
                            Image(systemName: "list.number")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("accentGreen"))
                        }
                        Text("How to use")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.45))
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        StepRow(number: "1", text: "Open Terminal (⌘ + Space → type Terminal)")
                        StepRow(number: "2", text: "Paste the command above and press Enter")
                        StepRow(number: "3", text: "You'll see all active connections with app names, remote IPs and ports")
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground(isHovering: false))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

struct StepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Color("accentGreen").opacity(0.3))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - ConnectionRow

struct ConnectionRow: View {
    let connection: ActiveConnection
    @State private var isHovering = false

    var body: some View {
        HStack {
            Text(connection.appName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)

            Text(connection.remoteIP)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(Color("accentTeal"))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(connection.portLabel)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
                .lineLimit(1)
                .frame(width: 130, alignment: .leading)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 9)
        .background(isHovering ? Color.white.opacity(0.05) : Color.clear)
        .onHover { isHovering = $0 }
    }
}

// MARK: - InfoCard

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let isLoading: Bool
    let accent: Color
    var valueFont: Font = .system(size: 14, weight: .semibold, design: .monospaced)
    @State private var isHovering = false
    @State private var copied = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.8)
                if isLoading && (value == "—" || value == "Not available") {
                    LoadingDots()
                } else {
                    Text(copied ? "Copied!" : value)
                        .font(valueFont)
                        .foregroundColor(copied ? accent : (value == "Not available" ? .white.opacity(0.3) : .white))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            Spacer()

            // Copy icon on hover
            if isHovering && value != "—" && value != "Not available" {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundColor(accent.opacity(0.7))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(cardBackground(isHovering: isHovering))
        .onHover { isHovering = $0 }
        .onTapGesture {
            guard value != "—" && value != "Not available" else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
        }
    }
}

// MARK: - InterfaceCard

struct InterfaceCard: View {
    let info: NetworkInfo
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("accentTeal").opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: info.activeInterface.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("accentTeal"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Interface")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text(info.activeInterface.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(cardBackground(isHovering: isHovering))
        .onHover { isHovering = $0 }
    }
}

// MARK: - VPNCard

struct VPNCard: View {
    let vpnActive: Bool
    let isLoading: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill((vpnActive ? Color.green : Color("accentRed")).opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: vpnActive ? "lock.shield.fill" : "lock.open")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(vpnActive ? .green : Color("accentRed"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("VPN")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.8)
                if isLoading {
                    LoadingDots()
                } else {
                    Text(vpnActive ? "Active" : "Not detected")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(vpnActive ? .green : Color("accentRed"))
                }
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(cardBackground(isHovering: isHovering))
        .onHover { isHovering = $0 }
    }
}

// MARK: - DNSCard

struct DNSCard: View {
    let servers: [String]
    let isLoading: Bool
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("accentGreen").opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "server.rack")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("accentGreen"))
                }
                Text("DNS Servers")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }
            if isLoading && servers == ["—"] {
                LoadingDots()
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(servers, id: \.self) { server in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color("accentGreen").opacity(0.7))
                                .frame(width: 5, height: 5)
                            Text(server)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(isHovering: isHovering))
        .onHover { isHovering = $0 }
    }
}

// MARK: - DNS Leak Card

struct DNSLeakCard: View {
    let result: DNSLeakResult
    @State private var isHovering = false

    var statusColor: Color {
        Color(result.status.colorName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    if result.status == .testing {
                        ProgressView().scaleEffect(0.6).tint(statusColor)
                    } else {
                        Image(systemName: result.status.icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
                Text("DNS Leak")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            Text(result.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(isHovering: isHovering))
        .onHover { isHovering = $0 }
    }
}

// MARK: - IPInfoCard

struct IPInfoCard: View {
    let ipInfo: IPInfo
    @State private var isHovering = false

    var statusColor: Color { Color(ipInfo.status.colorName) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    if ipInfo.status == .loading {
                        ProgressView().scaleEffect(0.6).tint(statusColor)
                    } else {
                        Image(systemName: ipInfo.status.icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("External Network Analysis")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Text(ipInfo.status.label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(statusColor)
                }
                Spacer()
                // Процент вероятности
                if ipInfo.status != .unknown && ipInfo.status != .loading {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(ipInfo.vpnProbability)%")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(statusColor)
                        Text("VPN chance")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
            }

            // Прогресс бар
            if ipInfo.status != .unknown && ipInfo.status != .loading {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(statusColor)
                            .frame(width: geo.size.width * CGFloat(ipInfo.vpnProbability) / 100, height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Детали
            if ipInfo.org != "—" || ipInfo.country != "—" {
                HStack(spacing: 20) {
                    if ipInfo.country != "—" {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Country")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .textCase(.uppercase)
                                .tracking(0.6)
                            Text(ipInfo.country)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    if ipInfo.city != "—" {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("City")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .textCase(.uppercase)
                                .tracking(0.6)
                            Text(ipInfo.city)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    if ipInfo.org != "—" {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Provider")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .textCase(.uppercase)
                                .tracking(0.6)
                            Text(ipInfo.org)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                        }
                    }
                    if ipInfo.dataSource != "—" {
                        Spacer()
                        Text("via \(ipInfo.dataSource)")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(isHovering: isHovering))
        .onHover { isHovering = $0 }
    }
}

// MARK: - PingCard

struct PingCard: View {
    let results: [PingResult]
    let isLoading: Bool
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("accentPurple").opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "waveform.path")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("accentPurple"))
                }
                Text("Ping")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.8)
            }

            if results.isEmpty {
                HStack {
                    Spacer()
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.7).tint(.white.opacity(0.5))
                            Text("Pinging servers...")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    } else {
                        Text("No results yet")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                HStack(spacing: 10) {
                    ForEach(results) { result in
                        PingBadge(result: result)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(isHovering: isHovering))
        .onHover { isHovering = $0 }
    }
}

struct PingBadge: View {
    let result: PingResult

    var qualityColor: Color {
        switch result.quality {
        case .excellent: return .green
        case .good: return Color("accentTeal")
        case .fair: return .yellow
        case .poor: return .orange
        case .timeout: return Color("accentRed")
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(result.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            if let ms = result.ms {
                Text("\(Int(ms))ms")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(qualityColor)
            } else {
                Text("—")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("accentRed"))
            }
            Text(result.quality.label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(qualityColor.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(qualityColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - SpeedTestCard

struct SpeedTestCard: View {
    let speedTest: SpeedTestResult
    let onRun: () -> Void
    @State private var isHovering = false
    @State private var isHoveringButton = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("accentBlue").opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "speedometer")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color("accentBlue"))
                }
                Text("Speed Test")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Button(action: onRun) {
                    HStack(spacing: 5) {
                        if speedTest.status == .testing {
                            ProgressView().scaleEffect(0.6).tint(.white)
                            Text("Testing...")
                        } else {
                            Image(systemName: "play.fill").font(.system(size: 10))
                            Text(speedTest.status == .done ? "Re-run" : "Run Test")
                        }
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isHoveringButton ? Color("accentBlue").opacity(0.5) : Color("accentBlue").opacity(0.3))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(speedTest.status == .testing)
                .onHover { isHoveringButton = $0 }
            }

            if speedTest.status == .idle {
                Text("Press Run Test to measure your download speed")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            } else if speedTest.status == .testing {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8).tint(Color("accentBlue"))
                    Text("Downloading 5MB from Cloudflare...")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            } else if let mbps = speedTest.downloadMbps {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Download")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                            .textCase(.uppercase)
                            .tracking(0.6)
                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            Text(String(format: "%.1f", mbps))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(speedColor(mbps: mbps))
                            Text("Mbps")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Quality")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                            .textCase(.uppercase)
                            .tracking(0.6)
                        Text(speedLabel(mbps: mbps))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(speedColor(mbps: mbps))
                    }
                }
            } else {
                Text("Test failed — check connection")
                    .font(.system(size: 12))
                    .foregroundColor(Color("accentRed"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(isHovering: isHovering))
        .onHover { isHovering = $0 }
    }

    func speedColor(mbps: Double) -> Color {
        if mbps > 50 { return Color("accentGreen") }
        if mbps > 20 { return Color("accentTeal") }
        if mbps > 5  { return .yellow }
        return Color("accentRed")
    }

    func speedLabel(mbps: Double) -> String {
        if mbps > 50 { return "Fast" }
        if mbps > 20 { return "Good" }
        if mbps > 5  { return "Moderate" }
        return "Slow"
    }
}

// MARK: - Loading Dots

struct LoadingDots: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 5, height: 5)
                    .scaleEffect(animate ? 1 : 0.5)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Helpers

func cardBackground(isHovering: Bool) -> some View {
    RoundedRectangle(cornerRadius: 14)
        .fill(Color.white.opacity(isHovering ? 0.1 : 0.07))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(isHovering ? 0.2 : 0.1), lineWidth: 0.5)
        )
}
