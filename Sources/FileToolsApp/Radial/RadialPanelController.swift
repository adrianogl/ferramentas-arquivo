import AppKit
import FileToolsCore
import SwiftUI

@MainActor
final class RadialPanelController {
    private let coordinator: ActionCoordinator
    private let settings: SettingsStore
    private var panel: NSPanel?
    private var model: RadialMenuModel?
    private var monitors: [Any] = []
    private var center: CGPoint = .zero
    private var cgPoint: CGPoint = .zero
    private var generation = 0

    init(coordinator: ActionCoordinator, settings: SettingsStore) {
        self.coordinator = coordinator
        self.settings = settings
    }

    func show(targets: [URL], at cgPoint: CGPoint) {
        close(animated: false)
        generation += 1
        let generation = generation
        self.cgPoint = cgPoint

        let model = RadialMenuModel(urls: targets, targets: targets.map(Self.info), limit: settings.sizeLimit)
        let frame = Self.frame(around: cgPoint)
        let panel = makePanel(frame: frame, model: model)
        self.model = model
        self.panel = panel
        center = CGPoint(x: frame.midX, y: frame.midY)

        panel.orderFrontRegardless()
        installMonitors()
        updateHover()
        DispatchQueue.main.async {
            withAnimation(.spring(duration: AppConstants.Radial.openDuration)) { model.isShown = true }
        }
        Task {
            let counts = await Task.detached(priority: .userInitiated) { Self.pageCounts(targets) }.value
            guard generation == self.generation else { return }
            model.updatePageCounts(counts)
        }
    }

    private func makePanel(frame: CGRect, model: RadialMenuModel) -> NSPanel {
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isReleasedWhenClosed = false
        panel.acceptsMouseMovedEvents = true
        let hosting = NSHostingView(rootView: RadialMenuView(model: model))
        hosting.frame = CGRect(origin: .zero, size: frame.size)
        hosting.addTrackingArea(NSTrackingArea(
            rect: .zero, options: [.mouseMoved, .activeAlways, .inVisibleRect], owner: hosting))
        panel.contentView = hosting
        return panel
    }

    private func installMonitors() {
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .leftMouseDown, .rightMouseDown, .keyDown]
        if let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { [weak self] event in
            MainActor.assumeIsolated { _ = self?.handle(event, local: false) }
        }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: mask, handler: { [weak self] event in
            let consumed = MainActor.assumeIsolated { self?.handle(event, local: true) ?? false }
            return consumed ? nil : event
        }) {
            monitors.append(local)
        }
    }

    private func removeMonitors() {
        monitors.forEach(NSEvent.removeMonitor)
        monitors.removeAll()
    }

    private func handle(_ event: NSEvent, local: Bool) -> Bool {
        guard let model, let panel else { return false }
        let ownsEvent = local && event.window === panel
        guard model.phase == .choosing else { return ownsEvent }
        switch event.type {
        case .mouseMoved, .leftMouseDragged:
            updateHover()
            return false
        case .leftMouseDown:
            click(model: model)
            return ownsEvent
        case .rightMouseDown:
            close(animated: true)
            return ownsEvent
        case .keyDown where event.keyCode == AppConstants.Radial.escapeKeyCode:
            close(animated: true)
            return true
        default:
            return false
        }
    }

    private func offset() -> CGVector {
        let mouse = NSEvent.mouseLocation
        return CGVector(dx: mouse.x - center.x, dy: mouse.y - center.y)
    }

    private func updateHover() {
        guard let model else { return }
        let slot = RadialGeometry.slot(at: offset())
        if model.hoveredSlot != slot { model.hoveredSlot = slot }
    }

    private func click(model: RadialMenuModel) {
        guard let slot = RadialGeometry.slot(at: offset()) else {
            close(animated: true)
            return
        }
        model.hoveredSlot = slot
        guard let id = model.action(at: slot), model.isAvailable(id) else { return }
        run(id, model: model)
    }

    private func run(_ id: ActionID, model: RadialMenuModel) {
        model.phase = .running(id)
        let generation = generation
        let point = cgPoint
        let urls = model.urls
        Task { [coordinator] in
            await coordinator.run(id, urls: urls, near: point)
        }
        Task {
            try? await Task.sleep(for: AppConstants.Radial.minimumProgress)
            guard generation == self.generation else { return }
            close(animated: true)
        }
    }

    private func close(animated: Bool) {
        removeMonitors()
        guard let panel, let model else { return }
        self.panel = nil
        self.model = nil
        generation += 1
        guard animated else {
            panel.orderOut(nil)
            return
        }
        withAnimation(.easeIn(duration: AppConstants.Radial.closeDuration)) { model.isShown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConstants.Radial.closeDuration) {
            panel.orderOut(nil)
        }
    }

    private static func info(_ url: URL) -> TargetInfo {
        let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return TargetInfo(name: url.lastPathComponent, bytes: bytes, pageCount: nil, kind: FileKind.of(url))
    }

    nonisolated private static func pageCounts(_ urls: [URL]) -> [Int?] {
        urls.map { url in
            guard FileKind.of(url) == .pdf else { return nil }
            return (try? PDFReader.open(url))?.pageCount
        }
    }

    private static func frame(around cgPoint: CGPoint) -> CGRect {
        let size = AppConstants.Radial.panelSize
        return ScreenPlacement.frame(size: CGSize(width: size, height: size), centeredAt: cgPoint)
    }
}
