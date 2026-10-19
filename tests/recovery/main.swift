// swiftc Rules.swift tests/recovery/main.swift -o /tmp/steamcup-recovery && /tmp/steamcup-recovery
import Foundation

// While Steamcup runs, it looks after its own session.
assert(recoveryStep(ours: true, sleepDisabled: true, appRunning: true) == .nothing)
// Gone, and it left lid sleep off: switch it back.
assert(recoveryStep(ours: true, sleepDisabled: true, appRunning: false) == .switchBack)
// Gone, lid sleep already back: just forget the record.
assert(recoveryStep(ours: true, sleepDisabled: false, appRunning: false) == .forget)
// Someone else switched lid sleep off (sudo pmset by hand): leave it alone.
assert(recoveryStep(ours: false, sleepDisabled: true, appRunning: false) == .nothing)
assert(recoveryStep(ours: false, sleepDisabled: false, appRunning: false) == .nothing)

print("recovery rules ok")
