#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROJECT_PATH="$REPO_ROOT/Skumring/Skumring.xcodeproj"
SCHEME="Skumring"
CONFIGURATION="Debug"
STATE_ROOT=${TMPDIR:-/tmp}
DERIVED_DATA="$STATE_ROOT/skumring-derived-data-$(printf "%s" "$REPO_ROOT" | shasum -a 256 | awk '{print $1}')"
OPEN_APP=true
BUILD_APP=false

usage() {
  cat <<'USAGE'
Usage: scripts/run_app.sh [options]

Options:
  --build               Build before running (default: use existing build)
  --configuration NAME   Build configuration (Debug or Release)
  --derived-data PATH    DerivedData output directory
  --no-open              Do not open the .app
  -h, --help             Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)
      BUILD_APP=true
      shift
      ;;
    --configuration)
      CONFIGURATION=$2
      shift 2
      ;;
    --derived-data)
      DERIVED_DATA=$2
      shift 2
      ;;
    --no-open)
      OPEN_APP=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Xcode project not found: $PROJECT_PATH" >&2
  exit 1
fi

APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION/Skumring.app"
if [[ "$BUILD_APP" == "true" ]]; then
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA" \
    build
fi

if [[ ! -d "$APP_PATH" ]]; then
  if [[ "$BUILD_APP" == "true" ]]; then
    echo "App not found at $APP_PATH" >&2
  else
    echo "App not found at $APP_PATH. Run with --build to compile." >&2
  fi
  exit 1
fi

if [[ "$BUILD_APP" == "true" ]]; then
  echo "Built: $APP_PATH"
else
  echo "Using existing build: $APP_PATH"
fi

if [[ "$OPEN_APP" == "true" ]]; then
  if command -v open >/dev/null 2>&1; then
    open "$APP_PATH"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$APP_PATH"
  else
    echo "No opener found. Launch the app manually." >&2
  fi
fi
