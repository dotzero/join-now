import ServiceManagement

@MainActor
protocol LaunchAtLoginManaging {
    var isEnabled: Bool { get }

    func setEnabled(_ enabled: Bool) throws
}

@MainActor
struct LaunchAtLoginService: LaunchAtLoginManaging {
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }
}
