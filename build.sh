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
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
</dict></plist>
PL
swiftc -O -framework Cocoa -framework UserNotifications -framework Carbon -framework IOKit -framework ServiceManagement Rules.swift Power.swift main.swift -o $APP/Contents/MacOS/Steamcup
codesign -s - --force --options runtime $APP
echo "built $APP"
