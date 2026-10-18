import Cocoa
import Carbon
import ServiceManagement
import UserNotifications

// Keeps the Mac awake while on. Left-click the cup (or press ⌃⌥W) to toggle;
// right-click for timers and options. Lid-closed mode additionally switches off lid sleep (see Power.swift).
final class App: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var assertion: IOPMAssertionID?
    var on: Bool { assertion != nil }
    var duration: Int?          // seconds of the running timer; nil = until turned off
    var until: Date?
    var lidActive = false       // we switched lid sleep off for this session
    var notice: String?         // why Steamcup last stopped on its own, shown at the top of the menu
    var ticker: Timer?
    var pausedByLock: (until: Date?, duration: Int?)?   // a session the screen lock paused, to resume on unlock
    var launched = false        // steamcup:// links that arrive before launch finishes wait in pendingURL
    var pendingURL: String?

    let prefs = UserDefaults.standard
    var lidMode: Bool { get { prefs.bool(forKey: "lidMode") } set { prefs.set(newValue, forKey: "lidMode") } }
    var screenMayTurnOff: Bool { get { prefs.bool(forKey: "screenMayTurnOff") } set { prefs.set(newValue, forKey: "screenMayTurnOff") } }
    var sleepOnLock: Bool { get { prefs.bool(forKey: "sleepOnLock") } set { prefs.set(newValue, forKey: "sleepOnLock") } }

    func applicationWillFinishLaunching(_ n: Notification) {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleURL(_:withReply:)),
                                                     forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        item.autosaveName = "SteamcupIcon"   // remembers where the cup sits in the menu bar
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        item.button?.imagePosition = .imageLeft
        item.button?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        // Left over from a crash or forced quit: lid sleep is still off, so switch it back.
        if LidSleep.isOff {
            if !LidSleep.setupDone || !LidSleep.keepAwakeWhenClosed(false) { notice = Self.manualFix }
        }
        UNUserNotificationCenter.current().delegate = self
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(screenLocked), name: .init("com.apple.screenIsLocked"), object: nil)
        dnc.addObserver(self, selector: #selector(screenUnlocked), name: .init("com.apple.screenIsUnlocked"), object: nil)
        registerHotkey()
        refresh()
        launched = true
        if let s = pendingURL { pendingURL = nil; runRemote(s) }
    }

    // steamcup://on, steamcup://off, steamcup://on?minutes=N. Safe to repeat: `on` again only restarts the timer, `off` while off does nothing.
    @objc func handleURL(_ e: NSAppleEventDescriptor, withReply _: NSAppleEventDescriptor) {
        guard let s = e.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else { return }
        if launched { runRemote(s) } else { pendingURL = s }
    }

    func runRemote(_ url: String) {
        switch remoteCommand(url) {
        case .on(let minutes)?: start(for: minutes.map { $0 * 60 })
        case .off?: stop()   // also drops a session paused by screen lock
        case nil: break
        }
    }

    @objc func clicked() {
        let e = NSApp.currentEvent
        if e?.type == .rightMouseUp || e?.modifierFlags.contains(.control) == true {
            item.menu = buildMenu()
            item.button?.performClick(nil)   // shows the menu
            item.menu = nil                  // so the next left-click toggles again
        } else { toggle() }
    }

    @objc func toggle() { on ? stop() : start(for: nil) }
    @objc func startTimed(_ sender: NSMenuItem) { start(for: sender.tag == 0 ? nil : sender.tag) }

    func start(for seconds: Int?) {
        pausedByLock = nil
        notice = nil
        if !on {
            assertion = Assertion.hold(screenMayTurnOff: screenMayTurnOff)
            if !on { notice = "Couldn't keep the Mac awake"; return refresh() }
        }
        duration = seconds
        until = seconds.map { Date().addingTimeInterval(TimeInterval($0)) }
        if lidMode && !lidActive { beginLidSession() }
        ticker?.invalidate()
        // Checks the wall clock, so a timer still ends on time across system sleep. Common mode: keeps ticking while a menu is open.
        let t = Timer(timeInterval: 15, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
        refresh()
    }

    @objc func stop() {
        pausedByLock = nil
        duration = nil
        until = nil
        if let a = assertion { Assertion.release(a); assertion = nil }
        endLidSession()
        // If switching lid sleep back on failed, keep ticking: tick() retries every 15 s until it succeeds.
        if !lidActive { ticker?.invalidate(); ticker = nil }
        refresh()
    }

    static let manualFix = "Lid sleep is still off — run in Terminal: sudo pmset -a disablesleep 0"

    func beginLidSession() {
        let b = Battery.read()
        if let why = lidSafety(thermal: ProcessInfo.processInfo.thermalState, onBattery: b.onBattery, percent: b.percent) {
            notice = "Lid-closed mode paused: \(why.rawValue)"
            return
        }
        lidActive = LidSleep.keepAwakeWhenClosed(true)
        if !lidActive { notice = "Lid-closed mode needs setup again" }
    }

    // Stays lidActive if switching back fails, so quitting retries.
    func endLidSession() {
        guard lidActive else { return }
        if LidSleep.keepAwakeWhenClosed(false) { lidActive = false } else { notice = Self.manualFix }
    }

    func tick() {
        if !on { return stop() }   // only while retrying a failed lid switch-back
        if let u = until, u <= Date() { return stop() }
        if lidActive {
            let b = Battery.read()
            if let why = lidSafety(thermal: ProcessInfo.processInfo.thermalState, onBattery: b.onBattery, percent: b.percent) {
                endLidSession()
                if !lidActive {
                    notice = notice ?? "Lid-closed mode paused: \(why.rawValue)"
                    notify("Steamcup turned off lid-closed mode: \(why.rawValue)")
                }
            }
        }
        refresh()
    }

    // Shown only if the user allowed notifications; otherwise the menu notice is the only trace.
    func notify(_ text: String) {
        let c = UNMutableNotificationContent()
        c.title = "Steamcup"
        c.body = text
        c.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: c, trigger: nil))
    }

    // Steamcup is a regular app, so without this macOS would hide banners while it is frontmost.
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification) async -> UNNotificationPresentationOptions { [.banner, .sound] }

    @objc func screenLocked() {
        guard sleepOnLock, on else { return }
        let p = (until, duration)
        stop()               // clears pausedByLock, so set it after
        pausedByLock = p
    }

    @objc func screenUnlocked() {
        guard let p = pausedByLock else { return }
        pausedByLock = nil
        guard !on, p.until.map({ $0 > Date() }) ?? true else { return }   // a timer that ran out while locked stays off
        start(for: nil)
        duration = p.duration   // keep the original end time, not a fresh timer
        until = p.until
        refresh()
    }

    // MARK: options

    @objc func toggleLidMode() {
        let ready = LidSleep.setupDone
        if lidMode && ready {
            lidMode = false
            endLidSession()
        } else if ready {
            enableLidMode()
        } else {
            installLidSetup()
        }
        refresh()
    }

    // The one admin prompt. Cancel does nothing; any other failure is explained in plain words.
    // Runs in the background so the cup keeps working while the password prompt is up.
    var installing = false
    func installLidSetup() {
        guard !installing else { return }
        let ask = NSAlert()
        ask.messageText = "Set up lid-closed mode?"
        ask.informativeText = "Steamcup will add /etc/sudoers.d/steamcup so your user can run two commands without a password: pmset -a disablesleep 1 and 0. The system prompt will be titled osascript."
        ask.addButton(withTitle: "Continue")
        ask.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard ask.runModal() == .alertFirstButtonReturn else { return }
        installing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = LidSleep.install()
            DispatchQueue.main.async { [self] in
                installing = false
                switch result {
                case .done: enableLidMode()
                case .cancelled: break
                case .failed(let why):
                    let a = NSAlert()
                    a.messageText = "Couldn't set up lid-closed mode"
                    a.informativeText = "\(why)\n\nYou can also run this in Terminal and enter your password:\nsudo zsh \(shellQuote(LidSleep.scriptPath))"
                    NSApp.activate(ignoringOtherApps: true)
                    a.runModal()
                }
                refresh()
            }
        }
    }

    func enableLidMode() {
        lidMode = true
        notice = nil
        if !prefs.bool(forKey: "askedNotify") {   // ask once, the first time lid mode is enabled
            prefs.set(true, forKey: "askedNotify")
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        // After a crash Steamcup only switches lid sleep back when it next starts, so make sure it starts at login.
        if SMAppService.mainApp.status != .enabled {
            do { try SMAppService.mainApp.register() } catch { NSLog("Steamcup: Open at Login failed: \(error)") }
        }
        // Ticking it means "keep my Mac running with the lid shut": turn on right away, not on the next cup click.
        if !on { start(for: nil) } else if !lidActive { beginLidSession() }
        refresh()
    }

    @objc func toggleScreen() {
        screenMayTurnOff.toggle()
        if let old = assertion {   // swap the assertion type in place, keeping the timer
            assertion = Assertion.hold(screenMayTurnOff: screenMayTurnOff)
            Assertion.release(old)
            if !on { stop(); notice = "Couldn't keep the Mac awake" }
        }
        refresh()
    }

    @objc func toggleSleepOnLock() { sleepOnLock.toggle(); if !sleepOnLock { pausedByLock = nil } }

    @objc func toggleLogin() {
        let s = SMAppService.mainApp
        if s.status == .requiresApproval { return SMAppService.openSystemSettingsLoginItems() }
        do { try s.status == .enabled ? s.unregister() : s.register() } catch {
            let a = NSAlert()
            a.messageText = "Couldn't change Open at Login"
            a.informativeText = "\(error.localizedDescription)\n\nMoving Steamcup into your Applications folder usually fixes this."
            a.runModal()
        }
    }

    // MARK: looks

    func refresh() {
        let name = !on ? "menubar-off" : lidActive ? "menubar-lid" : "menubar-on"
        let img = NSImage(named: name)
        img?.isTemplate = true
        img?.size = NSSize(width: 18, height: 18)
        item.button?.image = img
        item.button?.title = until.map { " " + remainingText($0.timeIntervalSinceNow) } ?? ""
        item.button?.toolTip = on ? headline() : "Click to keep your Mac awake · Right-click for timers and options"
        item.button?.setAccessibilityLabel(!on ? "Steamcup: off" : lidActive ? "Steamcup: on, even with the lid closed" : "Steamcup: on")
    }

    func headline() -> String {
        guard on else { return "Steamcup is off — your Mac sleeps as usual" }
        guard let u = until else { return "Keeping your Mac awake" }
        let f = DateFormatter()
        f.timeStyle = .short
        return "Keeping your Mac awake until \(f.string(from: u))"
    }

    func buildMenu() -> NSMenu {
        let m = NSMenu()
        m.autoenablesItems = false
        func add(_ title: String, _ action: Selector?, checked: Bool = false, tag: Int = 0, enabled: Bool = true) -> NSMenuItem {
            let i = m.addItem(withTitle: title, action: action, keyEquivalent: "")
            i.target = self
            i.state = checked ? .on : .off
            i.tag = tag
            i.isEnabled = enabled && action != nil
            return i
        }

        _ = add(headline(), nil)
        if on && lidActive { _ = add("Even with the lid closed", nil) }
        if let n = notice { _ = add("⚠︎ " + n, nil) }
        // Checked on every menu open, so the warning stays until it is fixed, also after a relaunch.
        switch lidMode ? SMAppService.mainApp.status : .enabled {
        case .enabled: break
        case .requiresApproval: _ = add("⚠︎ Allow Steamcup in System Settings → Login Items (crash recovery needs it)", nil)
        default: _ = add("⚠︎ Open at Login is off — move Steamcup to Applications (crash recovery needs it)", nil)
        }
        m.addItem(.separator())

        for (title, secs) in [("Until I turn it off", 0), ("For 30 minutes", 1800), ("For 1 hour", 3600), ("For 2 hours", 7200), ("For 4 hours", 14400), ("For 8 hours", 28800)] {
            _ = add(title, #selector(startTimed(_:)), checked: on && (duration ?? 0) == secs, tag: secs)
        }
        if on {
            let off = add("Turn Off", #selector(stop))
            off.keyEquivalent = "w"
            off.keyEquivalentModifierMask = [.control, .option]
        }
        m.addItem(.separator())

        let ready = LidSleep.setupDone
        _ = add(ready ? "Keep Awake with Lid Closed" : "Keep Awake with Lid Closed…", #selector(toggleLidMode), checked: lidMode && ready)
        _ = add("Let the Screen Turn Off", #selector(toggleScreen), checked: screenMayTurnOff)
        _ = add("Sleep When Screen Locks", #selector(toggleSleepOnLock), checked: sleepOnLock)
        _ = add("Open at Login", #selector(toggleLogin), checked: SMAppService.mainApp.status == .enabled)
        m.addItem(.separator())

        let quit = m.addItem(withTitle: "Quit Steamcup", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.isEnabled = true
        return m
    }

    // Dock: the menu-bar cup can hide behind the notch, so the Dock icon's right-click menu has everything.
    // (A Dock click and a re-open from Finder/Spotlight look the same to the app, so neither toggles.)
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let m = buildMenu()
        m.removeItem(at: m.numberOfItems - 1)   // Quit — the Dock adds its own
        m.removeItem(at: m.numberOfItems - 1)   // and the separator above it
        return m
    }
    func applicationWillTerminate(_ n: Notification) { stop() }

    // Global hotkey ⌃⌥W via Carbon (no Accessibility permission needed).
    func registerHotkey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
            app.toggle()
            return noErr
        }, 1, &spec, nil, nil)
        var ref: EventHotKeyRef?
        let r = RegisterEventHotKey(UInt32(kVK_ANSI_W), UInt32(controlKey | optionKey), EventHotKeyID(signature: 0x41574B45, id: 1),
                                    GetApplicationEventTarget(), 0, &ref)
        if r != noErr { NSLog("Steamcup: ⌃⌥W hotkey is taken by another app (\(r))") }
    }
}

let app = App()
// `kill` or logout skips applicationWillTerminate; catch the signal so lid sleep is always switched back.
let signals = [SIGTERM, SIGINT, SIGHUP].map { sig -> DispatchSourceSignal in
    signal(sig, SIG_IGN)
    let s = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    s.setEventHandler { app.stop(); exit(0) }
    s.resume()
    return s
}
NSApplication.shared.setActivationPolicy(.regular)
NSApplication.shared.delegate = app
NSApplication.shared.run()
