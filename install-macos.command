#!/bin/bash
# Double-click in Finder. If macOS blocks it the first time: right-click > Open,
# or run once in Terminal:  chmod +x install-macos.command
DIR="$(cd "$(dirname "$0")" && pwd)"
/bin/bash "$DIR/scripts/menu.sh"
echo
read -n 1 -s -r -p "Press any key to close..."
echo
