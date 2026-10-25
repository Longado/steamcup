# Install Steamcup on this Mac

Steamcup is a macOS menu bar app that keeps the Mac awake, including with the lid closed when that mode is enabled. It requires macOS 14 or newer. It does not support Linux or Windows.

1. Read the current installation and permission notes: https://github.com/Longado/steamcup/blob/main/README.zh-CN.md
2. Check the operating system. On a supported Mac, download and inspect https://longado.github.io/steamcup/install.sh, then run the inspected script with `/bin/bash`. The installer downloads the published v1.3.2 app, verifies its SHA-256, and installs it to `~/Applications`. It does not require Xcode.
3. If Steamcup is already installed, stop and tell the user where it is. Do not delete or overwrite it automatically.
4. Tell the user where the app was installed and ask them to open it. If macOS blocks the app, guide the user to System Settings → Privacy & Security → Open Anyway. Do not remove quarantine attributes or disable Gatekeeper.
5. Tell the user to click the menu bar cup to start or stop keeping the Mac awake. Do not enable lid-closed mode, change sleep settings, or grant administrator permissions automatically. The user can choose that mode in the app.

The app is free and MIT licensed. Current downloads include Apple Silicon and Intel builds; hands-on verification is on an Apple Silicon Mac running macOS 26. Other supported configurations remain to be tested.
