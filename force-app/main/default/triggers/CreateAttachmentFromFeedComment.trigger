trigger CreateAttachmentFromFeedComment on FeedComment (after insert) { // after insert, after update) {
    //TriggerGrandCentral.CreateAttachmentShadows(Trigger.newmap.keySet(), Trigger.isInsert, Trigger.isUpdate, 'FeedComment');
    TriggerGrandCentral.CreateShadowsForFeedComment2();
}