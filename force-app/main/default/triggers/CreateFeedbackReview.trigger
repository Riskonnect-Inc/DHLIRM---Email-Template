trigger CreateFeedbackReview on Patient_Satisfaction__c (before insert, before update) {
    CreateReviewRecord.makeFeedbackReview();
}