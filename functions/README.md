Deployable Cloud Function for UniHub

This folder contains a callable Cloud Function `createUserRecord` used to
create the `users` document and the associated `students`/`startups` profile
record server-side. This avoids client-side races with Firestore security
rules during user registration.

Deploy:

1. Install Firebase CLI and log in:

```bash
npm install -g firebase-tools
firebase login
```

2. From this `functions` folder install deps and deploy:

```bash
cd functions
npm install
firebase deploy --only functions:createUserRecord
```

Client usage (Flutter / Dart using `cloud_functions`):

```dart
import 'package:cloud_functions/cloud_functions.dart';

final functions = FirebaseFunctions.instance;
final callable = functions.httpsCallable('createUserRecord');
await callable.call(<String, dynamic>{
  'role': 'student',
  'displayName': 'Alice Example',
});
```

Call this immediately after `createUserWithEmailAndPassword` and after the
user is signed in. The callable function runs with admin privileges so it can
create the Firestore documents reliably.
