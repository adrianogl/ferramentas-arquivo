import AppKit

enum SessionClock {
    static func secondsSinceSessionStart() -> TimeInterval? {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: AppConstants.loginWindowBundleIdentifier)
        guard let pid = apps.first?.processIdentifier, let start = startDate(of: pid) else { return nil }
        return Date().timeIntervalSince(start)
    }

    private static func startDate(of pid: pid_t) -> Date? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0, size > 0 else { return nil }
        let started = info.kp_proc.p_un.__p_starttime
        return Date(timeIntervalSince1970: TimeInterval(started.tv_sec) + TimeInterval(started.tv_usec) / 1_000_000)
    }
}
