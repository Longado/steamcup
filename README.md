<p align="center"><img src="icon/icon-1024.png" width="112" alt="Steamcup"></p>

<h1 align="center">Steamcup</h1>
<p align="center"><strong>A pixel coffee cup in your menu bar that keeps your Mac awake, even with the lid closed.</strong></p>
<p align="center">Close the laptop and walk away while a build, render or agent run finishes. Runs on macOS 14 and later, on Apple Silicon and Intel.</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue" alt="MIT"></a>
  <img src="https://img.shields.io/badge/tested%20on-macOS%2026-black" alt="tested on macOS 26">
  <img src="https://img.shields.io/badge/Swift-6-orange" alt="Swift 6">
  <img src="https://img.shields.io/badge/status-Alpha-orange" alt="Alpha">
</p>

<p align="center">
  <a href="README.zh-CN.md">中文</a> ·
  <a href="docs/media/steamcup-explainer.mp4">How it works (1.5 min video)</a> ·
  <a href="docs/media/steamcup-intro.mp4">Intro (12 s)</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="#build-with-us">Build with us</a>
</p>

<p align="center"><img src="docs/media/steamcup-hero.gif" width="960" alt="Steamcup: keeps your Mac awake, even with the lid closed. Feature illustration."></p>

Most keep-awake apps stop at "don't idle-sleep", so the Mac still sleeps the moment you close the lid. **Steamcup keeps it running with the lid shut, and switches lid sleep back on when it stops, or within a minute if it crashes.**

**One click to turn it on. One password prompt to set up lid mode. Switches itself off when the Mac gets hot or the battery runs low.**

**Or from Terminal: `steamcup run -- <command>` keeps the Mac awake, lid closed too, until that command finishes.**

## What it is

A native macOS menu bar app of about 600 lines of Swift, with no dependencies. Click the cup and your Mac stays awake: the cup fills and steams. Click again and it sleeps as usual. Right-click for timers and options.

Closing the lid puts a MacBook to sleep whatever apps ask. The only way around that is a system-wide switch, `pmset disablesleep`, which needs admin rights. Steamcup flips that switch only while it is on. It flips it back when:
- you turn it off, a timer ends, or you quit
- the Mac gets too hot or the battery drops to 10%
- within a minute, if Steamcup crashes or is force-quit (a small background check does it)

> **Early version.** Tested by hand on one Apple Silicon MacBook running macOS 26 (the download also runs on Intel Macs and macOS 14+, but nobody has tried those yet): on/off, timers, lid mode on and off, quit and forced quit (lid sleep came back 55 s after `kill -9`), a timer ending with the lid shut (the Mac went to sleep, and woke normally), screen-lock pause, `steamcup run` (on while the command runs, off the moment it ends, Ctrl-C). Not yet tested: macOS 14–15, Intel Macs, the heat and low-battery stops firing for real. See [Known issues](#known-issues).

## How it works

| You… | Steamcup… |
| --- | --- |
| click the cup | keeps the Mac and screen awake (a power assertion, like `caffeinate -d`); click again to stop |
| right-click → For 30 minutes … 8 hours | shows the time left beside the cup (`0:30`) and stops by itself at the end, even across sleep |
| tick **Keep Awake with Lid Closed** | the first time, asks for your admin password once and adds a background check for crash recovery; turns Steamcup on with a padlock on the cup, and the lid no longer sleeps the Mac (the screen still goes dark, the Mac keeps running) |
| close the lid on a hot Mac, or on battery at 10% | stops lid mode within 15 seconds and posts a notification |
| tick **Let the Screen Turn Off** | lets the display sleep while the Mac keeps running |
| tick **Sleep When Screen Locks** | lets go when you lock the screen, and picks up again on unlock with the same end time |
| press **⌃⌥W** anywhere | toggles, handy when the notch hides the cup |
| run `steamcup run -- make build` in Terminal ([set up the command](#command-line)) | keeps the Mac awake until the command ends, then lets go; uses lid mode if you ticked it. Ctrl-C and the command's exit code pass straight through |
| run `open -g 'steamcup://on?minutes=120'` from a script or Shortcut | turns on for 2 hours (`steamcup://on` until off, `steamcup://off` to stop); uses lid mode if you ticked it |

## Try these

- Click the cup, then run `pmset -g assertions | grep Steamcup` in Terminal → you see `Steamcup is on`. Click again → it's gone.
- Right-click → **For 30 minutes** → `0:30` appears beside the cup and counts down.
- Tick **Keep Awake with Lid Closed** (the cup turns on with a padlock), run `pmset -g | grep SleepDisabled` → `SleepDisabled 1`. Click the cup off → the line is gone.
- With lid mode on, start some music and close the lid for 30 seconds → the music keeps playing.
- Run `steamcup run -- sleep 20`, then in another window `pmset -g assertions | grep Steamcup` → on. 20 seconds later → gone.

## Is it safe?

- **What the admin step allows:** it adds one file, `/etc/sudoers.d/steamcup`, that lets your user run exactly two commands without a password: `pmset -a disablesleep 1` and `pmset -a disablesleep 0`. Nothing else. The rule is checked with `visudo` before it is installed. Read [setup-lid-mode.sh](setup-lid-mode.sh), all 24 lines.
- **What the prompt runs:** the copy of `setup-lid-mode.sh` inside the app. To check it matches the one on GitHub: `diff /Applications/Steamcup.app/Contents/Resources/setup-lid-mode.sh <(curl -s https://raw.githubusercontent.com/Longado/steamcup/main/setup-lid-mode.sh)` prints nothing when they are the same.
- **Who can use those two commands:** any program run as your user can use them without a password, not only Steamcup.
- **Only its own switch:** Steamcup records when it switches lid sleep off, and only ever switches back what it switched off. If you ran `sudo pmset -a disablesleep 1` yourself, it leaves that alone.
- **Heat and battery:** a closed MacBook in a bag can get hot. Steamcup checks every 15 seconds while lid mode is on, and stops if macOS reports the Mac as seriously hot or the battery drops to 10%. Not yet seen on real hardware.
- **Lid already shut:** when lid sleep comes back while the lid is shut (a timer ends, heat, low battery, a crash), Steamcup asks the Mac to sleep with `pmset sleepnow`, unless an external display is keeping it in clamshell mode. Tried with a timer ending and the lid shut.
- **Crash or force-quit:** ticking lid mode adds a background check, `~/Library/LaunchAgents/com.longado.steamcup.recovery.plist`. launchd runs it every minute: if Steamcup is gone and left lid sleep off, it switches it back. It does not catch a Steamcup that hangs without quitting. Unticking lid mode removes it.
- **Links:** a `steamcup://on` link can turn Steamcup on, with lid mode if you ticked it. Your browser asks before opening one, and the heat and battery stops still apply.
- **Remove everything:**
  1. Quit Steamcup.
  2. Untick **Keep Awake with Lid Closed** (removes the background check) and **Open at Login**. If Steamcup is already gone: `launchctl bootout gui/$(id -u)/com.longado.steamcup.recovery; rm ~/Library/LaunchAgents/com.longado.steamcup.recovery.plist`
  3. `sudo pmset -a disablesleep 0 && sudo rm /etc/sudoers.d/steamcup`
  4. `defaults delete com.longado.steamcup`
  5. Delete the app.
- **Network:** Steamcup makes no network requests.

## Compared with

| | Steamcup | [Insomnia](https://github.com/krishhgg/Insomnia) | [Adrafinil](https://github.com/kageroumado/adrafinil) | [KeepingYouAwake](https://github.com/newmarcel/KeepingYouAwake) | [Amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12) |
| --- | --- | --- | --- | --- | --- |
| Price / source | Free, MIT | Free, MIT | Free, MIT | Free, MIT | Free, closed source |
| Runs on | macOS 14+, Apple Silicon and Intel | macOS 26+, Apple Silicon | macOS 26.4+ ([backport for 15](https://github.com/valentine/adrafinil)) | macOS 10.13+ | macOS 10.13+ |
| Lid closed | Yes, one password prompt | Yes | Yes, privileged helper | No ([#258](https://github.com/newmarcel/KeepingYouAwake/issues/258), [#262](https://github.com/newmarcel/KeepingYouAwake/issues/262)) | Yes; on Apple Silicon needs the separate Power Protect add-on |
| Lid sleep back after a crash | Within a minute | Yes, a recovery agent every minute | Releases abandoned holds | Not needed | Not that we found |
| Awake until a command ends | `steamcup run -- <command>` | Not that we found | `adrafinil hold --pid` | No | "While an app runs" trigger |
| Coding-agent hooks | No | No | Claude Code, Codex, Cursor and 7 more | No | No |

On macOS 26 with coding agents, Adrafinil does more. Steamcup is for lid-closed work on macOS 14 and 15 and on Intel Macs, and for any command, not just agents.

## Quick start

### Option A: download

1. Download [Steamcup.zip](https://github.com/Longado/steamcup/releases/latest/download/Steamcup.zip) from the [latest release](https://github.com/Longado/steamcup/releases/latest) and unzip it.
2. Drag `Steamcup.app` to your Applications folder.
3. Double-click it. The cup appears at the top right of the menu bar: click it to turn on or off, right-click or Control-click it for timers. If the notch hides it, click Steamcup's Dock icon for the same menu, or press ⌃⌥W.

The app is not notarized yet, so macOS blocks the first open (on macOS 15 and later the old right-click → Open shortcut no longer works). To get past it:

1. Double-click Steamcup and click **Done**, not **Move to Trash**.
2. Open **System Settings → Privacy & Security** and click **Open Anyway** ([Apple's guide](https://support.apple.com/en-us/102445)).
3. Confirm with your password.

The Open Anyway button only shows for about an hour after step 1.

### Option B: let your AI install it

Paste this into Claude Code or Codex:

```text
Install Steamcup for me from https://github.com/Longado/steamcup.
1. Read its README first.
2. Check `xcode-select -p` works and macOS is 14 or later.
3. Clone it, run ./build.sh, and move Steamcup.app to /Applications.
4. Open it. If macOS says it can't verify the developer, tell me to open
   System Settings → Privacy & Security and click "Open Anyway".
5. Tell me to click the cup in the menu bar to try it, and that lid mode
   asks for my admin password once when I first tick it.
```

### Option C: build it yourself

Needs the Xcode command-line tools (`xcode-select --install`) and macOS 14 or later.

```sh
git clone https://github.com/Longado/steamcup
cd steamcup
./build.sh
mv Steamcup.app /Applications/
open /Applications/Steamcup.app
```

### Command line

The app's own binary is the `steamcup` command. Add it to your shell once:

```sh
echo "alias steamcup='/Applications/Steamcup.app/Contents/MacOS/Steamcup'" >> ~/.zshrc && source ~/.zshrc
steamcup run -- ffmpeg -i talk.mov talk.mp4
```

`steamcup run` starts Steamcup if it isn't running. If Steamcup is already on until you turn it off, it stays on after the command. If you pick a timer or turn Steamcup off while a command runs, your choice wins.

## Known issues

- Clicking the Dock icon shows the menu instead of toggling, because macOS reports a Dock click and a re-open from Finder or Spotlight the same way.
- If Steamcup hangs without quitting, lid sleep stays off: the background check only steps in once it has quit (see [Is it safe?](#is-it-safe)).
- The heat and low-battery stops are tested as logic; neither has been seen firing on a real hot or drained Mac yet.

## Build with us

**Can a keep-awake app be trusted with the lid closed?** Steamcup tries to answer that with a tiny, readable codebase and hard safety stops.

| If you like… | You could… |
| --- | --- |
| testing on other Macs | try macOS 14–15 or an Intel MacBook and report what happens |
| macOS internals | catch a hung Steamcup, or find out whether `pmset disablesleep` survives a restart |
| scripting | build on the `steamcup://` URL scheme (`on`, `off`, `on?minutes=N`), e.g. `open 'steamcup://on?minutes=120'` from Shortcuts or a script |
| pixel art | improve the 18 px menu bar icons in `icon/make_menubar.py` |
| writing | translate the few menu strings |

Issues and pull requests are welcome.

## Development

```sh
./build.sh                                   # builds Steamcup.app (Apple Silicon + Intel, macOS 14+), ad-hoc signed
ditto -c -k --norsrc --noextattr --keepParent Steamcup.app Steamcup.zip   # release zip
swiftc Rules.swift tests/main.swift -o /tmp/steamcup-tests && /tmp/steamcup-tests
swiftc Rules.swift tests/recovery/main.swift -o /tmp/steamcup-recovery && /tmp/steamcup-recovery
swiftc Rules.swift tests/run/main.swift -o /tmp/steamcup-run && /tmp/steamcup-run
python3 icon/make_icon.py                    # app icon
python3 icon/make_menubar.py                 # menu bar icons (off / on / lid)
```

`main.swift` is the menu bar app, `Power.swift` holds the power assertion, the lid-sleep switch and the battery reading, and `Rules.swift` holds the pure decisions the tests check.

## License

[MIT](LICENSE) © Yutai Lin
