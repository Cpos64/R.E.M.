// scripts/backfillRecallRating.js

const admin = require('firebase-admin');

const serviceAccount = require('./sleepdreamsocialapp-firebase-adminsdk-fbsvc-5ccda48a60.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function backfillRecallRating() {
  const dreamsRef = db.collection('dreams');
  const snapshot  = await dreamsRef.get();
  console.log(`🔍 Fetched ${snapshot.size} dream documents.`);

  let updated = 0;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    // only update if recallRating is missing or null
    if (data.recallRating === undefined || data.recallRating === null) {
      await doc.ref.update({ recallRating: 5 });
      console.log(`✅ ${doc.id} → recallRating: 5`);
      updated++;
    }
  }

  console.log(`\n🎉 Backfilled recallRating on ${updated} documents.`);
  process.exit(0);
}

backfillRecallRating().catch(err => {
  console.error("❌ Error during backfill:", err);
  process.exit(1);
});
