import Foundation
import Testing
@testable import FileToolsCore

@Suite @MainActor struct SettingsStoreTests {
    @Test func defaults() {
        let s = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(s.limitMegabytes == 1.0)
        #expect(s.triggerModifier == .option)
        #expect(s.launchAtLogin)
        #expect(s.sizeLimit == SizeLimit(bytes: 1_000_000))
    }

    @Test func persists() {
        let suite = UUID().uuidString
        SettingsStore(defaults: UserDefaults(suiteName: suite)!).limitMegabytes = 2.5
        #expect(SettingsStore(defaults: UserDefaults(suiteName: suite)!).sizeLimit.bytes == 2_500_000)
    }

    @Test func clampsLimit() {
        let s = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        s.limitMegabytes = 0
        #expect(s.limitMegabytes == 0.1)
        s.limitMegabytes = 500
        #expect(s.limitMegabytes == 100)
    }
}
