import Foundation
import CoreLocation
import CoreBluetooth

class AppData: ObservableObject, Codable {
    @Published var monitoredApps: [MonitoredApp] = []
    @Published var locationRules: [LocationRule] = []
    @Published var activeSession: DoomscrollSession?
    @Published var blockSettings: BlockSettings = BlockSettings()
    @Published var usageHistory: [UsageRecord] = []
    @Published var isAppLocked: Bool = false
    @Published var emergencyOverrideUsed: Bool = false
    @Published var emergencyCode: String = UUID().uuidString.prefix(8)

    init() { loadSampleData() }

    private func loadSampleData() {
        monitoredApps = [
            MonitoredApp(appName: "Instagram", bundleID: "com.burbn.instagram", defaultLimit: 15, iconName: "camera", isActive: true),
            MonitoredApp(appName: "TikTok", bundleID: "com.zhiliaoapp.musically", defaultLimit: 20, iconName: "music.note", isActive: true),
            MonitoredApp(appName: "Twitter", bundleID: "com.atebits.Tweetie2", defaultLimit: 15, iconName: "bubble", isActive: true),
            MonitoredApp(appName: "YouTube", bundleID: "com.google.ios.youtube", defaultLimit: 30, iconName: "play.tv", isActive: true),
            MonitoredApp(appName: "Reddit", bundleID: "com.reddit.Reddit", defaultLimit: 20, iconName: "text.bubble", isActive: true),
        ]
    }

    func startSession(for app: MonitoredApp, purpose: SessionPurpose) {
        activeSession = DoomscrollSession(app: app, startTime: Date(), purpose: purpose, extensionCount: 0)
        saveUsageRecord(app: app, purpose: purpose)
    }

    func extendSession() {
        guard var session = activeSession else { return }
        session.extensionCount += 1
        session.lastExtensionTime = Date()
        activeSession = session
        if session.extensionCount >= blockSettings.maxExtensions { lockApp() }
    }

    func endSession() {
        guard let session = activeSession else { return }
        let duration = Date().timeIntervalSince(session.startTime) / 60
        if session.purpose == .browsing && duration > Double(session.app.defaultLimit) {
            saveUsageRecord(app: session.app, purpose: .doomscrolling, duration: duration)
        }
        activeSession = nil
    }

    func lockApp() { isAppLocked = true; activeSession = nil }
    func unlockApp(with passcode: String) -> Bool {
        if passcode == blockSettings.passcode { isAppLocked = false; return true }
        return false
    }
    func emergencyUnlock(with code: String) -> Bool {
        if code == emergencyCode { isAppLocked = false; emergencyOverrideUsed = true; return true }
        return false
    }

    private func saveUsageRecord(app: MonitoredApp, purpose: SessionPurpose, duration: Double? = nil) {
        let record = UsageRecord(app: app, purpose: purpose, timestamp: Date(), duration: duration)
        usageHistory.append(record)
        if usageHistory.count > 100 { usageHistory.removeFirst() }
    }

    func addLocationRule(_ rule: LocationRule) { locationRules.append(rule) }
    func removeLocationRule(at indexSet: IndexSet) { locationRules.remove(atOffsets: indexSet) }
    func updateLocationRule(_ rule: LocationRule) {
        if let index = locationRules.firstIndex(where: { $0.id == rule.id }) { locationRules[index] = rule }
    }
}

struct MonitoredApp: Identifiable, Codable, Hashable {
    let id: UUID
    var appName: String
    var bundleID: String
    var defaultLimit: Int
    var iconName: String
    var isActive: Bool

    init(id: UUID = UUID(), appName: String, bundleID: String, defaultLimit: Int, iconName: String, isActive: Bool = true) {
        self.id = id; self.appName = appName; self.bundleID = bundleID
        self.defaultLimit = defaultLimit; self.iconName = iconName; self.isActive = isActive
    }
}

enum SessionPurpose: String, Codable {
    case socializing = "Socializing"
    case browsing = "Browsing"
    case doomscrolling = "Doomscrolling"
}

struct DoomscrollSession: Identifiable, Codable {
    let id: UUID
    let app: MonitoredApp
    let startTime: Date
    let purpose: SessionPurpose
    var extensionCount: Int
    var lastExtensionTime: Date?

    init(id: UUID = UUID(), app: MonitoredApp, startTime: Date, purpose: SessionPurpose, extensionCount: Int = 0) {
        self.id = id; self.app = app; self.startTime = startTime
        self.purpose = purpose; self.extensionCount = extensionCount
    }

    var elapsedMinutes: Int { Int(Date().timeIntervalSince(startTime) / 60) }
    var isOverLimit: Bool { elapsedMinutes > app.defaultLimit }
}

enum RuleType: String, Codable {
    case bluetooth, gps
}

struct LocationRule: Identifiable, Codable {
    let id: UUID
    var name: String
    var ruleType: RuleType
    var deviceIdentifier: String?
    var coordinate: CLLocationCoordinate2D?
    var rangeMeters: Double
    var isActive: Bool
    var gracePeriodSeconds: Int?

    init(id: UUID = UUID(), name: String, ruleType: RuleType, deviceIdentifier: String? = nil, coordinate: CLLocationCoordinate2D? = nil, rangeMeters: Double = 10.0, isActive: Bool = true, gracePeriodSeconds: Int? = nil) {
        self.id = id; self.name = name; self.ruleType = ruleType
        self.deviceIdentifier = deviceIdentifier; self.coordinate = coordinate
        self.rangeMeters = rangeMeters; self.isActive = isActive
        self.gracePeriodSeconds = gracePeriodSeconds
    }
}

struct BlockSettings: Codable {
    var maxExtensions: Int = 3
    var passcode: String = "0000"
    var useGracePeriod: Bool = false
    var gracePeriodMinutes: Int = 1
    var showEmergencyQR: Bool = true

    enum CodingKeys: String, CodingKey { case maxExtensions, useGracePeriod, gracePeriodMinutes, showEmergencyQR }
}

struct UsageRecord: Identifiable, Codable {
    let id: UUID
    let app: MonitoredApp
    let purpose: SessionPurpose
    let timestamp: Date
    let duration: Double?

    init(id: UUID = UUID(), app: MonitoredApp, purpose: SessionPurpose, timestamp: Date, duration: Double? = nil) {
        self.id = id; self.app = app; self.purpose = purpose
        self.timestamp = timestamp; self.duration = duration
    }
}
