import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` so the popover can toggle the login item.
@MainActor
final class LaunchAtLogin: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var requiresApproval = false

    init() {
        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        requiresApproval = status == .requiresApproval
    }

    func toggle() {
        do {
            if isEnabled || requiresApproval {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Launch at login update failed: \(error.localizedDescription)")
        }
        refresh()
        if requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
