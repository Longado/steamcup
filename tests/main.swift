// swiftc Rules.swift tests/main.swift -o /tmp/steamcup-tests && /tmp/steamcup-tests
import Foundation

assert(lidSafety(thermal: .nominal, onBattery: false, percent: 3) == nil, "plugged in at 3% is fine")
assert(lidSafety(thermal: .fair, onBattery: true, percent: 11) == nil)
assert(lidSafety(thermal: .nominal, onBattery: true, percent: 10) == .lowBattery)
assert(lidSafety(thermal: .serious, onBattery: false, percent: 90) == .hot)
assert(lidSafety(thermal: .critical, onBattery: true, percent: 5) == .hot, "heat wins over battery")

assert(remainingText(3600) == "1:00")
assert(remainingText(3599) == "1:00")
assert(remainingText(61) == "0:02")
assert(remainingText(5) == "0:01")
assert(remainingText(0) == "0:01", "never shows 0:00 while still on")
assert(remainingText(4 * 3600 - 30) == "4:00")

let sample = "System-wide power settings:\n SleepDisabled\t\t1\nCurrently in use:\n standby              1\n"
assert(sleepDisabled(inPmsetOutput: sample))
assert(!sleepDisabled(inPmsetOutput: sample.replacingOccurrences(of: "SleepDisabled\t\t1", with: "SleepDisabled\t\t0")))
assert(!sleepDisabled(inPmsetOutput: "Currently in use:\n standby 1\n"))

assert(shellQuote("/a b/c.sh") == "'/a b/c.sh'")
assert(shellQuote("it's") == "'it'\\''s'")
assert(appleScriptLiteral("a\"b\\c") == "\"a\\\"b\\\\c\"")

assert(remoteCommand("steamcup://on") == .on(minutes: nil))
assert(remoteCommand("steamcup://off") == .off)
assert(remoteCommand("steamcup://on?minutes=90") == .on(minutes: 90))
assert(remoteCommand("STEAMCUP://On?minutes=1") == .on(minutes: 1))
for bad in ["steamcup://on?minutes=0", "steamcup://on?minutes=-5", "steamcup://on?minutes=abc", "steamcup://on?minutes=", "steamcup://on?minutes=10081",
            "steamcup://on?hours=2", "steamcup://on?minutes=5&lid=1", "steamcup://toggle", "other://on", "steamcup://"] {
    assert(remoteCommand(bad) == nil, bad)
}

print("all rules ok")
