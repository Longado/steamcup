#!/bin/zsh
# Builds Steamcup.app (no Xcode project) and ad-hoc signs it. Needs Xcode command-line tools.
set -e
cd "$(dirname "$0")"
APP=Steamcup.app
mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
cp icon/AppIcon.icns $APP/Contents/Resources/   # regenerate with: python3 icon/make_icon.py
cp icon/menubar-*.png $APP/Contents/Resources/  # regenerate with: python3 icon/make_menubar.py
cp setup-lid-mode.sh $APP/Contents/Resources/
cat > $APP/Contents/Info.plist <<'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.longado.steamcup</string>
<key>CFBundleName</key><string>Steamcup</string>
<key>CFBundleExecutable</key><string>Steamcup</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.2</string>
<key>CFBundleVersion</key><string>4</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>CFBundleURLTypes</key><array><dict>
<key>CFBundleURLName</key><string>com.longado.steamcup</string>
<key>CFBundleURLSchemes</key><array><string>steamcup</string></array>
</dict></array>
</dict></plist>
PL
# The background check (crash recovery for lid mode), registered by the app with SMAppService.agent.
mkdir -p $APP/Contents/Library/LaunchAgents
cat > $APP/Contents/Library/LaunchAgents/com.longado.steamcup.watchdog.plist <<'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Label</key><string>com.longado.steamcup.watchdog</string>
<key>BundleProgram</key><string>Contents/MacOS/Steamcup</string>
<key>ProgramArguments</key><array><string>Steamcup</string><string>--watchdog</string></array>
<key>StartInterval</key><integer>60</integer>
<key>RunAtLoad</key><true/>
<key>ProcessType</key><string>Background</string>
<key>AssociatedBundleIdentifiers</key><array><string>com.longado.steamcup</string></array>
</dict></plist>
PL
# One binary for Apple Silicon and Intel, runnable from macOS 14 (swiftc otherwise targets only this Mac's chip and OS).
for arch in arm64 x86_64; do
  swiftc -O -target $arch-apple-macos14.0 -framework Cocoa -framework UserNotifications -framework Carbon -framework IOKit -framework ServiceManagement \
    Rules.swift Power.swift main.swift -o .build-$arch
done
lipo -create .build-arm64 .build-x86_64 -output $APP/Contents/MacOS/Steamcup
rm -f .build-arm64 .build-x86_64
codesign -s - --force --options runtime $APP
echo "built $APP"
