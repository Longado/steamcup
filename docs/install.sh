#!/bin/bash
# Install the published Mac app. No administrator access or sleep settings change.
set -euo pipefail

fail() { printf 'Steamcup: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || fail '需要 macOS 14 或更新版本。'
steamcup_macos=$(sw_vers -productVersion)
[ "${steamcup_macos%%.*}" -ge 14 ] || fail '需要 macOS 14 或更新版本。'

steamcup_target=${STEAMCUP_INSTALL_DIR:-"$HOME/Applications"}
steamcup_destination="$steamcup_target/Steamcup.app"
if [ -e "$steamcup_destination" ] || [ -L "$steamcup_destination" ]; then
  fail "已有安装：${steamcup_destination}。请先退出并按版本页说明更新。"
fi
if [ -z "${STEAMCUP_INSTALL_DIR+x}" ] && { [ -e /Applications/Steamcup.app ] || [ -L /Applications/Steamcup.app ]; }; then
  fail '已有安装：/Applications/Steamcup.app。请先退出并按版本页说明更新。'
fi

steamcup_temp=$(mktemp -d "${TMPDIR:-/tmp}/steamcup-install.XXXXXX")
trap 'rm -rf "$steamcup_temp"' EXIT

printf '下载 Steamcup v1.3.2…\n'
curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
  'https://github.com/Longado/steamcup/releases/download/v1.3.2/Steamcup.zip' \
  --output "$steamcup_temp/Steamcup.zip"
printf '%s  %s\n' \
  '5fca8da13b0bc1aad795dca1881f90c566c4d634ec0bc4202fd54b0d59374d2c' \
  "$steamcup_temp/Steamcup.zip" | shasum -a 256 -c - >/dev/null

ditto -x -k "$steamcup_temp/Steamcup.zip" "$steamcup_temp"
steamcup_app="$steamcup_temp/Steamcup.app"
[ -x "$steamcup_app/Contents/MacOS/Steamcup" ] || fail '下载包缺少 Steamcup 应用。'
[ "$(defaults read "$steamcup_app/Contents/Info" CFBundleIdentifier)" = com.longado.steamcup ] \
  || fail '下载包的应用标识不正确。'

# curl does not set quarantine; retain Apple's first-launch checks for this download.
printf -v steamcup_timestamp '%x' "$(date +%s)"
xattr -w com.apple.quarantine "0081;$steamcup_timestamp;SteamcupInstaller;" "$steamcup_app"

mkdir -p "$steamcup_target"
if [ -e "$steamcup_destination" ] || [ -L "$steamcup_destination" ]; then
  fail "已有安装：${steamcup_destination}。未覆盖。"
fi
ditto "$steamcup_app" "$steamcup_destination"

printf '\n已安装到 %s\n' "$steamcup_destination"
printf '在访达中打开 Steamcup.app。若 macOS 阻止打开，请按仓库说明前往「系统设置 → 隐私与安全性 → 仍要打开」。\n'
printf '安装不会开启合盖模式；需要时在应用菜单中选择，并确认系统授权。\n'
