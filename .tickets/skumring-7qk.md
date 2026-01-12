---
id: skumring-7qk
status: closed
deps: [skumring-fza]
links: []
created: 2026-01-02T17:41:30.873139+01:00
type: task
priority: 0
parent: skumring-b2h
---
# Implement repeat and shuffle modes

Add repeat and shuffle functionality to playback:

1. Repeat modes (RepeatMode enum):
   - .off: Stop after last item
   - .one: Loop current item indefinitely
   - .all: Loop entire playlist/queue after last item

2. Shuffle modes (ShuffleMode enum):
   - .off: Play in playlist order
   - .on: Play in random order

3. UI controls:
   - Repeat button in Now Playing bar:
     - Off: outline icon
     - One: filled icon with '1' badge
     - All: filled icon
     - Cycles through modes on click
   - Shuffle button in Now Playing bar:
     - Off: outline icon
     - On: filled/highlighted icon
     - Toggles on click
   - Same controls in playlist header

4. Playback behavior - Repeat:
   - .off: next() at end returns false, playback stops
   - .one: next() replays current item (or seeks to start)
   - .all: next() at end wraps to first item

5. Playback behavior - Shuffle:
   - When enabled, create shuffled copy of queue
   - Previous/Next navigate shuffled order
   - Reshuffle when turning shuffle on
   - Remember original order for when shuffle turned off
   - Option: don't repeat items until all played (Fisher-Yates)

6. Persistence:
   - Remember last repeat/shuffle mode per playlist
   - Remember global default if no playlist context

7. Keyboard shortcuts:
   - Cmd+R: Toggle repeat (cycle modes)
   - Cmd+S: Toggle shuffle (or Cmd+Shift+S to avoid conflict)

Acceptance criteria:
- Repeat One loops single item correctly
- Repeat All loops playlist correctly
- Shuffle randomizes playback order
- Previous works correctly in shuffle mode
- Settings persist per playlist


