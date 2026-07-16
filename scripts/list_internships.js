const admin = require('firebase-admin');
const projectId = process.env.FIREBASE_PROJECT || 'unihub-db7fa';
const initOptions = { projectId };
if (admin.credential && typeof admin.credential.applicationDefault === 'function') {
  initOptions.credential = admin.credential.applicationDefault();
}
admin.initializeApp(initOptions);
const { getFirestore } = require('firebase-admin/firestore');
const db = getFirestore();

async function list() {
  const snap = await db.collection('internships').limit(50).get();
  console.log(`Found ${snap.size} internships in project ${projectId}`);
  snap.forEach((doc) => {
    const d = doc.data();
    console.log(`- ${doc.id}: ${d.title} @ ${d.startupName} (${d.status})`);
  });
}

list().catch((e) => {
  console.error('List failed:', e);
  process.exit(1);
});
