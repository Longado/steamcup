// swiftc Rules.swift tests/run/main.swift -o /tmp/steamcup-run && /tmp/steamcup-run
import Foundation

// `steamcup run -- <command>` arguments: everything after "run" (and an optional "--") is the command.
assert(runCommand(["run", "--", "ffmpeg", "-i", "a.mov", "b.mp4"]) == ["ffmpeg", "-i", "a.mov", "b.mp4"])
assert(runCommand(["run", "make", "build"]) == ["make", "build"])
assert(runCommand(["run", "--", "--version"]) == ["--version"], "only the first -- is ours")
assert(runCommand(["run"]) == nil)
assert(runCommand(["run", "--"]) == nil)
assert(runCommand(["--watchdog"]) == nil)
assert(runCommand([]) == nil)

// The link the command line sends to the app: stay on while that process lives.
assert(remoteCommand("steamcup://on?pid=4242") == .onWhile(pid: 4242))
for bad in ["steamcup://on?pid=0", "steamcup://on?pid=1", "steamcup://on?pid=-7", "steamcup://on?pid=abc",
            "steamcup://on?pid=99999999999", "steamcup://on?pid=5&minutes=3", "steamcup://off?pid=5"] {
    assert(remoteCommand(bad) == nil || remoteCommand(bad) == .off, bad)
}
assert(remoteCommand("steamcup://off?pid=5") == .off, "off ignores extras, as before")
assert(remoteCommand("steamcup://on?minutes=90") == .on(minutes: 90), "minutes still work")

// Exit code passed on like a shell does: the command's own, or 128 + the signal that ended it.
assert(shellExitCode(waitStatus: 0) == 0)
assert(shellExitCode(waitStatus: 3 << 8) == 3)
assert(shellExitCode(waitStatus: 2) == 130, "Ctrl-C")
assert(shellExitCode(waitStatus: 9) == 137, "kill -9")

print("run rules ok")
