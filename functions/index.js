const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { deliveryAudience, sendDeliveryAlerts } = require('./delivery');
const { adminEvent, sendAdminAlerts } = require('./admin-notifications');
const { buyerUpdate, sendBuyerAlert } = require('./buyer');

initializeApp();
exports.notifyDeliveryRequests = onDocumentWritten('orders/{orderId}', async event => {
  const audience = deliveryAudience(event.data?.before.data(), event.data?.after.data());
  if (audience) await sendDeliveryAlerts(getFirestore(), getMessaging(), event.params.orderId, audience);
});

const adminTrigger = (category, document) => onDocumentWritten(document, async event => {
  const notice = adminEvent(category, event.data?.before.data(), event.data?.after.data(),
    event.data?.after.ref.path ?? event.data?.before.ref.path);
  await sendAdminAlerts(getFirestore(), getMessaging(), event.id, notice);
});
exports.notifyAdminApplications = adminTrigger('applications', 'artisanProfiles/{profileId}');
exports.notifyAdminOrders = adminTrigger('orders', 'orders/{orderId}');
exports.notifyAdminComplaints = adminTrigger('reports', 'marketplaceReports/{reportId}');
exports.notifyAdminDeliveryIssues = adminTrigger('reports', 'orders/{orderId}/deliveryIssues/{reportId}');
exports.notifyBuyerOrderUpdates = onDocumentWritten({ document: 'orders/{orderId}', retry: true }, async event => {
  const update = buyerUpdate(event.data?.before.data(), event.data?.after.data());
  if (update) await sendBuyerAlert(getFirestore(), getMessaging(), event.params.orderId,
    update, event.data.after.updateTime);
});
