---
id: skumring-yese
status: closed
deps: []
links: []
created: 2026-01-04T07:13:07.983195+01:00
type: bug
priority: 2
---
# Fix YouTube player alignment - center video with 16:9 aspect ratio

The YouTube video player is misaligned - the video content starts about 1/3 from the left edge and spans to the right edge, leaving black space on the left. The video should be centered and maintain a 16:9 aspect ratio regardless of the container size. This is likely caused by the CSS injection that hides YouTube UI elements not properly handling the video container sizing.


