import Foundation

// Pure decisions, kept apart so tests/main.swift can check them without the app.

enum LidStop: String { case hot = "the Mac got too hot", lowBattery = "the battery is low" }

// Lid-closed mode stops itself when a closed MacBook is likely cooking or about to die.
func lidSafety(thermal: ProcessInfo.ThermalState, onBattery: Bool, percent: Int) -> LidStop? {
    if thermal == .serious || thermal == .critical { return .hot }
    if onBattery && percent <= 10 { return .lowBattery }
    return nil
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

// 'it'\''s' — safe inside single quotes in sh/zsh.
func shellQuote(_ s: String) -> String { "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'" }

// A double-quoted AppleScript string literal.
func appleScriptLiteral(_ s: String) -> String {
    "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}
