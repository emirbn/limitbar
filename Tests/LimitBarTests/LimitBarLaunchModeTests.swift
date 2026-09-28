import Testing
@testable import LimitBar

struct LimitBarLaunchModeTests {
    @Test
    func `normal launch starts the application`() {
        #expect(LimitBarLaunchMode.resolve(arguments: ["/Applications/LimitBar"]) == .application)
    }

    @Test
    func `hook event launch skips application initialization`() {
        #expect(LimitBarLaunchMode.resolve(
            arguments: ["/Applications/LimitBar", "--hook-event"]) == .hookEvent)
    }

    @Test
    func `hook event is recognized among other arguments`() {
        #expect(LimitBarLaunchMode.resolve(
            arguments: ["/Applications/LimitBar", "--verbose", "--hook-event"]) == .hookEvent)
    }

    @Test
    func `similar argument still starts the application`() {
        #expect(LimitBarLaunchMode.resolve(
            arguments: ["/Applications/LimitBar", "--hook-events"]) == .application)
    }
}
