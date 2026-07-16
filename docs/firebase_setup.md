# Firebase setup guide

## 1. Create the project
1. Go to the Firebase console and create a project (e.g. `unihub`).
2. Add an **Android** app (package `com.example.unihub` or your own) and an
   **iOS** app if you target iOS.

## 2. Generate the config
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This writes a real `lib/firebase_options.dart` (replacing the placeholder that
throws on launch) and platform files (`google-services.json`,
`GoogleService-Info.plist`).

## 3. Enable services
In the console enable:
- **Authentication → Email/Password**.
- **Cloud Firestore** (production mode).
- **Storage**.
- **Cloud Messaging**.
- **Analytics** and **Crashlytics**.

## 4. Deploy rules and indexes
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```
Files: `firestore.rules`, `firestore.indexes.json`, `storage.rules`.

## 5. Admin role
Admin capabilities are gated by an `admin` custom claim. Set it from a trusted
environment (Cloud Function or Admin SDK):
```js
await admin.auth().setCustomUserClaims(uid, { admin: true });
```

## 6. Push notifications delivery (Cloud Function)
In-app notifications are written to the `notifications` collection as a side
effect of allowed writes. To deliver them as FCM pushes, add a function that
fans out on document creation:

```js
exports.sendPush = functions.firestore
  .document('notifications/{id}')
  .onCreate(async (snap) => {
    const n = snap.data();
    const user = await admin.firestore().doc(`users/${n.userId}`).get();
    const token = user.get('fcmToken');
    if (!token) return;
    await admin.messaging().send({
      token,
      notification: { title: n.title, body: n.body },
      data: { route: n.route || '' },
    });
  });
```

## 7. Verification decisions
`AdminRepositoryImpl.decideVerification` flips a startup's
`verificationStatus`. Run it from the admin console or a callable function
authenticated with the admin claim; the client app cannot self-verify
(enforced by rules).
