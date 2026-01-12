---
id: skumring-8dz
status: closed
deps: []
links: []
created: 2026-01-02T17:35:22.766861+01:00
type: task
priority: 0
parent: skumring-y8g
---
# Create Xcode project with SwiftUI App lifecycle

Initialize a new macOS Xcode project for Skumring:
- Bundle ID: com.skumring.Skumring (or similar)
- Deployment target: macOS 26 (Tahoe) for Liquid Glass APIs
- SwiftUI App lifecycle (@main App struct)
- Enable App Sandbox for security
- Configure Info.plist with:
  - App name and version
  - Required permissions (network access)
  - App Transport Security settings for HTTPS
- Set up basic folder structure:
  - App/
  - Models/
  - Views/
  - ViewModels/
  - Services/
  - Resources/
  - Extensions/

Acceptance criteria:
- Project builds and runs on macOS 26
- Empty window appears with app title
- Bundle identifier is set correctly


