import Foundation
import Network
import SystemConfiguration
import Darwin
import Combine

// MARK: - Models

struct NetworkInfo {
    var localIP: String = "—"
    var externalIP: String = "—"
    var ipv4: String = "—"
    var ipv6: String = "—"
    var dnsServers: [String] = []
    var vpnActive: Bool = false
    var activeInterface: NetworkInterface = .unknown
    var isLoading: Bool = false
    var lastUpdated: Date? = nil
}

enum NetworkInterface: String {
    case wifi = "Wi-Fi"
    case ethernet = "Ethernet"
    case vpn = "VPN"
    case unknown = "Unknown"

    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .vpn: return "lock.shield"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - DNS Leak

struct DNSLeakResult {
    var status: LeakStatus = .unknown
    var detectedServers: [String] = []
    var message: String = "Not tested"

    enum LeakStatus {
        case safe, warning, leak, unknown, testing

        var colorName: String {
            switch self {
            case .safe: return "accentGreen"
            case .warning: return "accentOrange"
            case .leak: return "accentRed"
            case .unknown, .testing: return "accentPurple"
            }
        }

        var icon: String {
            switch self {
            case .safe: return "checkmark.shield.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .leak: return "xmark.shield.fill"
            case .unknown: return "shield"
            case .testing: return "arrow.triangle.2.circlepath"
            }
        }
    }
}

// MARK: - IP Info (Router VPN detect)

struct IPInfo {
    var country: String = "—"
    var city: String = "—"
    var org: String = "—"
    var vpnProbability: Int = 0      // 0–100%
    var isVPNOrHosting: Bool = false
    var status: RouterVPNStatus = .unknown
    var isLoading: Bool = false
    var dataSource: String = "—"     // какой сервис ответил

    enum RouterVPNStatus {
        case vpnDetected    // 86–100%
        case likelyVPN      // 61–85%
        case possible       // 31–60%
        case unlikely       // 0–30%
        case unknown
        case loading

        var colorName: String {
            switch self {
            case .vpnDetected: return "accentGreen"
            case .likelyVPN: return "accentTeal"
            case .possible: return "accentOrange"
            case .unlikely: return "accentRed"
            case .unknown, .loading: return "accentPurple"
            }
        }

        var icon: String {
            switch self {
            case .vpnDetected: return "checkmark.shield.fill"
            case .likelyVPN: return "shield.lefthalf.filled"
            case .possible: return "shield"
            case .unlikely: return "xmark.shield"
            case .unknown: return "shield"
            case .loading: return "arrow.triangle.2.circlepath"
            }
        }

        var label: String {
            switch self {
            case .vpnDetected: return "Almost certainly VPN"
            case .likelyVPN: return "Probably VPN"
            case .possible: return "Possibly VPN"
            case .unlikely: return "Likely no VPN"
            case .unknown: return "Unknown"
            case .loading: return "Analysing..."
            }
        }

        static func from(probability: Int) -> RouterVPNStatus {
            switch probability {
            case 86...100: return .vpnDetected
            case 61...85:  return .likelyVPN
            case 31...60:  return .possible
            default:       return .unlikely
            }
        }
    }
}

// MARK: - SpeedTestResult

struct SpeedTestResult {
    var downloadMbps: Double? = nil
    var status: Status = .idle
    enum Status { case idle, testing, done }
}

// MARK: - PingResult

struct PingResult: Identifiable {
    let id = UUID()
    let name: String
    let host: String
    let ms: Double?

    var quality: PingQuality {
        guard let ms else { return .timeout }
        if ms < 30 { return .excellent }
        if ms < 80 { return .good }
        if ms < 150 { return .fair }
        return .poor
    }
}

enum PingQuality {
    case excellent, good, fair, poor, timeout

    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .timeout: return "Timeout"
        }
    }
}

// MARK: - Active Connection

struct ActiveConnection: Identifiable {
    let id = UUID()
    let appName: String
    let remoteIP: String
    let port: String
    let proto: String

    var portLabel: String {
        switch port {
        case "443": return "443 (HTTPS)"
        case "80": return "80 (HTTP)"
        case "22": return "22 (SSH)"
        case "53": return "53 (DNS)"
        case "25", "587", "465": return "\(port) (Mail)"
        default: return port
        }
    }
}

// MARK: - NetworkMonitor

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var info = NetworkInfo()
    @Published var pingResults: [PingResult] = []
    @Published var dnsLeak = DNSLeakResult()
    @Published var ipInfo = IPInfo()
    @Published var speedTest = SpeedTestResult()
    @Published var connections: [ActiveConnection] = []
    @Published var connectionsLoading = false

    // FIX #4: защита от параллельных refresh
    private var isRefreshing = false

    private var refreshTimer: Timer?
    private var connectionsTimer: Timer?
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    // FIX #2: URLSession с таймаутом 5 сек для внешних запросов
    private let timedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        return URLSession(configuration: config)
    }()

    static let pingTargets: [(name: String, host: String)] = [
        ("Google", "8.8.8.8"),
        ("Cloudflare", "1.1.1.1"),
        ("Apple", "17.253.144.10")
    ]

    private let privacyDNS: Set<String> = [
        "1.1.1.1", "1.0.0.1",
        "8.8.8.8", "8.8.4.4",
        "9.9.9.9", "149.112.112.112",
        "208.67.222.222", "208.67.220.220",
        "94.140.14.14", "94.140.15.15",
        "185.228.168.9", "185.228.169.9"
    ]

    init() {
        startPathMonitor()
        Task { await refresh(full: true) }
        startAutoRefresh()
        Task { await fetchConnections() }
        startConnectionsTimer()
    }

    deinit {
        refreshTimer?.invalidate()
        connectionsTimer?.invalidate()
        monitor.cancel()
    }

    // MARK: - Refresh

    // FIX #1: разделён на quick (локальные данные) и full (внешние запросы)
    func refresh(full: Bool = false) async {
        // FIX #4: не запускаем если уже идёт refresh
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        info.isLoading = true

        // Быстрые локальные данные — всегда
        async let ipv4 = getIPv4()
        async let ipv6 = getIPv6()
        async let dns = getDNSServers()
        async let vpn = checkVPN()
        async let iface = getActiveInterface()

        let (v4, v6, dnsArr, isVPN, iface_) = await (ipv4, ipv6, dns, vpn, iface)

        info.ipv4 = v4
        info.ipv6 = v6
        info.dnsServers = dnsArr
        info.vpnActive = isVPN
        info.activeInterface = iface_

        // Внешний IP — тоже всегда, но с таймаутом
        let ext = await getExternalIP()
        info.externalIP = ext
        info.localIP = v4

        info.isLoading = false
        info.lastUpdated = Date()

        // Ping — всегда (TCP, быстро)
        await runPings()

        // DNS Leak — всегда (локальная логика)
        await runDNSLeakTest(dnsServers: dnsArr, vpnActive: isVPN)

        // FIX #1: тяжёлый ipapi запрос — только при full refresh
        if full {
            await fetchIPInfo(externalIP: ext)
        }
    }

    private func startPathMonitor() {
        monitor.pathUpdateHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                // При смене сети — полный refresh
                await self?.refresh(full: true)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh(full: false)
            }
        }
    }

    private func startConnectionsTimer() {
        connectionsTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchConnections()
            }
        }
    }

    // MARK: - Active Connections

    func fetchConnections() async {
        connectionsLoading = true

        let result = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
                process.arguments = ["-i", "4", "-n", "-P", "-sTCP:ESTABLISHED"]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()
                do {
                    try process.run()
                    process.waitUntilExit()
                    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } catch {
                    print("lsof error: \(error)")
                    continuation.resume(returning: "")
                }
            }
        }
        print("lsof output lines: \(result.components(separatedBy: "\n").count)")
        print("first line: \(result.components(separatedBy: "\n").first ?? "empty")")

        connections = parseConnections(result)
        connectionsLoading = false
    }

    private func parseConnections(_ output: String) -> [ActiveConnection] {
        let systemProcesses = [
            "com.apple", "launchd", "kernel", "mds", "configd",
            "locationd", "trustd", "bird", "nsurlsessiond", "cloudd",
            "rapportd", "symptomsd", "parsecd", "identityservicesd",
            "securityd", "distnoted", "notifyd", "opendirectoryd",
            "coreaudiod", "mediaremoted", "coreduetd", "dasd",
            "spindump", "aned", "akd", "remindd", "callservicesd",
            "identitys", "ccpd", "canon"
        ]

        var seen = Set<String>()
        var result: [ActiveConnection] = []

        for line in output.components(separatedBy: "\n").dropFirst() {
            // Проверяем ESTABLISHED и TCP
            guard line.contains("(ESTABLISHED)") && line.contains("TCP") else { continue }
            // Пропускаем fe80 (link-local) и 127.0.0.1 (localhost)
            guard !line.contains("fe80") && !line.contains("127.0.0.1") else { continue }

            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 9 else { continue }

            let appName = String(parts[0])
            let appLower = appName.lowercased()
            if systemProcesses.contains(where: { appLower.contains($0) }) { continue }

            // Адрес — ищем часть с "->"
            guard let addressPart = parts.first(where: { $0.contains("->") }) else { continue }
            let address = String(addressPart)

            guard let arrow = address.range(of: "->") else { continue }
            let remote = String(address[arrow.upperBound...])
            guard let lastColon = remote.lastIndex(of: ":") else { continue }

            let remoteIP = String(remote[remote.startIndex..<lastColon])
            let remotePort = String(remote[remote.index(after: lastColon)...])

            let key = "\(appName)-\(remoteIP)-\(remotePort)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            result.append(ActiveConnection(
                appName: appName,
                remoteIP: remoteIP,
                port: remotePort,
                proto: "TCP"
            ))
        }

        return Array(result.prefix(50))
    }

    // MARK: - Local IP / IPv4

    private func getIPv4() async -> String {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return "Not available" }
        defer { freeifaddrs(ifaddr) }
        var ptr = ifaddr
        while let ifa = ptr?.pointee {
            if ifa.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                let name = String(cString: ifa.ifa_name)
                if name.hasPrefix("en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(ifa.ifa_addr, socklen_t(ifa.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        return String(cString: hostname)
                    }
                }
            }
            ptr = ifa.ifa_next
        }
        return "Not available"
    }

    // MARK: - IPv6

    private func getIPv6() async -> String {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return "Not available" }
        defer { freeifaddrs(ifaddr) }
        var ptr = ifaddr
        while let ifa = ptr?.pointee {
            if ifa.ifa_addr.pointee.sa_family == UInt8(AF_INET6) {
                let name = String(cString: ifa.ifa_name)
                if name.hasPrefix("en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(ifa.ifa_addr, socklen_t(ifa.ifa_addr.pointee.sa_len),
                                   &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let ip = String(cString: hostname)
                        if !ip.hasPrefix("fe80") { return ip }
                    }
                }
            }
            ptr = ifa.ifa_next
        }
        return "Not available"
    }

    // MARK: - External IP (с таймаутом)

    private func getExternalIP() async -> String {
        let urls = ["https://api.ipify.org", "https://icanhazip.com", "https://checkip.amazonaws.com"]
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            // FIX #2: используем timedSession с таймаутом 5 сек
            if let (data, _) = try? await timedSession.data(from: url),
               let ip = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !ip.isEmpty { return ip }
        }
        return "No connection"
    }

    // MARK: - DNS

    private func getDNSServers() async -> [String] {
        guard let store = SCDynamicStoreCreate(nil, "MacNetInspector" as CFString, nil, nil),
              let dict = SCDynamicStoreCopyValue(store, "State:/Network/Global/DNS" as CFString) as? [String: Any],
              let addresses = dict["ServerAddresses"] as? [String] else { return ["—"] }
        let servers = Array(addresses.prefix(3))
        return servers.isEmpty ? ["—"] : servers
    }

    // MARK: - VPN (только default route, игнорируем fe80)

    private func checkVPN() async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
                process.arguments = ["-rn"]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()
                do {
                    try process.run()
                    process.waitUntilExit()
                    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    for line in output.components(separatedBy: "\n") {
                        // FIX: только default route + utun + не fe80 (link-local)
                        if line.hasPrefix("default") && line.contains("utun") && !line.contains("fe80") {
                            continuation.resume(returning: true)
                            return
                        }
                    }
                    continuation.resume(returning: false)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    // MARK: - Active Interface (только default route, игнорируем fe80)

    private func getActiveInterface() async -> NetworkInterface {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
                process.arguments = ["-rn"]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()
                do {
                    try process.run()
                    process.waitUntilExit()
                    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    for line in output.components(separatedBy: "\n") {
                        guard line.hasPrefix("default") else { continue }
                        // FIX: utun только если не fe80
                        if line.contains("utun") && !line.contains("fe80") {
                            continuation.resume(returning: .vpn); return
                        }
                        if line.contains("en0") { continuation.resume(returning: .wifi); return }
                        if line.contains("en1") { continuation.resume(returning: .ethernet); return }
                    }
                    continuation.resume(returning: .unknown)
                } catch {
                    continuation.resume(returning: .unknown)
                }
            }
        }
    }

    // MARK: - DNS Leak Test

    func runDNSLeakTest(dnsServers: [String], vpnActive: Bool) async {
        dnsLeak.status = .testing
        dnsLeak.message = "Testing..."
        dnsLeak.detectedServers = dnsServers.filter { $0 != "—" }

        try? await Task.sleep(nanoseconds: 500_000_000)

        let servers = dnsServers.filter { $0 != "—" }
        if servers.isEmpty {
            dnsLeak.status = .unknown
            dnsLeak.message = "No DNS servers detected"
            return
        }

        if vpnActive {
            let allPrivate = servers.allSatisfy { privacyDNS.contains($0) }
            let anyPrivate = servers.contains { privacyDNS.contains($0) }
            if allPrivate {
                dnsLeak.status = .safe
                dnsLeak.message = "No leak — DNS routes through VPN"
            } else if anyPrivate {
                dnsLeak.status = .warning
                dnsLeak.message = "Possible partial leak detected"
            } else {
                dnsLeak.status = .leak
                dnsLeak.message = "Leak! ISP DNS used with VPN active"
            }
        } else {
            let usingPrivacyDNS = servers.contains { privacyDNS.contains($0) }
            dnsLeak.status = usingPrivacyDNS ? .safe : .warning
            dnsLeak.message = usingPrivacyDNS ? "Using privacy DNS" : "Using ISP DNS — consider 1.1.1.1"
        }
    }

    // MARK: - IP Info / Router VPN detect (только при full refresh)

    func fetchIPInfo(externalIP: String) async {
        guard externalIP != "—", externalIP != "No connection" else {
            ipInfo.status = .unknown; return
        }
        ipInfo.isLoading = true
        ipInfo.status = .loading
        print("fetchIPInfo called with: \(externalIP)")
        // Пробуем два сервиса с фоллбеком
        let parsed: IPData?
        if let first = await fetchFromIpApi(ip: externalIP) {
            parsed = first
        } else if let second = await fetchFromIpApiCo(ip: externalIP) {
            parsed = second
        } else {
            parsed = await fetchFromIpWhois(ip: externalIP)
        }

        guard let data = parsed else {
            ipInfo.status = .unknown
            ipInfo.isLoading = false
            return
        }


        ipInfo.country = data.country
        ipInfo.city = data.city
        ipInfo.org = data.org
        ipInfo.dataSource = data.source

        // MARK: Подсчёт вероятности VPN
        var score = 0

        let providerText = "\(data.org) \(data.asn)".lowercased()

        // +40% — провайдер явно VPN
        let vpnKeywords = ["vpn", "wireguard", "openvpn", "mullvad", "nordvpn",
                           "surfshark", "expressvpn", "protonvpn", "tailscale",
                           "zerotier", "tunnel", "proxy", "hide.me", "pia"]
        if vpnKeywords.contains(where: { providerText.contains($0) }) { score += 40 }

        // +35% — ip-api.com напрямую говорит hosting: true
        if data.isHosting { score += 35 }

        // +30% — хостинг / датацентр по ключевым словам
        let hostingKeywords = ["amazon", "aws", "digitalocean", "linode", "vultr",
                               "hetzner", "ovh", "choopa", "oracle", "m247",
                               "datacamp", "server", "hosting", "datacenter",
                               "vps", "cloud", "leaseweb", "fastly", "akamai"]
        if hostingKeywords.contains(where: { providerText.contains($0) }) { score += 30 }

        // +35% — страна IP не совпадает с таймзоной Mac
        let tzRegion = TimeZone.current.identifier
            .split(separator: "/").first.map(String.init) ?? ""
        let countryLower = data.country.lowercased()
        let tzLower = tzRegion.lowercased()
        let isCountryMismatch = !countryLower.isEmpty && !tzLower.isEmpty
            && !countryLower.contains(tzLower) && !tzLower.contains(countryLower)
        if isCountryMismatch { score += 35 }

        // +15% — страна = популярный VPN-хаб
        let vpnHubCountries = ["netherlands", "switzerland", "panama", "iceland",
                               "british virgin islands", "luxembourg", "romania",
                               "seychelles", "malta", "cyprus"]
        if vpnHubCountries.contains(where: { countryLower.contains($0) }) { score += 15 }

        // +20% — ASN известного датацентра
        let datacenterASNs = ["as14061", "as16509", "as8075", "as13335",
                               "as20473", "as9009", "as24940", "as51167"]
        if datacenterASNs.contains(where: { providerText.contains($0) }) { score += 20 }

        // +10% — IPv6 недоступен при наличии IPv4 (признак VPN туннеля)
        if info.ipv4 != "Not available" && info.ipv6 == "Not available" { score += 10 }

        // -30% — явный residential ISP
        let residentialKeywords = ["comcast", "vodafone", "telekom", "orange",
                                   "cosmote", "att ", "verizon", "bt ", "telefonica",
                                   "xfinity", "charter", "rostelecom", "beeline",
                                   "megafon", "mts ", "tele2", "virgin media"]
        if residentialKeywords.contains(where: { providerText.contains($0) }) { score -= 30 }

        // Ограничиваем 0–100
        score = max(0, min(100, score))

        ipInfo.vpnProbability = score
        ipInfo.status = .from(probability: score)
        ipInfo.isVPNOrHosting = score >= 31
        ipInfo.isLoading = false
    }

    // MARK: - IP API helpers

    private struct IPData {
        let country: String
        let city: String
        let org: String
        let asn: String
        let source: String
        let isHosting: Bool
    }

    // Сервис 1: ip-api.com (быстрее, надёжнее, бесплатный)
    private func fetchFromIpApi(ip: String) async -> IPData? {
        guard let url = URL(string: "https://ip-api.com/json/\(ip)?fields=country,city,org,as,hosting") else { return nil }
        guard let (data, _) = try? await timedSession.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["country"] != nil else { return nil }

        let country = json["country"] as? String ?? "—"
        let city = json["city"] as? String ?? "—"
        let org = json["org"] as? String ?? "—"
        let asn = json["as"] as? String ?? ""
        let isHosting = json["hosting"] as? Bool ?? false
        let orgFinal = isHosting ? "\(org) [hosting]" : org

        return IPData(country: country, city: city, org: orgFinal, asn: asn, source: "ip-api.com", isHosting: isHosting)
    }
    
    // Сервис 2: ipapi.co (фоллбек)
    private func fetchFromIpApiCo(ip: String) async -> IPData? {
        guard let url = URL(string: "https://ipapi.co/\(ip)/json/") else { return nil }
        guard let (data, _) = try? await timedSession.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (json["error"] as? Bool) != true else { return nil }

        let country = json["country_name"] as? String ?? (json["country"] as? String ?? "—")
        let city = json["city"] as? String ?? "—"
        let org = json["org"] as? String ?? (json["org_name"] as? String ?? json["asn_org"] as? String ?? "—")
        let asnCode: String = {
            if let asnStr = json["asn"] as? String { return asnStr.lowercased().hasPrefix("as") ? asnStr : "as\(asnStr)" }
            if let asnNum = json["asn"] as? Int { return "as\(asnNum)" }
            return ""
        }()
        let isHosting = (json["type"] as? String)?.lowercased() == "hosting"
        let orgFinal = isHosting ? "\(org) [hosting]" : org

        return IPData(country: country, city: city, org: orgFinal, asn: asnCode, source: "ipapi.co", isHosting: isHosting)
    }

    // Сервис 2: ipapi.co (фоллбек)
    private func fetchFromIpWhois(ip: String) async -> IPData? {
        guard let url = URL(string: "https://ipwhois.io/json/\(ip)") else { return nil }
        guard let (data, _) = try? await timedSession.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (json["success"] as? Bool) == true else { return nil }

        let country = json["country"] as? String ?? "—"
        let city = json["city"] as? String ?? "—"
        let connection = json["connection"] as? [String: Any]
        let org = connection?["org"] as? String ?? "—"
        let isp = connection?["isp"] as? String ?? ""
        let asn = String(connection?["asn"] as? Int ?? 0)
        let orgFinal = isp.isEmpty ? org : "\(org) / \(isp)"

        return IPData(country: country, city: city, org: orgFinal, asn: "as\(asn)", source: "ipwhois.io", isHosting: false)
    }
    // MARK: - Ping (TCP, работает через VPN)

    func runPings() async {
        var results: [PingResult] = []
        for target in Self.pingTargets {
            let ms = await tcpLatency(host: target.host, port: 443)
            results.append(PingResult(name: target.name, host: target.host, ms: ms))
        }
        pingResults = results
    }

    // FIX #3: NWConnection с надёжной защитой от зависаний
    private func tcpLatency(host: String, port: UInt16) async -> Double? {
        return await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(rawValue: port)!,
                using: .tcp
            )
            let start = Date()
            var resumed = false
            let lock = NSLock()

            func resume(_ value: Double?) {
                lock.lock()
                defer { lock.unlock() }
                guard !resumed else { return }
                resumed = true
                connection.cancel()
                continuation.resume(returning: value)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let ms = Date().timeIntervalSince(start) * 1000
                    resume(ms)
                case .failed:
                    resume(nil)
                default: break
                }
            }

            connection.start(queue: DispatchQueue.global(qos: .utility))

            // FIX #3: таймаут 3 сек с гарантированным resume
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                resume(nil)
            }
        }
    }

    // MARK: - Speed Test

    func runSpeedTest() async {
        speedTest = SpeedTestResult(status: .testing)
        let downloadMbps = await measureDownload()
        speedTest.downloadMbps = downloadMbps
        speedTest.status = .done
    }

    private func measureDownload() async -> Double? {
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=5000000") else { return nil }
        let start = Date()
        do {
            // Для speed test нужен отдельный session без короткого таймаута
            let (data, _) = try await URLSession.shared.data(from: url)
            let seconds = Date().timeIntervalSince(start)
            let mbps = (Double(data.count) * 8) / seconds / 1_000_000
            return mbps
        } catch {
            return nil
        }
    }
}

