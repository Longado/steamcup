import Foundation

// A plain-text record of what Steamcup did and how warm the Mac was, for looking back after a lid-closed run:
// ~/Library/Logs/Steamcup.log (opens in Console). The app and the background check both add to it.
enum Log {
    static var url: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/Steamcup.log") }

    static func note(_ text: String) {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let line = Array("\(f.string(from: Date()))  \(text)\n".utf8)
        let fd = open(url.path, O_WRONLY | O_APPEND | O_CREAT, 0o644)   // O_APPEND: two processes adding lines never overwrite each other
        guard fd >= 0 else { return NSLog("Steamcup: couldn't open \(url.path) (errno \(errno))") }
        defer { close(fd) }
        if write(fd, line, line.count) != line.count { NSLog("Steamcup: couldn't write to \(url.path) (errno \(errno))") }
    }

    // Written once a minute while Steamcup is on. The battery sensor is the warmest part a user app can read
    // without admin rights; "heat" is the level macOS itself acts on (and Steamcup stops lid-closed mode at "serious").
    static func sample(lidClosedMode: Bool) {
        let b = Battery.read()
        let heat = [ProcessInfo.ThermalState.nominal: "normal", .fair: "fair", .serious: "serious", .critical: "critical"][ProcessInfo.processInfo.thermalState] ?? "unknown"
        let temp = Battery.celsius().map { String(format: "battery %.1f°C", $0) } ?? "battery temperature unknown"
        note("lid \(Lid.isShut ? "shut" : "open"), lid-closed mode \(lidClosedMode ? "on" : "off"), \(b.percent)% \(b.onBattery ? "on battery" : "plugged in"), \(temp), heat \(heat)")
    }

    // ponytail: keeps one old file; 5 MB is about six weeks of round-the-clock use at a line a minute.
    static func rotate() {
        let fm = FileManager.default
        guard let size = (try? fm.attributesOfItem(atPath: url.path))?[.size] as? Int, size > 5_000_000 else { return }
        let old = url.deletingLastPathComponent().appendingPathComponent("Steamcup.old.log")
        if fm.fileExists(atPath: old.path) { try? fm.removeItem(at: old) }
        do { try fm.moveItem(at: url, to: old) } catch { NSLog("Steamcup: couldn't rotate \(url.path): \(error)") }
    }
}
