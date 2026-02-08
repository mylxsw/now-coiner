import Foundation
import ServiceManagement

@MainActor
enum LaunchAtLoginManager {
    static func apply(enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Keep app functional even when launch service cannot be registered
            // (common in unsigned local builds).
        }
    }
}
