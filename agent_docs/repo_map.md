# Repo Map — Skumring

## Project Overview

Skumring is a macOS focus-music player that mixes internet radio streams, audio URLs, and YouTube embeds.

**Primary stack:** Swift, SwiftUI, macOS Tahoe 26

## Key Directories

```
Skumring/
├── Skumring.xcodeproj/     # Xcode project
└── Skumring/               # Main app source
    ├── Models/             # Core data models (Codable, Hashable)
    │   ├── LibraryItemKind.swift     # stream, youtube, audioURL
    │   ├── LibraryItemSource.swift   # URL or YouTube ID
    │   ├── HealthStatus.swift        # unknown, ok, failing
    │   ├── LibraryItem.swift         # Main item struct
    │   ├── RepeatMode.swift          # off, one, all
    │   ├── ShuffleMode.swift         # off, on
    │   ├── Playlist.swift            # Playlist struct
    │   └── Pack.swift                # Import/export container
    ├── SkumringApp.swift     # App entry point
    ├── ContentView.swift     # Main view (currently YouTube PoC)
    ├── YouTubePlayer.swift   # YouTube player state model
    ├── YouTubePlayerView.swift  # WKWebView YouTube embed
    └── Assets.xcassets/      # App icons, colors

agent_docs/                   # Agent documentation
├── README.md                 # Index (start here)
├── repo_map.md               # This file
├── gotchas.md                # Known pitfalls
├── runbooks/                 # How-to guides
│   ├── dev.md                # Development setup
│   ├── test.md               # Testing procedures
│   └── release.md            # Release process
├── decisions/                # ADR-like decision records
└── workflows/                # Agent coordination workflows

.beads/                       # Beads task tracker
scripts/                      # Build/dev scripts
assets/                       # Generated assets, images
```

## Build & Run

```bash
cd Skumring
xcodebuild -scheme Skumring -destination 'platform=macOS' build
```

Or open `Skumring.xcodeproj` in Xcode and run.

## Current Milestone

**Milestone 0 (YouTube PoC)** — Validates YouTube IFrame API in WKWebView.

Next: Milestone 1 (Playable) — LibraryStore, AVPlayer backend, Stream resolver.

## Key Models

| Model | Purpose |
|-------|---------|
| `LibraryItem` | Single music item (stream, YouTube, audio URL) |
| `Playlist` | Ordered collection of item IDs with repeat/shuffle |
| `Pack` | Import/export container with schema version |
| `HealthStatus` | Item playback health tracking |
