const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// This scheduled function runs every 24 hours.
exports.autoCompleteOrders = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  const db = admin.firestore();
  const now = new Date();
  const threeDaysAgo = new Date();
  threeDaysAgo.setDate(now.getDate() - 3);

  // Query for orders that are 'Delivered' and were delivered more than 3 days ago.
  const querySnapshot = await db.collection('orders')
                                .where('status', '==', 'Delivered')
                                .get();

  if (querySnapshot.empty) {
    console.log("No delivered orders to process.");
    return null;
  }

  const batch = db.batch();
  let processedCount = 0;

  querySnapshot.forEach(doc => {
    const order = doc.data();
    // Ensure deliveredAt field exists and is a timestamp
    if (order.deliveredAt && order.deliveredAt.toDate) {
      const deliveredDate = order.deliveredAt.toDate();
      if (deliveredDate < threeDaysAgo) {
        console.log(`Order ${doc.id} will be marked as Shipped.`);
        batch.update(doc.ref, { 'status': 'Shipped', 'updatedAt': admin.firestore.FieldValue.serverTimestamp() });
        processedCount++;
      }
    }
  });

  if (processedCount > 0) {
    await batch.commit();
    console.log(`Successfully processed and marked ${processedCount} orders as Shipped.`);
  } else {
    console.log("No orders met the 3-day criteria.");
  }

  return null;
});
