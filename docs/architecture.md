# Architecture

UniHub uses **Clean Architecture** with a **feature-first** layout. Each
feature owns three layers with a strict dependency direction:

```
presentation  ->  domain  <-  data
   (UI, Riverpod)   (entities,    (Firestore impls,
                      contracts)     mappers)
```

- **domain** has no Flutter or Firebase imports. It holds entities
  (`Internship`, `Application`, `AppUser`, ...) and repository interfaces.
- **data** implements the domain contracts against Firebase and maps
  documents to entities. All infrastructure exceptions are converted to
  domain `Failure`s via `mapError`, so the UI never sees a `FirebaseException`.
- **presentation** exposes Riverpod providers and widgets. Business logic
  lives in controllers/providers, never in widgets.

## Key patterns

- **Repository pattern** — one interface per aggregate; the implementation is
  swappable and mocked in tests.
- **Dependency injection** — Firebase singletons are provided through
  `firebase_providers.dart`; every repository receives its dependencies via
  Riverpod, so tests override them with `FakeFirebaseFirestore` /
  `MockFirebaseAuth`.
- **Result type** — `Result<T>` (`Success` / `ResultError`) forces callers to
  handle both branches; `guard()` wraps async bodies.
- **Single source of auth truth** — `authStateProvider` streams the current
  `AppUser` (with role loaded from Firestore). The router redirects on it, so
  role-based access control lives in exactly one place.

## State management

- `StreamProvider` for realtime Firestore data (internships, applications,
  chat, notifications, bookmarks) → automatic live updates and rebuild
  minimisation via Riverpod's selectors.
- `AsyncNotifierProvider.family` (`InternshipFeed`) for paginated, filterable
  feeds with infinite scroll and pull-to-refresh.
- `AsyncNotifier` (`AuthController`) for imperative flows with
  loading/error/success surfaced as `AsyncValue`.
- Derived providers (`recommendedInternshipsProvider`,
  `startupAnalyticsProvider`, `myApplicationStatsProvider`) compute from
  already-streamed data — no extra reads.

## Navigation

`GoRouter` with two `StatefulShellRoute.indexedStack` shells (student and
startup), each with four tabs, plus shared detail routes. The redirect guard:
routes unauthenticated users to onboarding/login, parks unverified emails on
`/verify-email`, and keeps each role inside its own area.

## Offline & errors

Firestore persistence is enabled in `bootstrap()`. `OfflineBanner` reflects
connectivity; writes queue locally and sync on reconnect. `AsyncView`
centralises loading (skeletons), empty and error (retry) states.
