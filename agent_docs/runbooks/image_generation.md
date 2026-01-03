# Image generation (Gemini Nano Banana)

This runbook covers generating lofi-style images using Gemini's image models
via REST. It includes model names, request shapes, and how to decode the image
from the response.

## Models
- `gemini-2.5-flash-image` (Nano Banana): fast/cheap. As of 2026-01-03 it rejects
  `generationConfig.imageConfig` with `INVALID_ARGUMENT`; use prompt wording to
  enforce aspect ratio.
- `gemini-3-pro-image-preview` (Nano Banana Pro): supports `responseModalities`
  plus `imageConfig` (aspect ratio + image size).

## API key
The API key is stored in `.gemini_api_key` (gitignored). Export it to an env var:

```bash
export GEMINI_API_KEY="$(cat .gemini_api_key)"
```

## REST examples

### Nano Banana (Flash)
Use prompt-only aspect ratio guidance.

```bash
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [
        {"text": "Calm lofi illustration, 16:9 wide composition. Cozy cabin on a hillside, soft pastel sky, warm light, gentle mist. No text, no logos."}
      ]
    }]
  }'
```

### Nano Banana Pro (3 Pro Image Preview)
Explicit aspect ratio + size.

```bash
curl -s -X POST \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "role": "user",
      "parts": [
        {"text": "Calm colorful lofi scene, 16:9 wide composition. City skyline at dawn, soft gradient sky, hanging plants, tranquil mood. No text, no logos."}
      ]
    }],
    "generationConfig": {
      "responseModalities": ["TEXT", "IMAGE"],
      "imageConfig": {
        "aspectRatio": "16:9",
        "imageSize": "2K"
      }
    }
  }'
```

## Decode the image
The response includes base64 image data at `candidates[0].content.parts[*].inlineData`.
Use the MIME type to pick the file extension.

```bash
python - <<'PY'
import base64
import json
import sys

data = json.load(sys.stdin)
parts = data["candidates"][0]["content"]["parts"]
for part in parts:
    inline = part.get("inlineData") or part.get("inline_data")
    if not inline:
        continue
    mime = inline.get("mimeType", "image/png")
    ext = ".png" if "png" in mime else ".jpg"
    with open("out" + ext, "wb") as f:
        f.write(base64.b64decode(inline["data"]))
    print("Wrote", "out" + ext)
    break
PY
```
