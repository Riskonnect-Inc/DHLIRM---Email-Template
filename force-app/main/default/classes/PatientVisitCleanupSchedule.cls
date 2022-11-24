global class PatientVisitCleanupSchedule implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new PatientVisitCleanupBatch());
	}
}