public enum ClickTargetRule {
    public static func allowsSyntheticClick(path: [AccessibilityNode]) -> Bool {
        typealias Rules = Constants.ClickTarget
        guard path.last?.role == Rules.applicationRole else { return false }
        if path.contains(where: { Rules.blockedRoles.contains($0.role) }) { return false }
        if isDesktop(path) { return true }
        return path.contains(where: { $0.role == Rules.windowRole })
            && path.contains(where: isFileView)
    }

    private static func isFileView(_ node: AccessibilityNode) -> Bool {
        Constants.ClickTarget.fileViewRoles.contains(node.role)
            && Constants.ClickTarget.fileViewIdentifiers.contains(node.identifier)
    }

    private static func isDesktop(_ path: [AccessibilityNode]) -> Bool {
        let ancestors = path.dropLast()
        return ancestors.last?.role == Constants.ClickTarget.scrollAreaRole
            && !ancestors.contains(where: { $0.role == Constants.ClickTarget.windowRole })
    }
}
