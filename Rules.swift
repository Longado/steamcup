import Foundation

// Pure decisions, kept apart so tests/main.swift can check them without the app.

enum LidStop: String { case hot = "the Mac got too hot", lowBattery = "the battery is low" }

// Lid-closed mode stops itself when a closed MacBook is likely cooking or about to die.
func lidSafety(thermal: ProcessInfo.ThermalState, onBattery: Bool, percent: Int) -> LidStop? {
    if thermal == .serious || thermal == .critical { return .hot }
    if onBattery && percent <= 10 { return .lowBattery }
    return nil
}

// After a crash or forced quit: what the background check (and the next launch) does about lid sleep.
// ours: Steamcup switched lid sleep off and has not switched it back.
enum RecoveryStep: Equatable { case nothing, forget, switchBack }

func recoveryStep(ours: Bool, sleepDisabled: Bool, appRunning: Bool) -> RecoveryStep {
    if appRunning || !ours { return .nothing }   // a running Steamcup handles its own session; someone else's switch is left alone
    return sleepDisabled ? .switchBack : .forget
}

// Time left shown beside the cup: "1:05", "0:01". Rounds up so it never shows 0:00 while still on.
func remainingText(_ seconds: TimeInterval) -> String {
    let m = max(1, Int((seconds / 60).rounded(.up)))
    return "\(m / 60):" + String(format: "%02d", m % 60)
}

// `pmset -g` prints a "SleepDisabled  1" line once lid sleep has been switched off.
func sleepDisabled(inPmsetOutput out: String) -> Bool {
    out.split(separator: "\n").contains { line in
        let parts = line.split(whereSeparator: \.isWhitespace)
        return parts.first == "SleepDisabled" && parts.last == "1"
    }
}

// steamcup://on, steamcup://off, steamcup://on?minutes=N, and steamcup://on?pid=N (stay on while that process lives,
// sent by `steamcup run`). Anything else, including a bad number, is ignored.
enum RemoteCommand: Equatable { case on(minutes: Int?), onWhile(pid: Int32), off }

func remoteCommand(_ s: String) -> RemoteCommand? {
    guard let c = URLComponents(string: s), c.scheme?.lowercased() == "steamcup" else { return nil }
    let items = c.queryItems ?? []
    switch c.host?.lowercased() {
    case "off": return .off
    case "on":
        if items.isEmpty { return .on(minutes: nil) }
        guard items.count == 1, let n = items[0].value.flatMap({ Int32($0) }) else { return nil }
        switch items[0].name {
        case "minutes" where (1...10080).contains(n): return .on(minutes: Int(n))
        case "pid" where n > 1: return .onWhile(pid: n)   // 1 is launchd, which never exits
        default: return nil
        }
    default: return nil
    }
}

// `steamcup run [--] <command…>`: the command to run, or nil if these arguments are not a run.
func runCommand(_ args: [String]) -> [String]? {
    guard args.first == "run" else { return nil }
    let rest = args.dropFirst().first == "--" ? args.dropFirst(2) : args.dropFirst()
    return rest.isEmpty ? nil : Array(rest)
}

// A waitpid status as a shell reports it: the command's exit code, or 128 + the signal that ended it.
func shellExitCode(waitStatus s: Int32) -> Int32 {
    s & 0x7f == 0 ? (s >> 8) & 0xff : 128 + (s & 0x7f)
}

// 'it'\''s' — safe inside single quotes in sh/zsh.
func shellQuote(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }

// A double-quoted AppleScript string literal.
func appleScriptLiteral(_ s: String) -> String {
    "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}
