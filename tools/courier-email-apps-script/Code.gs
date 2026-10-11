// Runs under the sender's Google account. No public web app endpoint is exposed.
var COURIER_SENDER = 'ksathsara378@gmail.com';
var COURIER_PROJECT = 'craftisan-we114-2026';

function installCourierEmailTrigger() {
  courierSenderCheck_();
  courierSettings_();
  // Request mail authorization without sending a message.
  MailApp.getRemainingDailyQuota();
  ScriptApp.getProjectTriggers().forEach(function(trigger) {
    if (trigger.getHandlerFunction() === 'sendCourierDecisionEmails') {
      ScriptApp.deleteTrigger(trigger);
    }
  });
  ScriptApp.newTrigger('sendCourierDecisionEmails').timeBased().everyMinutes(5).create();
}

function courierSenderCheck_() {
  if (Session.getEffectiveUser().getEmail().toLowerCase() !== COURIER_SENDER) {
    throw new Error('Run this script using the configured sender Google account.');
  }
}

function courierSettings_() {
  var values = PropertiesService.getScriptProperties().getProperties();
  ['FIREBASE_API_KEY','WORKER_EMAIL','WORKER_PASSWORD','WORKER_UID'].forEach(function(key) {
    if (!values[key]) throw new Error('Missing Script Property: ' + key);
  });
  return values;
}

function courierHttp_(url, body, token) {
  var options = {muteHttpExceptions: true, headers: {}};
  if (token) options.headers.Authorization = 'Bearer ' + token;
  if (body !== undefined) {
    options.method = 'post';
    options.contentType = 'application/json';
    options.payload = JSON.stringify(body);
  }
  var response = UrlFetchApp.fetch(url, options);
  var status = response.getResponseCode();
  if (status < 200 || status >= 300) {
    // Do not log tokens, passwords, recipient addresses or provider response bodies.
    throw new Error('Courier email service request failed (HTTP ' + status + ').');
  }
  return JSON.parse(response.getContentText());
}

function courierLogin_(settings) {
  var result = courierHttp_(
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=' + encodeURIComponent(settings.FIREBASE_API_KEY),
    {email: settings.WORKER_EMAIL, password: settings.WORKER_PASSWORD, returnSecureToken: true}
  );
  if (result.localId !== settings.WORKER_UID || !result.idToken) {
    throw new Error('Unexpected email worker account.');
  }
  return result.idToken;
}

function courierClaim_(document, token, uid) {
  var result = courierHttp_(courierBase_() + ':commit', {writes: [{
    update: {name: document.name, fields: {delivery: {mapValue: {fields: {
      state: {stringValue: 'PROCESSING'}, workerId: {stringValue: uid}
    }}}}},
    updateMask: {fieldPaths: ['delivery']}, currentDocument: {updateTime: document.updateTime},
    updateTransforms: [{fieldPath: 'delivery.attemptedAt', setToServerValue: 'REQUEST_TIME'}]
  }]}, token);
  var write = result.writeResults[0];
  return {updateTime: write.updateTime, attemptedAt: write.transformResults[0].timestampValue};
}

function courierComplete_(document, claim, token, uid, state) {
  var fields = {state: {stringValue: state}, workerId: {stringValue: uid},
    attemptedAt: {timestampValue: claim.attemptedAt}};
  if (state === 'FAILED') fields.error = {stringValue: 'Email send failed. Review the sender account and quota before retrying manually.'};
  courierHttp_(courierBase_() + ':commit', {writes: [{
    update: {name: document.name, fields: {delivery: {mapValue: {fields: fields}}}},
    updateMask: {fieldPaths: ['delivery']}, currentDocument: {updateTime: claim.updateTime},
    updateTransforms: [{fieldPath: 'delivery.completedAt', setToServerValue: 'REQUEST_TIME'}]
  }]}, token);
}

function courierBase_() {
  return 'https://firestore.googleapis.com/v1/projects/' + COURIER_PROJECT + '/databases/(default)/documents';
}

function courierProcess_(document, token, settings) {
  var delivery = document.fields.delivery;
  // Never automatically resend SENT/FAILED/PROCESSING records. A crash after
  // Gmail accepts mail but before status persistence requires manual review.
  if (delivery && delivery.mapValue.fields.state) return false;
  var recipient = document.fields.to.stringValue;
  var message = document.fields.message.mapValue.fields;
  if (!/^[^\s,@]+@[^\s,@]+\.[^\s,@]+$/.test(recipient) || !message.subject || !message.text) {
    throw new Error('Invalid queued email.');
  }
  var claim = courierClaim_(document, token, settings.WORKER_UID);
  try {
    MailApp.sendEmail({to: recipient, subject: message.subject.stringValue,
      body: message.text.stringValue, name: 'Craftisan Delivery', replyTo: COURIER_SENDER});
  } catch (_) {
    courierComplete_(document, claim, token, settings.WORKER_UID, 'FAILED');
    return false;
  }
  // A status-write error propagates; do not mark an accepted email as failed.
  courierComplete_(document, claim, token, settings.WORKER_UID, 'SENT');
  return true;
}

function sendCourierDecisionEmails() {
  courierSenderCheck_();
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(1000)) return;
  try {
    var settings = courierSettings_();
    var remaining = Math.min(MailApp.getRemainingDailyQuota(), 20);
    if (remaining <= 0) return;
    var token = courierLogin_(settings);
    var properties = PropertiesService.getScriptProperties();
    var cursor = properties.getProperty('QUEUE_CURSOR') || '';
    for (var page = 0; page < 5 && remaining > 0; page++) {
      var url = courierBase_() + '/courierApprovalEmails?pageSize=50';
      if (cursor) url += '&pageToken=' + encodeURIComponent(cursor);
      var result = courierHttp_(url, undefined, token);
      var documents = result.documents || [];
      for (var i = 0; i < documents.length && remaining > 0; i++) {
        if (courierProcess_(documents[i], token, settings)) remaining--;
      }
      if (remaining <= 0) {
        // Resume this page next time so its remaining records aren't skipped.
        properties.setProperty('QUEUE_CURSOR', cursor);
        return;
      }
      cursor = result.nextPageToken || '';
      properties.setProperty('QUEUE_CURSOR', cursor);
      if (!cursor) break;
    }
  } finally {
    lock.releaseLock();
  }
}
