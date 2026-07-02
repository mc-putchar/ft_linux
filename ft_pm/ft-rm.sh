#!/usr/bin/env bash
set -e

# Package uninstaller
# See ft-pm for more details

VAR_DB="/var/lib/packages"

PACKAGE="$1"
if [ -z "$PACKAGE" ]; then
    echo "Usage: $0 package"
    exit 1
fi

if [ ! -f "$VAR_DB/$PACKAGE.files" ]; then
    echo "Package $PACKAGE not found"
    exit 1
fi

while read -r file; do
    rm -v "$file" 2>/dev/null || true
done < "$VAR_DB/$PACKAGE.files"

rm -v "$VAR_DB/$PACKAGE.files" 2>/dev/null || true

echo "Package $PACKAGE removed"
