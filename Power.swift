import Foundation
import IOKit.pwr_mgt
import IOKit.ps

// "Don't idle-sleep" power assertion — the same mechanism as `caffeinate`.
enum Assertion {
    static func hold(screenMayTurnOff: Bool) -> IOPMAssertionID? {
        let type = screenMayTurnOff ? kIOPMAssertionTypePreventUserIdleSystemSleep : kIOPMAssertionTypePreventUserIdleDisplaySleep
        var id: IOPMAssertionID = 0
        let r = IOPMAssertionCreateWithName(type as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), "Steamcup is on" as CFString, &id)
        if r != kIOReturnSuccess { NSLog("Steamcup: power assertion failed (\(r))"); return nil }
        return id
    }
    static func release(_ id: IOPMAssertionID) { IOPMAssertionRelease(id) }
}

// Lid sleep can only be switched off system-wide (`pmset disablesleep`, root only).
// setup-lid-mode.sh grants exactly these two pmset commands via sudoers, so `sudo -n` never prompts.
enum LidSleep {
    static var setupDone: Bool { run("/usr/bin/sudo", ["-n", "-l", "/usr/bin/pmset", "-a", "disablesleep", "1"]).ok }
    static var isOff: Bool { sleepDisabled(inPmsetOutput: run("/usr/bin/pmset", ["-g"]).out) }

    static var scriptPath: String { Bundle.main.path(forResource: "setup-lid-mode", ofType: "sh") ?? "setup-lid-mode.sh" }

    enum Install { case done, cancelled, failed(String) }

    // One admin password prompt: runs the bundled setup script as root. It gets no SUDO_USER here, so we pass the user name.
    // Blocks until the prompt is answered, so call it off the main thread (osascript, since NSAppleScript is main-thread only).
    static func install() -> Install {
        let cmd = "/bin/zsh \(shellQuote(scriptPath)) \(shellQuote(NSUserName()))"
        let r = run("/usr/bin/osascript", ["-e", "do shell script \(appleScriptLiteral(cmd)) with administrator privileges"], timeout: nil)
        if !r.ok { return r.out.contains("(-128)") ? .cancelled : .failed(r.out.trimmingCharacters(in: .whitespacesAndNewlines)) }
        return setupDone ? .done : .failed("The permission was not installed.")
    }

    @discardableResult
    static func keepAwakeWhenClosed(_ on: Bool) -> Bool {
        let r = run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", on ? "1" : "0"])
        if !r.ok { NSLog("Steamcup: pmset disablesleep \(on ? 1 : 0) failed: \(r.out)") }
        return r.ok
    }

    private static func run(_ path: String, _ args: [String], timeout: Double? = 5) -> (ok: Bool, out: String) {
        let p = Process()
        let pipe = Pipe()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        p.standardInput = FileHandle.nullDevice
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return (false, "\(error)") }
        // Most calls run on the main thread: never let a stuck sudo/pmset freeze the menu bar.
        if let t = timeout { DispatchQueue.global().asyncAfter(deadline: .now() + t) { if p.isRunning { p.terminate() } } }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus == 0, String(decoding: data, as: UTF8.self))
    }
}

enum Battery {
    // (onBattery, percent). Desktops without a battery read as plugged in at 100%.
    static func read() -> (onBattery: Bool, percent: Int) {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let list = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
        for src in list {
            guard let d = IOPSGetPowerSourceDescription(info, src)?.takeUnretainedValue() as? [String: Any],
                  let cur = d[kIOPSCurrentCapacityKey] as? Int, let max = d[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
            return (d[kIOPSPowerSourceStateKey] as? String == kIOPSBatteryPowerValue, cur * 100 / max)
        }
        return (false, 100)
    }
}
