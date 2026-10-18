#!/bin/zsh
# One-time setup for Steamcup's lid-closed mode. Run:  sudo zsh setup-lid-mode.sh
# (Steamcup itself runs it as root without sudo and passes your user name as the first argument.)
# Lets your user run exactly two commands without a password — nothing else:
#   pmset -a disablesleep 1   (lid closed → keep running)
#   pmset -a disablesleep 0   (back to normal)
# Undo:  sudo pmset -a disablesleep 0 && sudo rm /etc/sudoers.d/steamcup
set -e
export PATH=/usr/bin:/bin:/usr/sbin:/sbin   # runs as root: only system tools, never ones from the user's PATH
umask 077
[[ $EUID -eq 0 ]] || { echo "Run with sudo:  sudo zsh $0"; exit 1; }
U=${SUDO_USER:-${1:-}}
[[ $U =~ '^[A-Za-z0-9._-]+$' && $U != root ]] && id -u "$U" >/dev/null 2>&1 \
  || { echo "Run with sudo from your own account, or pass your user name:  sudo zsh $0 <user>"; exit 1; }
# Built inside the root-only folder (sudo ignores names starting with "."), checked, then renamed into place in one step.
TMP=$(mktemp /etc/sudoers.d/.steamcup.XXXXXX)
trap 'rm -f "$TMP"' EXIT
echo "$U ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 1, /usr/bin/pmset -a disablesleep 0" > "$TMP"
visudo -cf "$TMP" >/dev/null || { echo "Rule failed the sudoers check — nothing installed."; exit 1; }
chown root:wheel "$TMP"
chmod 440 "$TMP"
mv -f "$TMP" /etc/sudoers.d/steamcup
echo "Done. Steamcup can now keep your Mac running with the lid closed (for user $U)."
