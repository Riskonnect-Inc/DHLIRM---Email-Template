global class PatientVisitCleanupBatch implements Database.Batchable<SObject> {
	global PatientVisitCleanupBatch() {}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		//Grab the current custom settings instance
		HC_Custom_Settings__c healthCareSettings = HC_Custom_Settings__c.getInstance();
		
		//Verify that the max age in days has been configured prior to attempting to delete any Patient_Visit__c records.
		if (bc != null && (healthCareSettings == null || healthCareSettings.Patient_Visit_Max_Age_Days__c == null)) {
			System.abortJob(bc.getJobId());
			return null;
		}

		//Retrieve the configured max Patient_Visit__c age (shift back one day to handle the inclusive equality behavior of the < operator with LAST_N_DAYS)
		Integer maxAgeDays = Integer.valueOf(healthCareSettings.Patient_Visit_Max_Age_Days__c) + 1;

		//Query for all Patient_Visit__c records that are older than the configured max age
		return Database.getQueryLocator('SELECT Id FROM Patient_Visit__c WHERE CreatedDate < LAST_N_DAYS:' + maxAgeDays);
	}

	global void execute(Database.BatchableContext bc, SObject[] scope) {
		//Delete any queried Patient_Visit__c records
		delete scope;
	}

	global void finish(Database.BatchableContext bc) {

	}
}