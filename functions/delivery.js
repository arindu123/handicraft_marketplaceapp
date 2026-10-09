// Notification payloads deliberately omit addresses, phone numbers and parcel details.
function deliveryAudience(before, after) {
  if (!after) return null;
  if (after.status === 'confirmed' && !after.courierId &&
      (before?.status !== 'confirmed' || before?.courierId)) return 'available';
  if (after.status === 'courierAssigned' && after.courierId &&
      (before?.status !== 'courierAssigned' || before?.courierId !== after.courierId)) return after.courierId;
  return null;
}

async function sendDeliveryAlerts(db, messaging, orderId, audience) {
  // Recheck current ownership so delayed events cannot notify a former assignee.
  const current = (await db.doc(`orders/${orderId}`).get()).data();
  if (!current || (audience === 'available'
      ? current.status !== 'confirmed' || current.courierId
      : current.status !== 'courierAssigned' || current.courierId !== audience)) return;
  const users = audience === 'available'
    ? (await db.collection('users').where('role', '==', 'courier').get()).docs
    : [await db.doc(`users/${audience}`).get()];
  for (const user of users) {
    const profile = user.data();
    if (!profile || profile.role !== 'courier' || profile.active === false ||
        profile.deliveryNotifications === false ||
        (audience === 'available' && profile.deliveryOnline !== true)) continue;
    const devices = (await db.collection('deliveryDevices').where('courierId', '==', user.id).get()).docs;
    for (let offset = 0; offset < devices.length; offset += 500) {
      const chunk = devices.slice(offset, offset + 500);
      if (!chunk.length) continue;
      const response = await messaging.sendEachForMulticast({
        tokens: chunk.map(device => device.data().token),
        notification: { title: 'Craftisan Delivery', body: audience === 'available'
          ? 'A new delivery request is available.' : 'You have a new delivery assignment.' },
        data: { orderId, type: 'delivery' },
        android: { priority: 'high', ttl: 3600000,
          notification: { tag: `delivery-${orderId}` } },
      });
      await Promise.all(response.responses.map((result, index) => {
        if (['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']
            .includes(result.error?.code)) return chunk[index].ref.delete();
        if (result.error) console.error('Delivery notification failed:', result.error.code);
        return Promise.resolve();
      }));
    }
  }
}

module.exports = { deliveryAudience, sendDeliveryAlerts };
