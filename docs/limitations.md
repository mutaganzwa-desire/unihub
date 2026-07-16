# Known limitations & roadmap

## Known limitations
- **Search** uses Firestore prefix tokens (`searchTokens`), which supports
  starts-with matching, not full-text or typo tolerance. For richer search,
  integrate Algolia/Typesense via a Cloud Function.
- **Recommendations** are content-based and computed over the currently loaded
  feed page. A server-side job could score the full catalogue and persist
  per-user recommendations.
- **Push delivery** requires the Cloud Function in firebase_setup.md; without
  it, notifications still appear in-app (and as local notifications while the
  app is foregrounded) but not as background pushes.
- **Admin UI** is intentionally not shipped in the consumer app. The full
  `AdminRepository` capability set is implemented for use by an internal
  console or callable functions.
- **Interview scheduling** sets a status and notifies; it does not yet capture
  date/time or calendar invites.
- **Read receipts** patch the most recent messages on open; extremely long
  threads read only the latest window.

## Roadmap
- Full-text search + saved searches and alerts.
- Server-side recommendation pipeline with feedback signals.
- In-app interview scheduling with calendar integration.
- Group conversations and message reactions.
- Startup team accounts (multiple recruiters per startup).
- Web/desktop responsive targets.
- Localisation (the codebase already separates copy from logic).
