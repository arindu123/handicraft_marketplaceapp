const messages = {
  confirmed: 'Your artisan has confirmed your order.',
  courierAssigned: 'A courier has been assigned to your order.',
  pickedUp: 'Your order has been picked up by the courier.',
  onTheWay: 'Your order is on the way to you.',
  delivered: 'Your order has been delivered.',
  cancelled: 'Your order has been cancelled.',
};

function buyerUpdate(before, after) {
  if (!before || !after || before.status === after.status ||
      !after.buyerId || !messages[after.status]) return null;
  return { buyerId: after.buyerId, status: after.status,
    title: 'Order update', body: messages[after.status] };
}

async function sendBuyerAlert(db, messaging, orderId, update, createdAt) {
  const user = (await db.doc(`users/${update.buyerId}`).get()).data();
  if (!user || user.role !== 'buyer' || user.active === false) return;
  // One inbox entry per milestone, including when a trigger is retried.
  const ref = db.doc(`users/${update.buyerId}/notifications/${orderId}_${update.status}`);
  try {
    await ref.create({ orderId, status: update.status, title: update.title,
      body: update.body, createdAt, read: false });
  } catch (error) {
    if (error.code !== 6 && error.code !== 'already-exists') throw error;
  }
  // Duplicate trigger deliveries share an Android notification tag.
  const devices = (await db.collection('buyerDevices')
    .where('buyerId', '==', update.buyerId).get()).docs;
  for (let offset = 0; offset < devices.length; offset += 500) {
    const chunk = devices.slice(offset, offset + 500);
    const response = await messaging.sendEachForMulticast({
      tokens: chunk.map(device => device.data().token),
      notification: { title: update.title, body: update.body },
      data: { orderId, status: update.status, type: 'buyerOrder' },
      android: { priority: 'high', ttl: 3600000,
        notification: { tag: `buyer-${orderId}-${update.status}` } },
    });
    await Promise.all(response.responses.map((result, index) => {
      if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']
          .includes(result.error?.code)) return chunk[index].ref.delete();
      if (result.error) throw new Error(`Buyer notification failed: ${result.error.code}`);
      return Promise.resolve();
    }));
  }
}

module.exports = { buyerUpdate, sendBuyerAlert };
