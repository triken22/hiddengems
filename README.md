# HiddenGems

HiddenGems is a SwiftUI + MVVM iOS application backed by a Cloudflare Worker API for collaborative spot discovery. The project ships with a Core Data model, background AI job queue, local vector store, and a full-featured sync engine.

## Getting Started

### Prerequisites

- Xcode 15 or later
- iOS 17 simulator or device
- Node.js 20+
- Wrangler CLI (`npm install -g wrangler`)

### iOS App

1. Duplicate the environment file and add your credentials:

   ```bash
   cp .env.example .env
   ```

2. Update the `Config.Debug.xcconfig` and `Config.Release.xcconfig` files with API endpoints, bearer token, and logging preferences.

3. Open `HiddenGems.xcodeproj` in Xcode and select the `HiddenGems` scheme.

4. Build and run with **⌘R**.

The app uses `AppEnvironment` for dependency injection and automatically kicks off an initial sync when the home map appears.

### Cloudflare Worker

```bash
cd cloudflare-worker
npm install
cp ../.env.example .env
wrangler d1 create hidden_gems
# Update wrangler.toml with the returned database_id
wrangler d1 execute hidden_gems --file=schema.sql
wrangler deploy
```

Once deployed, configure the `API_BASE_URL` and `APP_SYNC_TOKEN` values in the xcconfig files to point to your Worker.

## Project Structure

- `App/` – Application entry point and environment wiring
- `Features/` – SwiftUI feature modules (Home map, Groups, Settings, Onboarding)
- `Model/` – Domain models used across the app and worker
- `Persistence/` – Core Data stack and entity mappings
- `Services/` – AI, Vector, Sync, Media, and Location services
- `Utilities/` – Common helpers and UI utilities
- `cloudflare-worker/` – Cloudflare Worker source with Hono router and D1 schema

## Testing

Unit and UI test targets are scaffolded under `HiddenGemsTests` and `HiddenGemsUITests`. Add test cases for services, repositories, and feature view models as you expand the app.
