// swiftc Rules.swift tests/watchdog/main.swift -o /tmp/steamcup-watchdog && /tmp/steamcup-watchdog
import Foundation

// Steamcup running but maybe frozen: heat or a low battery while its lid sleep switch is off brings lid sleep back.
assert(watchdogStep(ours: true, sleepDisabled: true, appRunning: true, unsafe: true) == .switchBack)
// Running and safe: it handles its own session.
assert(watchdogStep(ours: true, sleepDisabled: true, appRunning: true, unsafe: false) == .nothing)
// Running, lid sleep already back on: don't clear its record, it may be mid-switch.
assert(watchdogStep(ours: true, sleepDisabled: false, appRunning: true, unsafe: true) == .nothing)
// Someone else switched lid sleep off: leave it alone, hot or not.
assert(watchdogStep(ours: false, sleepDisabled: true, appRunning: true, unsafe: true) == .nothing)
assert(watchdogStep(ours: false, sleepDisabled: true, appRunning: false, unsafe: true) == .nothing)
// Gone: as before, whatever the heat.
assert(watchdogStep(ours: true, sleepDisabled: true, appRunning: false, unsafe: false) == .switchBack)
assert(watchdogStep(ours: true, sleepDisabled: false, appRunning: false, unsafe: false) == .forget)

print("watchdog rules ok")
