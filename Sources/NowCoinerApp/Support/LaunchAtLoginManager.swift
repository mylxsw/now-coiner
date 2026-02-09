import Foundation
import ServiceManagement

@MainActor
enum LaunchAtLoginManager {
    private static let launchAgentLabel = "com.nowcoiner.launch-at-login"

    static func apply(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                return
            } catch {
                // Fallback for unsigned/dev builds where SMAppService often fails.
            }
        }

        do {
            if enabled {
                try enableLaunchAgentFallback()
            } else {
                try disableLaunchAgentFallback()
            }
        } catch {
            NSLog("NowCoiner: launch at login update failed: %@", error.localizedDescription)
        }
    }

    private static func enableLaunchAgentFallback() throws {
        let plistURL = try launchAgentPlistURL()
        let plist = launchAgentDictionary()
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: plistURL, options: .atomic)

        // Ensure reloading the latest plist content.
        try? runLaunchctl(["bootout", "gui/\(getuid())", plistURL.path])
        try runLaunchctl(["bootstrap", "gui/\(getuid())", plistURL.path])
        try runLaunchctl(["enable", "gui/\(getuid())/\(launchAgentLabel)"])
    }

    private static func disableLaunchAgentFallback() throws {
        let plistURL = try launchAgentPlistURL()
        try? runLaunchctl(["bootout", "gui/\(getuid())", plistURL.path])
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }

    private static func launchAgentPlistURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("LaunchAgents", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(launchAgentLabel).plist")
    }

    private static func launchAgentDictionary() -> [String: Any] {
        [
            "Label": launchAgentLabel,
            "ProgramArguments": launchCommand(),
            "RunAtLoad": true,
            "KeepAlive": false,
            "ProcessType": "Background",
            "LimitLoadToSessionType": "Aqua"
        ]
    }

    private static func launchCommand() -> [String] {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app" {
            return ["/usr/bin/open", bundleURL.path]
        }

        if let executable = Bundle.main.executableURL?.path {
            return [executable]
        }

        return ["/usr/bin/true"]
    }

    private static func runLaunchctl(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let stderr = Pipe()
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = stderr.fileHandleForReading.readDataToEndOfFile()
            let reason = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
            throw NSError(domain: "LaunchAtLoginManager", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: reason])
        }
    }
}
