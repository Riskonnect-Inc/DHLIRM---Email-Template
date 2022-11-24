public with sharing class PolicyMap_New_Controller {
	private Boolean shouldRedirect {get; set;}
	private Id recordTypeId {get; set;}

	public PolicyMap_New_Controller(ApexPages.StandardController controller) {
		shouldRedirect = false;

		RecordType[] policyMapRecordTypes = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Policy_Map__c'];
		Map<String, RecordType> policyMapRecordTypesByNameAndId = new Map<String, RecordType>();
		for (RecordType recordType : policyMapRecordTypes) {
			policyMapRecordTypesByNameAndId.put(recordType.DeveloperName, recordType);
			policyMapRecordTypesByNameAndId.put(String.valueOf(recordType.Id).substring(0, 15), recordType);
		}

		Policy_Map__c newPolicyMap = (Policy_Map__c)controller.getRecord();
		if (newPolicyMap.RecordTypeId != null) {
			//Force a redirect to the non-standard page only if the record type is Policy_Map
			shouldRedirect = policyMapRecordTypesByNameAndId.get(String.valueOf(newPolicyMap.RecordTypeId).substring(0, 15)).DeveloperName.equals('Policy_Map');
			recordTypeId = newPolicyMap.RecordTypeId;
		} else {
			shouldRedirect = true;
		}
	}

	public PageReference attemptRedirect() {
		PageReference redirect;
		if (shouldRedirect) {
			redirect = new PageReference('/apex/PolicyMap_Wrapper');
		} else {
			Schema.DescribeSObjectResult policyMapDescribe = Schema.getGlobalDescribe().get('Policy_Map__c').getDescribe();
			redirect = new PageReference('/' + policyMapDescribe.getKeyPrefix() + '/e?RecordType=' + recordTypeId + '&nooverride=1');
		}
		return redirect;
	}
}