import Testing
@testable import FileToolsCore

@Suite struct OnboardingStepTests {
    @Test func firstIsWelcomeWhenNotCompleted() {
        #expect(OnboardingStep.first(accessibility: true, finder: true, completed: false) == .welcome)
    }

    @Test func firstIsAccessibilityWhenCompletedButAccessibilityMissing() {
        #expect(OnboardingStep.first(accessibility: false, finder: true, completed: true) == .accessibility)
    }

    @Test func firstIsFinderWhenCompletedButFinderMissing() {
        #expect(OnboardingStep.first(accessibility: true, finder: false, completed: true) == .finder)
    }

    @Test func firstIsNilWhenEverythingIsGranted() {
        #expect(OnboardingStep.first(accessibility: true, finder: true, completed: true) == nil)
    }

    @Test func welcomeAlwaysContinues() {
        #expect(OnboardingStep.welcome.canContinue(accessibility: false, finder: false, triedIt: false))
    }

    @Test func accessibilityRequiresPermission() {
        #expect(!OnboardingStep.accessibility.canContinue(accessibility: false, finder: true, triedIt: true))
        #expect(OnboardingStep.accessibility.canContinue(accessibility: true, finder: false, triedIt: false))
    }

    @Test func finderRequiresBothPermissions() {
        #expect(!OnboardingStep.finder.canContinue(accessibility: true, finder: false, triedIt: true))
        #expect(!OnboardingStep.finder.canContinue(accessibility: false, finder: true, triedIt: true))
        #expect(OnboardingStep.finder.canContinue(accessibility: true, finder: true, triedIt: false))
    }

    @Test func tryItRequiresTriedIt() {
        #expect(!OnboardingStep.tryIt.canContinue(accessibility: true, finder: true, triedIt: false))
        #expect(OnboardingStep.tryIt.canContinue(accessibility: true, finder: true, triedIt: true))
    }

    @Test func doneAlwaysContinues() {
        #expect(OnboardingStep.done.canContinue(accessibility: false, finder: false, triedIt: false))
    }
}
