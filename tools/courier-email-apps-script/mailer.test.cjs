const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(require('node:path').join(__dirname, 'Code.gs'), 'utf8');
function setup({sendFailure=false, finalWriteFailure=false, claimFailure=false, quota=100, sender='ksathsara378@gmail.com'}={}) {
  const state = {sent: [], commits: [], requests: [], lockReleased: false};
  const settings = {FIREBASE_API_KEY:'public-key',WORKER_UID:'worker',WORKER_EMAIL:'worker@example.invalid',WORKER_PASSWORD:'sample-secret'};
  const context = vm.createContext({
    Session:{getEffectiveUser:()=>({getEmail:()=>sender})},
    PropertiesService:{getScriptProperties:()=>({getProperties:()=>settings,getProperty:()=>'',setProperty:()=>{}})},
    MailApp:{getRemainingDailyQuota:()=>quota,sendEmail:(mail)=>{if(sendFailure) throw Error('Sensitive provider error'); state.sent.push(mail);}},
    LockService:{getScriptLock:()=>({tryLock:()=>true,releaseLock:()=>{state.lockReleased=true;}})},
    UrlFetchApp:{fetch:(url,options)=>{
      state.requests.push(url);
      const body=options.payload?JSON.parse(options.payload):null;
      if(url.includes('signInWithPassword')) return response(200,{localId:'worker',idToken:'id-token'});
      if(url.endsWith(':commit')) {
        state.commits.push(body);
        if(state.commits.length===1 && claimFailure) return response(412,{});
        if(state.commits.length===2 && finalWriteFailure) return response(503,{});
        return response(200,{writeResults:[{updateTime:'2026-10-11T10:00:00Z',transformResults:[{timestampValue:'2026-10-11T10:00:00Z'}]}]});
      }
      return response(200,{documents:[]});
    }},
  });
  vm.runInContext(source,context);
  return {context,state,settings};
}
function response(code,body){return {getResponseCode:()=>code,getContentText:()=>JSON.stringify(body)};}
function document(state) {
  const fields={to:{stringValue:'courier@example.com'},message:{mapValue:{fields:{subject:{stringValue:'Approved'},text:{stringValue:'You can log in.'}}}}};
  if(state) fields.delivery={mapValue:{fields:{state:{stringValue:state}}}};
  return {name:'projects/craftisan-we114-2026/databases/(default)/documents/courierApprovalEmails/one',updateTime:'old-version',fields};
}
test('claims once and sends only the queued recipient, then marks SENT',()=>{
  const {context,state,settings}=setup();
  assert.equal(context.courierProcess_(document(),'token',settings),true);
  assert.equal(state.sent[0].to,'courier@example.com');
  assert.equal(state.sent[0].replyTo,'ksathsara378@gmail.com');
  assert.equal(state.commits[0].writes[0].currentDocument.updateTime,'old-version');
  assert.equal(state.commits[1].writes[0].update.fields.delivery.mapValue.fields.state.stringValue,'SENT');
});
test('all previously claimed jobs are skipped without another send',()=>{
  for(const status of ['PROCESSING','SENT','FAILED']){
    const {context,state,settings}=setup();
    assert.equal(context.courierProcess_(document(status),'token',settings),false);
    assert.equal(state.sent.length,0);
    assert.equal(state.commits.length,0);
  }
});
test('a claim conflict prevents sending and a send error records FAILED',()=>{
  const failedClaim=setup({claimFailure:true});
  assert.throws(()=>failedClaim.context.courierProcess_(document(),'token',failedClaim.settings));
  assert.equal(failedClaim.state.sent.length,0);
  const failedSend=setup({sendFailure:true});
  assert.equal(failedSend.context.courierProcess_(document(),'token',failedSend.settings),false);
  assert.equal(failedSend.state.commits[1].writes[0].update.fields.delivery.mapValue.fields.state.stringValue,'FAILED');
});
test('status persistence failure never triggers a second send or a false FAILED result',()=>{
  const {context,state,settings}=setup({finalWriteFailure:true});
  assert.throws(()=>context.courierProcess_(document(),'token',settings));
  assert.equal(state.sent.length,1);
  assert.equal(state.commits.length,2);
});
test('wrong sender and exhausted daily quota do not send or authenticate',()=>{
  const wrong=setup({sender:'other@gmail.com'});
  assert.throws(()=>wrong.context.sendCourierDecisionEmails());
  assert.equal(wrong.state.requests.length,0);
  const exhausted=setup({quota:0});
  exhausted.context.sendCourierDecisionEmails();
  assert.equal(exhausted.state.requests.length,0);
  assert.equal(exhausted.state.lockReleased,true);
});
