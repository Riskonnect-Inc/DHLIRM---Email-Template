global class reviewEmailSchedulerPE implements Schedulable {
	global void execute(SchedulableContext sc) {
		reviewerEmailRemindersPE revRemPE = new reviewerEmailRemindersPE();
			revRemPE.dueReviewer(revRemPE.incompleteReview3Days);
			revRemPE.dueReviewer(revRemPE.incompleteReview7Days);
			revRemPE.dueReviewer(revRemPE.incompleteReview10Days);
			revRemPE.dueReviewer(revRemPE.incompleteReview12Days);
			revRemPE.sendEmails();
	}
}