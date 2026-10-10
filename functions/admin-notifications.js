function adminEvent(category, before, after, targetId) {
  if (!after) return null;
  if (category === 'applications' && after.verificationStatus === 'pending' &&
      before?.verificationStatus !== 'pending') {
    return {category, targetId, title: 'Craftisan Admin', body: 'A new application is awaiting review.'};
  }
  if (category === 'orders' && (!before || before.status !== after.status || before.courierId !== after.courierId)) {
    return {category, targetId, title: 'Craftisan Admin', body: 'An order was created or updated.'};
  }
  if (category === 'reports' && !before) {
    return {category, targetId, title: 'Craftisan Admin', body: 'A new complaint needs review.'};
  }
  return null;
}

async function sendAdminAlerts(db, messaging, eventId, notice) {
  if (!notice) return;
  // Firestore events can be retried. Claim one dispatch per event.
  try {
    await db.collection('notificationDispatches').doc(eventId).create({
      category: notice.category, targetId: notice.targetId, createdAt: new Date(),
    });
  } catch (error) {
    if (error.code === 6 || error.code === 'already-exists') return;
    throw error;
  }
  const admins = (await db.collection('users').where('role', '==', 'admin').get()).docs;
  for (const admin of admins) {
    if (admin.data().active === false) continue;
    const preferences = (await db.doc(`adminPreferences/${admin.id}`).get()).data();
    if (preferences?.[notice.category] === false) continue;
    const devices = (await db.collection('adminDevices').where('adminId', '==', admin.id).get()).docs;
    for (let index = 0; index < devices.length; index += 500) {
      const chunk = devices.slice(index, index + 500);
      const response = await messaging.sendEachForMulticast({
        tokens: chunk.map(device => device.data().token),
        notification: {title: notice.title, body: notice.body},
        data: {type: 'admin', category: notice.category, targetId: notice.targetId},
        android: {priority: 'high', ttl: 3600000, notification: {tag: `admin-${notice.category}-${notice.targetId}`}},
      });
      await Promise.all(response.responses.map((result, offset) => {
        if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(result.error?.code)) {
          return chunk[offset].ref.delete();
        }
        if (result.error) console.error('Admin notification failed:', result.error.code);
        return Promise.resolve();
      }));
    }
  }
}

module.exports = {adminEvent, sendAdminAlerts};
