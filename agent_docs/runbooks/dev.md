# Dev Environment Runbook

Status: current
Last verified: 2026-01-04

## Setup
- Install Xcode (17+ with macOS 26 SDK).
- Open `Skumring/Skumring.xcodeproj` once to let Xcode index the project.

## Build and run (Xcode)
1) Open `Skumring/Skumring.xcodeproj`.
2) Select scheme `Skumring`.
3) Product > Run.

## Build and run (CLI)
```bash
cd Skumring
xcodebuild -scheme Skumring -destination 'platform=macOS' \
  -derivedDataPath ../build/DerivedData build
open "$(pwd)/../build/DerivedData/Build/Products/Debug/Skumring.app"
```

## Build and install (local)
This produces a standard `.app` that you can keep in Applications.

```bash
cd Skumring
xcodebuild -scheme Skumring -configuration Release -destination 'platform=macOS' \
  -derivedDataPath ../build/DerivedData build

APP_PATH="$(pwd)/../build/DerivedData/Build/Products/Release/Skumring.app"

# Option A (recommended): per-user install
mkdir -p ~/Applications
ditto "$APP_PATH" "$HOME/Applications/Skumring.app"

# Option B: system-wide install (may prompt for admin password)
sudo ditto "$APP_PATH" "/Applications/Skumring.app"
```

Launch with Spotlight or:
```bash
open "$HOME/Applications/Skumring.app"
```

## Scripted helper (optional)
If you just want a quick local run during dev, `scripts/run_app.sh` is still available.

## Hot reload (Inject)
Hot reload is wired via the `Inject` Swift package and Debug linker flags.

1) Install InjectionIII from https://github.com/johnno1962/InjectionIII/releases and move it to `/Applications`.
2) Open InjectionIII, select `Skumring/Skumring.xcodeproj`.
3) Run the app in Debug from Xcode.
4) Save a Swift file — the view should reload without full restart.

Notes:
- If you add new types or change initializer signatures, you may need a full rebuild.
- State can reset on injection; re-open the view if needed.

## Common issues
- App icon does not update: delete the old app from Applications and re-copy.
