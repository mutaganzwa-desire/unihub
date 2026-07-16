# Testing guide

```bash
flutter test
```

## What's covered
- **Unit** — `validators_test.dart`, `string_ext_test.dart`,
  `recommendation_engine_test.dart` (pure logic: form rules, search tokens,
  recommendation ranking).
- **Repository** — `auth_repository_test.dart` and
  `application_repository_test.dart` run against `fake_cloud_firestore` and
  `firebase_auth_mocks`, verifying document creation, the one-application
  constraint, atomic counter increments, timeline appends and notification
  side effects.
- **Widget** — `widget_test.dart` covers shared UI (`EmptyState`,
  `StatusChip`).

## Adding tests
Because every repository takes its Firebase dependencies via the constructor
(injected through Riverpod in the app), a test just constructs it with fakes:

```dart
final db = FakeFirebaseFirestore();
final repo = ApplicationRepository(db, NotificationRepository(db));
```

For provider/state tests, wrap with a `ProviderContainer` and override
`firestoreProvider` / `firebaseAuthProvider` with fakes.
