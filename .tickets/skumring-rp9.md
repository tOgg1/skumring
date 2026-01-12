---
id: skumring-rp9
status: closed
deps: [skumring-25r]
links: []
created: 2026-01-02T17:39:24.059064+01:00
type: task
priority: 1
parent: skumring-zhs
---
# Implement stream reconnection with exponential backoff

Add automatic reconnection logic for dropped streams:

1. ReconnectionManager class or integration into AVPlaybackBackend:
   - maxRetries: Int = 3
   - baseDelay: TimeInterval = 1.0
   - maxDelay: TimeInterval = 30.0
   - currentRetryCount: Int

2. Reconnection trigger conditions:
   - AVPlayerItem status becomes .failed
   - Network connectivity lost and restored
   - Stream stalls for extended period

3. Exponential backoff algorithm:
   - delay = min(baseDelay * (2 ^ retryCount), maxDelay)
   - Add jitter (random 0-25% variation)
   - Wait, then attempt reconnection
   - Reset retry count on successful playback

4. User feedback:
   - Show 'Reconnecting...' status in Now Playing
   - Show retry count (e.g., 'Reconnecting (2/3)...')
   - After max retries, show error with 'Retry' button

5. Network awareness:
   - Use NWPathMonitor to detect network changes
   - Pause retry timer when offline
   - Resume attempts when online

6. State preservation:
   - Remember current item/queue during reconnection
   - Resume from same position if possible (for finite content)
   - For streams, just restart from live

Acceptance criteria:
- Stream reconnects after brief network interruption
- Exponential backoff is visible in logs
- After 3 failures, shows error with manual retry
- Network recovery triggers reconnection attempt
- User can cancel reconnection and stop playback


