const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { deliveryAudience, sendDeliveryAlerts } = require('./delivery');

initializeApp();
exports.notifyDeliveryRequests = onDocumentWritten('orders/{orderId}', async event => {
  const audience = deliveryAudience(event.data?.before.data(), event.data?.after.data());
  if (audience) await sendDeliveryAlerts(getFirestore(), getMessaging(), event.params.orderId, audience);
});
