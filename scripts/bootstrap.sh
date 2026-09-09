#!/bin/sh

set -eu

SCRIPT_DIRECTORY="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PROJECT_DIRECTORY="$(dirname "$SCRIPT_DIRECTORY")"

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required. Install it from https://brew.sh and run this script again."
    exit 1
fi

brew list xcodegen >/dev/null 2>&1 || brew install xcodegen
brew list swiftgen >/dev/null 2>&1 || brew install swiftgen
brew list swiftlint >/dev/null 2>&1 || brew install swiftlint

if command -v bundle >/dev/null 2>&1; then
    (cd "$PROJECT_DIRECTORY" && bundle install)
else
    echo "warning: Bundler is not installed. Skipping Ruby dependencies."
fi

if [ ! -f "$SCRIPT_DIRECTORY/.env" ]; then
    cp "$SCRIPT_DIRECTORY/.env.example" "$SCRIPT_DIRECTORY/.env"
    echo "Created scripts/.env; set TEAM_ID before generating the project."
    exit 1
fi

set -a
. "$SCRIPT_DIRECTORY/.env"
set +a

"$SCRIPT_DIRECTORY/generate"

echo "All set up. Opening ${PROJECT_NAME}.xcodeproj in Xcode."
open "$PROJECT_DIRECTORY/${PROJECT_NAME}.xcodeproj"
