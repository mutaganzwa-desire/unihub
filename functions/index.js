const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Callable function to create the user document and an empty profile document
 * for `students` or `startups` collections. The client should call this after
 * the user finishes authentication (createUserWithEmailAndPassword).
 *
 * Expects: { role: 'student' | 'startup', displayName: string }
 * Requires: authenticated context (callable invoked by the newly-signed-in user)
 */
exports.createUserRecord = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const uid = context.auth.uid;
  const email = context.auth.token.email || null;
  const role = data.role;
  const displayName = data.displayName || '';

  if (!['student', 'startup'].includes(role)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid role');
  }

  const userRef = db.collection('users').doc(uid);
  const profileCol = role === 'student' ? 'students' : 'startups';
  const profileRef = db.collection(profileCol).doc(uid);

  // Prevent accidental overwrite if the client already created records
  const userSnap = await userRef.get();
  if (userSnap.exists) {
    return { ok: true, message: 'User record already exists' };
  }

  const batch = db.batch();
  batch.set(userRef, {
    uid,
    email,
    role,
    displayName,
    status: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const profileData = {
    uid,
    email,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (role === 'student') profileData.fullName = displayName;
  if (role === 'startup') {
    profileData.name = displayName;
    profileData.verificationStatus = 'unverified';
  }

  batch.set(profileRef, profileData);
  await batch.commit();
  return { ok: true };
});
