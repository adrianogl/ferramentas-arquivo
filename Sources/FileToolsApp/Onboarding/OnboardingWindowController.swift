import AppKit
import FileToolsCore
import SwiftUI

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    var onTryItTarget: (([URL]) -> Bool)?
    var onAccessibilityGranted: (() -> Void)? {
        get { model.onAccessibilityGranted }
        set { model.onAccessibilityGranted = newValue }
    }
    var onRequestAccessibility: (() -> Void)? {
        get { model.onRequestAccessibility }
        set { model.onRequestAccessibility = newValue }
    }

    private let model: OnboardingModel
    private var window: NSWindow?

    init(settings: SettingsStore) {
        model = OnboardingModel(settings: settings)
        super.init()
        onTryItTarget = { [weak model] targets in model?.registerTryIt(targets) ?? false }
        model.commitEdits = { [weak self] in _ = self?.window?.makeFirstResponder(nil) }
        model.onFinish = { [weak self] in self?.window?.close() }
    }

    func show(at step: OnboardingStep) {
        model.start(at: step)
        let window = window ?? makeWindow()
        self.window = window
        NSApp.activate()
        if !window.isVisible { window.center() }
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        model.stop()
    }

    private func makeWindow() -> NSWindow {
        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let size = AppConstants.Onboarding.windowSize
        let probe = NSRect(origin: .zero, size: size)
        let titlebarHeight = NSWindow.frameRect(forContentRect: probe, styleMask: styleMask).height - size.height
        let contentSize = CGSize(width: size.width, height: size.height - titlebarHeight)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: styleMask,
            backing: .buffered,
            defer: false)
        window.title = "Configuração"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .aqua)
        window.backgroundColor = .white
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: OnboardingView(model: model, size: contentSize))
        return window
    }
}
