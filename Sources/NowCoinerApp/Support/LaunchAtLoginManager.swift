import Foundation
import ServiceManagement

@MainActor
enum LaunchAtLoginManager {
    static func apply(enabled: Bool) {
        if enabled {
            do {
                try SMAppService.mainApp.register()
            } catch {
                NSLog("NowCoiner: launch at login enable failed: %@", error.localizedDescription)
            }
        } else {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                NSLog("NowCoiner: launch at login disable failed: %@", error.localizedDescription)
            }
        }
    }
}
