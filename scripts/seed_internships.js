/*
Seed sample internships into Firestore.

Usage:
  1) Install deps: npm install firebase-admin
  2) Set credentials:
     - For production Firestore: set GOOGLE_APPLICATION_CREDENTIALS to a service account JSON
       or run `gcloud auth application-default login` and set FIREBASE_PROJECT.
     - For emulator: set FIRESTORE_EMULATOR_HOST=localhost:8080 and FIREBASE_PROJECT to your project id.
  3) Run: node scripts/seed_internships.js

Environment variables:
  - FIREBASE_PROJECT (optional, defaults to 'unihub-db7fa')
  - GOOGLE_APPLICATION_CREDENTIALS (optional if using ADC via gcloud)
*/

const admin = require('firebase-admin');

const projectId = process.env.FIREBASE_PROJECT || 'unihub-db7fa';
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;
const serviceAccount = process.env.GOOGLE_APPLICATION_CREDENTIALS;

console.log('Seeding internships with project:', projectId);
console.log('Using Firestore emulator:', Boolean(emulatorHost));
if (emulatorHost) console.log('FIRESTORE_EMULATOR_HOST=', emulatorHost);
if (serviceAccount) console.log('GOOGLE_APPLICATION_CREDENTIALS=', serviceAccount);

// Initialize admin with application default credentials (use GOOGLE_APPLICATION_CREDENTIALS or
// ADC via gcloud). This works with the emulator if FIRESTORE_EMULATOR_HOST is set.
// Initialize admin SDK. Prefer application default credentials when
// available, but fall back to a simple init using `projectId` so the
// script works with the Cloud Firestore emulator or older environments.
const initOptions = { projectId };
if (admin.credential && typeof admin.credential.applicationDefault === 'function') {
  initOptions.credential = admin.credential.applicationDefault();
}
admin.initializeApp(initOptions);

const { getFirestore } = require('firebase-admin/firestore');
const db = getFirestore();

async function seed() {
  const internships = [
    {
      startupId: 'startup_acme',
      startupName: 'Acme Labs',
      startupLogoUrl: null,
      title: 'Frontend Intern (Flutter)',
      description: 'Work on mobile features using Flutter. Great for students.',
      responsibilities: ['Build UI', 'Write tests', 'Ship features'],
      requirements: ['Flutter', 'Dart', 'Git'],
      skills: ['Flutter', 'Dart'],
      skillsLower: ['flutter', 'dart'],
      category: 'Software',
      workMode: 'Remote',
      employmentType: 'Internship',
      location: 'Remote',
      durationWeeks: 12,
      compensation: 'Paid',
      deadline: null,
      positions: 2,
      applicationInstructions: 'Email us your CV.',
      status: 'open',
      postedAt: new Date(),
      viewsCount: 0,
      applicantsCount: 0,
      searchTokens: ['frontend', 'flutter', 'mobile']
    },
    {
      startupId: 'startup_verdant',
      startupName: 'Verdant AI',
      startupLogoUrl: null,
      title: 'Data Science Intern',
      description: 'Help build ML models for environmental data.',
      responsibilities: ['Explore datasets', 'Train models'],
      requirements: ['Python', 'Pandas', 'ML basics'],
      skills: ['Python', 'Pandas'],
      skillsLower: ['python', 'pandas'],
      category: 'Data Science',
      workMode: 'Hybrid',
      employmentType: 'Internship',
      location: 'San Francisco, CA',
      durationWeeks: 10,
      compensation: 'Unpaid stipend',
      deadline: null,
      positions: 1,
      applicationInstructions: 'Apply via our portal.',
      status: 'open',
      postedAt: new Date(),
      viewsCount: 0,
      applicantsCount: 0,
      searchTokens: ['data', 'ml', 'python']
    },
    {
      startupId: 'startup_greenbyte',
      startupName: 'GreenByte',
      startupLogoUrl: null,
      title: 'Product Design Intern',
      description: 'Support product design and user research.',
      responsibilities: ['Design mocks', 'User testing'],
      requirements: ['Figma', 'UX basics'],
      skills: ['Design', 'Figma'],
      skillsLower: ['design', 'figma'],
      category: 'Design',
      workMode: 'On-site',
      employmentType: 'Internship',
      location: 'London, UK',
      durationWeeks: 8,
      compensation: 'Paid',
      deadline: null,
      positions: 1,
      applicationInstructions: 'Send portfolio link.',
      status: 'open',
      postedAt: new Date(),
      viewsCount: 0,
      applicantsCount: 0,
      searchTokens: ['design', 'ux', 'figma']
    }
  ];

  const batch = db.batch();
  internships.forEach((it) => {
    const ref = db.collection('internships').doc();
    batch.set(ref, it);
  });

  await batch.commit();
  console.log(`Seeded ${internships.length} internships to project ${projectId}`);
}

seed().catch((e) => {
  console.error('Seeding failed:', e);
  process.exit(1);
});
