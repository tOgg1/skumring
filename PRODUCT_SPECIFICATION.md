# Product Specification — “Skumring”

**One‑line:** A beautiful macOS focus-music player that mixes curated **internet radio streams**, **open audio URLs**, and **YouTube embeds**, with playlists, looping, and shareable JSON “packs”.

**Doc version:** v1.1
**Date:** 2026‑01‑03
**Primary platform:** macOS
**UI direction:** “Liquid Glass” overlay navigation + controls (not glass everywhere) ([Apple Developer][1])

---

## 1) Problem statement

People want background focus music (lofi / jazz / ambient) that:

* is high quality,
* doesn’t require constantly browsing YouTube,
* doesn’t depend on Spotify playlists,
* can be curated and shared, and
* feels like a first-class macOS app.

---

## 2) Goals and success criteria

### Goals (v1)

1. **Zero-friction playback**

   * One-click to play any item.
   * Persistent “Now Playing” bar.
2. **Mixed-source library**

   * Support: **streams**, **open audio URLs**, and **YouTube embeds**.
3. **Playlists + queue**

   * Create/edit playlists, reorder, loop one/all, shuffle.
4. **Shareable packs**

   * Export/import library or playlist(s) as versioned JSON (no binaries).
5. **Beautiful UI**

   * Liquid Glass-inspired overlays for navigation + controls, with readable content.

### Success criteria

* Playback starts within **< 2 seconds** for typical sources (assuming network OK).
* App recovers gracefully from common failures (stream down, network loss).
* Import/export round-trips without data loss (except transient fields like “lastPlayed”).
* YouTube playback remains compliant: embedded player is visible and not misused for background audio. ([Google for Developers][2])

---

## 3) Non-goals (v1)

* Downloading/caching full audio tracks for offline playback.
* “Extract audio from YouTube” or hiding the player to simulate audio-only (don’t do this).
* Social accounts, sync, or cloud hosting of content.
* A full Spotify replacement.

---

## 4) Target users and use cases

### Personas

* **Knowledge worker**: wants lofi/jazz in background all day, quickly switches “moods”.
* **Student**: builds playlists for study sessions, exports to friends.
* **Creative**: wants “soundtrack packs” (e.g., rainy jazz + synth ambient) to share.

### Top use cases

* “Start Deep Work” playlist, loop all for 3–4 hours.
* Quickly switch between 3–6 favorite stations.
* Import a friend’s curated pack in seconds.
* Use media keys/shortcuts without leaving coding/writing app.

---

## 5) Product principles

1. **Press Play. Stay in flow.**
2. **Respect platform + content policies** (especially YouTube embeds). ([YouTube][3])
3. **Library is yours** (local-first; exportable).
4. **Glass as an overlay** (toolbars/controls/now playing), not “glass everywhere”. ([Apple Developer][1])

---

## 6) Platform and compatibility

### OS targets

* **Primary target:** macOS version that supports Liquid Glass APIs (often referenced as **macOS Tahoe 26** alongside iOS 26). ([Apple Developer][1])
* **Fallback mode (optional):** if you decide to support older macOS, use standard SwiftUI materials (blur) without Liquid Glass-specific modifiers.

### Distribution

* **v1:** Local testing only (Xcode run / archive)
* **Post-v1:** Direct distribution via GitHub Releases + Sparkle auto-updates (requires code signing + notarization)

---

## 7) Information architecture

### Sidebar sections (NavigationSplitView)

* **Home**

  * “Focus Now” shortcuts (top playlists + recently played)
* **Built-in Pack**

  * Curated stations + curated YouTube embeds (see Section 7a)
* **Library**

  * All Items
  * Streams
  * YouTube
  * Audio URLs
* **Playlists**

  * User playlists
* **Imports**

  * Imported packs (optional grouping)

### Main content

* Grid or list of items
* Search + tag filters

### Detail panel

* Playlist editor
* Item details (title, tags, artwork, source URL/ID)
* Playback controls (if not using a global Now Playing bar)

### Persistent Now Playing bar (bottom)

* play/pause, next/prev
* title/author/source
* repeat/shuffle toggles
* volume
* "queue" popover

---

## 7a) Built-in Pack

### Purpose

The Built-in Pack provides a curated set of focus music sources out-of-the-box, so users can start listening immediately without adding their own content.

### Source

* **Remote URL:** `https://skumring.app/packs/builtin-v1.json` (or similar CDN URL)
* **Fallback:** Bundled `builtin-pack.json` in app resources (used if network unavailable on first launch)
* **Refresh:** App checks for updates to the remote pack on launch (max once per 24 hours); updates are merged silently

### Behavior

* Built-in Pack items appear in a dedicated sidebar section
* Users **cannot delete** built-in items (but can hide the entire Built-in Pack section in preferences)
* Users **can add** built-in items to their own playlists (creates a reference, not a copy)
* Built-in items are visually distinguished (e.g., subtle "curated" badge)

### Schema

Same as the import/export JSON schema (Section 14), with an additional top-level field:

```json
{
  "schemaVersion": 1,
  "packType": "builtin",
  "packVersion": "2026.01.03",
  ...
}
```

---

## 8) Core objects and data model

### Library item types (v1)

1. **Stream** (infinite/live sources)

   * URL can be direct stream or playlist file (`.m3u`, `.pls`)
   * Examples: internet radio, 24/7 lofi streams
   * Auto-detected by: `.m3u`/`.pls` extension, or `Content-Type: audio/x-mpegurl`, or lack of `Content-Length` header
2. **YouTube**

   * video ID (and optionally playlist ID later)
3. **Audio URL** (finite files)

   * direct audio file (mp3/aac/m4a) or HLS audio URL
   * Auto-detected by: audio file extension, or `Content-Type: audio/*` with `Content-Length` header

### Canonical model (Swift)

* `LibraryItem` (id, type, title, subtitle, tags, artwork, source)
* `Playlist` (id, name, ordered item references, shuffle/repeat)
* `Pack` (optional wrapper for imports/exports)

---

## 9) Functional requirements (with priorities)

### P0 — Playback (must ship)

**P0.1 Play audio streams & audio URLs**

* Uses `AVPlayer` for:

  * direct audio URLs (mp3/aac/m4a/hls)
  * resolved stream URLs (see Stream Resolver below)

**Acceptance criteria**

* Can play a known good stream URL for 30 minutes without crashing.
* If stream fails to load, show error state and allow retry.

---

**P0.2 Play YouTube via embed**

* Uses **WKWebView** with embedded player (IFrame API or iframe).
* Respect minimum viewport size and embed parameters. ([Google for Developers][4])

**Acceptance criteria**

* YouTube item plays with a visible embedded player surface.
* No attempt to extract audio-only or run “hidden” playback.
* If YouTube playback fails (blocked/restricted), show a clear error and provide “Open on YouTube” action.

**Policy constraint you must design around**

* YouTube API policies prohibit promoting features that play content from a **background player that is not displayed**. ([Google for Developers][2])
* YouTube site terms also restrict downloading/circumventing and limit use to personal, non-commercial, and permitted embed usage. ([YouTube][3])

---

**P0.3 Queue**

* When user clicks an item:

  * If in playlist context: play within that playlist order
  * Else: play that single item and set a temporary queue (optional v1)

**Acceptance criteria**

* Next/Previous works for playlist playback.
* Repeat mode affects behavior at ends.

---

### P0 — Library & Playlists (must ship)

**P0.4 Add items**

* Add Stream:

  * paste URL
  * optional title + tags
* Add YouTube:

  * paste YouTube URL or ID
* Add Audio URL:

  * paste direct URL
* Optional: validate URL scheme (https recommended)

**Acceptance criteria**

* Item appears immediately in Library
* Item is editable/deletable

---

**P0.5 Playlists**

* Create / rename / delete playlist
* Add items to playlist
* Drag reorder
* Shuffle on/off
* Repeat: off / one / all

**Acceptance criteria**

* Reordering persists after app restart
* Repeat One loops the current item
* Repeat All loops playlist from start

---

### P0 — Import/Export (must ship)

**P0.6 Export JSON**

* Export:

  * whole library + playlists, or
  * selected playlist(s)
* Export contains **metadata + URLs/IDs only** (no audio files)

**P0.7 Import JSON**

* Import merges into library
* Detect duplicates:

  * by stable `id` if same origin pack
  * by normalized source key (URL or youtubeID)

**Acceptance criteria**

* Importing an export yields the same playlists and items (IDs may change depending on dedupe settings).
* Schema version validated; incompatible versions show a message.

---

### P1 — Mac niceties (strongly recommended)

**P1.1 Media keys + menu**

* Play/Pause via keyboard media key if possible
* Menu bar commands + keyboard shortcuts:

  * Space: Play/Pause
  * Cmd+N: New Playlist
  * Cmd+L: Add Link/Item
  * Cmd+F: Search
  * Cmd+E: Export
  * Cmd+I: Import

---

### P2 — Nice-to-haves (post-v1)

* **Menu bar mini-player** (status bar item with title + controls)
* Smart playlists by tags ("LoFi", "Jazz", "No Beats")
* Stream "health check" (periodic ping)
* Remote pack URLs (subscribe to curated packs)
* Focus timer / Pomodoro integration
* **Auto-updates via Sparkle** (GitHub Releases appcast)

---

## 10) Liquid Glass UI requirements

### Design intent

Use Liquid Glass for:

* Now Playing bar
* Floating playback controls
* Sidebar/toolbar accents
* Search field container

Avoid:

* glass on every list row (visual noise, readability issues)
* stacking too many glass layers

### Implementation notes

* When multiple glass elements exist in a region, wrap them in `GlassEffectContainer` for better performance and morphing behavior. ([Apple Developer][5])
* Apple’s Liquid Glass docs note `glassEffect(_:in:)` captures content for the container and should be applied after other relevant modifiers. ([Apple Developer][5])
* Glass configuration supports concepts like `tint` and `interactive`. ([Apple Developer][6])
* WWDC session guidance emphasizes Liquid Glass for navigational elements, controls, and overlay structures. ([Apple Developer][1])

### Accessibility requirements

* Respect Reduce Transparency / Increase Contrast when possible
* Ensure text contrast is high enough on glass backgrounds
* Provide “Simple Mode” toggle (fallback to material blur) if needed

---

## 11) YouTube embed requirements (hard constraints)

### Player requirements

* Embedded players must be at least **200×200**; recommended at least **480×270** for 16:9. ([Google for Developers][4])
* For IFrame API control (`enablejsapi=1`), specify `origin` as a security measure. ([Google for Developers][4])
* Looping a single YouTube video in embeds requires:

  * `loop=1` and `playlist=VIDEO_ID` ([Google for Developers][4])

### Policy requirements (design implications)

* YouTube API policies prohibit promoting features that play content from a **background player that is not displayed**. ([Google for Developers][2])
* **Skumring approach:** The YouTube player is always rendered (visible in the Now Playing area when a YouTube item is active). However, playback is **not** paused when the user navigates away or minimizes — we simply ensure the player surface exists and is accessible. This is compliant: we don't hide the player or extract audio-only.

### Product UX rule for YouTube items

* "Audio-first" presentation is allowed — the player can be compact (>= 200×200).
* The artwork/ambient image can decorate around it, but must not fully obscure the player controls.

---

## 12) Streaming requirements

### Stream resolver

Support playlist indirections:

* `.m3u` → pick first valid http(s) URL line
* `.pls` → parse `File1=...`

**Acceptance criteria**

* Given a valid `.m3u` or `.pls`, app resolves to a playable URL automatically.

### Reconnect behavior

* If stream drops:

  * attempt reconnect up to N times (e.g., 3) with exponential backoff
  * then show an error + retry button

### Item and playlist health status

Each library item tracks a `healthStatus`:

* **`unknown`** — never tested (default for new items)
* **`ok`** — last playback or probe succeeded
* **`failing`** — last N attempts failed (N=3)

Health is updated:

* On successful playback start → `ok`
* On playback failure → increment fail counter; after 3 consecutive failures → `failing`
* Manual "Retry" resets fail counter and re-probes

**Playlist health** is derived:

* **Healthy:** all items `ok` or `unknown`
* **Degraded:** 1+ items `failing`, but at least one `ok`
* **Broken:** all items `failing`

**UI indicators:**

* Items: small badge (warning icon for `failing`)
* Playlists: subtle indicator in sidebar (e.g., orange dot for degraded, red for broken)
* Playlist detail view: list of failing items with "Retry All" action

---

## 13) Persistence and storage

### Local-first storage

Store everything in:

* `Application Support/<bundle id>/library.json`
  or
* SwiftData + export/import mapping

### Data to persist

* Items, playlists
* UI state: last selected playlist, last played item, last volume, repeat/shuffle
* Recent items (optional)

### Data NOT to store

* Audio binaries
* YouTube content files
* User credentials (v1 has no accounts)

### Artwork cache

* **Location:** `Application Support/<bundle id>/artwork/`
* **Format:** Downloaded images converted to JPEG (quality 0.8) for consistency
* **Size limit:** 100 MB total cache size
* **Eviction:** LRU (least recently used) when limit exceeded
* **Stale handling:** If artwork URL returns 404/error, keep cached version; mark as "stale" but don't delete
* **Filename:** SHA256 hash of the original URL + `.jpg`

---

## 14) Import/Export JSON format (v1)

### File format

* UTF‑8 JSON
* Top-level object includes `schemaVersion`

### Schema (v1)

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-01-02T10:10:00Z",
  "appIdentifier": "com.example.Skumring",
  "items": [
    {
      "id": "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
      "kind": "stream",
      "title": "LoFi Beats Radio",
      "subtitle": "Curated",
      "tags": ["lofi", "focus"],
      "source": {
        "url": "https://example.com/stream.m3u"
      },
      "artworkURL": "https://example.com/art.jpg",
      "addedAt": "2026-01-02T10:00:00Z"
    },
    {
      "id": "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF",
      "kind": "youtube",
      "title": "Rainy Jazz Café",
      "subtitle": "YouTube",
      "tags": ["jazz", "rain"],
      "source": {
        "youtubeID": "M7lc1UVf-VE"
      },
      "artworkURL": "https://example.com/thumb.jpg",
      "addedAt": "2026-01-02T10:05:00Z"
    }
  ],
  "playlists": [
    {
      "id": "11111111-2222-3333-4444-555555555555",
      "name": "Deep Work",
      "itemIDs": [
        "A2B3C4D5-E6F7-4123-8901-23456789ABCD",
        "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF"
      ],
      "repeatMode": "all",
      "shuffleMode": "off"
    }
  ]
}
```

### Import validation rules

* `schemaVersion` must be recognized
* Item kinds must be known (`stream`, `youtube`, `audioURL`)
* URLs must be http(s) (reject `file://` to avoid abuse)
* If item has neither url nor youtubeID → reject item

### Dedupe rules

Compute `sourceKey`:

* stream/audioURL: normalized URL (lowercase scheme+host, trimmed, remove tracking params optionally)
* YouTube: `youtubeID`

Merge behavior (automatic, no user prompt):

* If same `sourceKey` exists in library:
  * **Update** title, subtitle, tags, artworkURL from the imported item (imported values win)
  * Preserve the existing item's `id` and `addedAt`
  * Do not create a duplicate

---

## 15) UI screens and interaction specs

### First launch

* Show “Built‑in Focus Pack”
* Big “Play” CTA on a default playlist/station
* Tiny onboarding note: “Paste a stream/YouTube link to add your own”

### Library list/grid

* Each card shows:

  * artwork (optional)
  * title + subtitle
  * tags
  * “…” actions: Add to playlist, Edit, Export selection, Delete

### Playlist editor

* Drag reorder
* Toggle shuffle/repeat
* Bulk add/remove

### Now Playing

* For AVPlayer sources:

  * show artwork, title, source name
* For YouTube:

  * show compact embedded player area (>= 200×200)
  * show metadata alongside

---

## 16) Security, privacy, and compliance

### Privacy (v1)

* No accounts
* No tracking by default
* Optional crash logs only

### Network safety

* Only load http(s)
* Timeouts for metadata fetches
* Don’t execute arbitrary scripts except your known embedded YouTube player HTML

### Compliance summary (YouTube)

* Embed player only
* Don’t offer “background YouTube audio”
* Don’t download or circumvent restrictions ([YouTube][3])

---

## 17) Technical architecture

### Core components

1. `LibraryStore`

   * CRUD items/playlists
   * persistence
2. `PlaybackController`

   * unified API for play/pause/next/prev
   * internally routes to:

     * `AVPlaybackBackend`
     * `YouTubePlaybackBackend`
3. `StreamResolver`

   * resolves `.m3u` / `.pls`
4. `ImportExportService`

   * JSON encode/decode
   * schema migration hooks
5. `ArtworkCache`

   * lightweight disk cache for images

### State management

* SwiftUI with `ObservableObject` / `@StateObject`
* One global `AppModel` holding:

  * library store
  * playback controller
  * UI selection state

---

## 18) Testing plan

### Unit tests

* JSON import/export round-trip
* Stream resolver parsing (m3u/pls)
* Dedupe logic

### Integration tests

* AVPlayer can start playback of a sample stream URL (mock network if needed)
* YouTube WebView loads and responds to JS calls (smoke)

### UI tests

* Create playlist → add item → reorder → export → import into clean library

---

## 19) Risks and mitigations

1. **YouTube in WKWebView may have issues** (HIGHEST PRIORITY)

   * Risk: IFrame API JS bridge may be unreliable, or Apple may block certain behaviors
   * Mitigation: Milestone 0 PoC validates this before full build; if blocked, consider AVKit-based alternatives or dropping YouTube support
2. **Streams go offline**

   * Mitigation: show health status, retry, allow user to edit URL
3. **YouTube restrictions / playback failures**

   * Mitigation: clear error UI, "Open on YouTube", don't depend on YouTube for core value
4. **Overdoing Liquid Glass**

   * Mitigation: strict rule: glass only for overlays + containers
5. **Built-in Pack URL becomes unavailable**

   * Mitigation: bundled fallback always works; app gracefully handles fetch failures

---

## 20) MVP build plan (what to implement first)

### Milestone 0 (YouTube PoC) — BLOCKER

**Goal:** Validate that YouTube IFrame API works reliably in WKWebView on macOS Tahoe 26.

**Deliverables:**

1. Minimal Xcode project with a single WKWebView
2. Load YouTube IFrame API embed for a known video ID
3. Verify: play, pause, seek, and `onStateChange` events work via JS bridge
4. Verify: looping works with `loop=1&playlist=VIDEO_ID`
5. Document any quirks or blockers

**Exit criteria:** YouTube embed plays and responds to JS commands reliably, OR we document a workaround/alternative.

---

### Milestone 1 (Playable)

* LibraryStore + persistence
* AVPlayer backend (streams + audio URLs)
* Stream resolver (`.m3u` / `.pls`)
* Add item flow (paste URL → auto-detect type)
* Basic UI: sidebar, list, now playing bar
* Item health tracking (ok/failing states)

### Milestone 2 (Playlists + JSON)

* Playlist CRUD + drag reorder
* Repeat modes (off/one/all) + shuffle
* Export/import JSON with auto-merge dedupe
* Playlist health indicators

### Milestone 3 (YouTube)

* WKWebView embed backend (based on Milestone 0 PoC)
* YouTube items in library + playlists
* Compact player UI (>= 200x200, always visible when playing)
* Error handling + "Open on YouTube" fallback

### Milestone 4 (Built-in Pack + Polish)

* Remote Built-in Pack fetch + fallback bundle
* Artwork cache (100MB LRU)
* Liquid Glass on Now Playing bar + overlays
* Media key support (`MPRemoteCommandCenter`)
* Keyboard shortcuts

