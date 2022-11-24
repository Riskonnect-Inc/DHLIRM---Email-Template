// BK : PST-00018434
// Added this trigger to intercept changes to shadow attachment objects for feed items and feed comments
//
trigger ContentVersionTrigger on ContentVersion (after update) {
  TriggerGrandCentral.updateAttachmentShadows();
}