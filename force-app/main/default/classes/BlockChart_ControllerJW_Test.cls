@IsTest
public class BlockChart_ControllerJW_Test {
	public static testmethod void test_Constructor() {
		BlockChart_ControllerJW controller = new BlockChart_ControllerJW((rkl.JS_Search)null);
		controller = new BlockChart_ControllerJW((ApexPages.StandardController)null);
	}

	public static testmethod void test_Constructor_WithId() {
		String name = 'test';
		String dataLevel = 'Policy';
		Double maximum = 100.0;
		String scaleConfig = '{"scale":"linear"}';
		String filterConfig = '{"coverage_line__c":["Building"],"program_year__c":"","name":""}';
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveNewPolicyMap(name, dataLevel, scaleConfig, maximum, filterConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Id policyMapId = (Id)response.get('id');

		PageReference currentPage = Page.PolicyMap_Wrapper;
		currentPage.getParameters().put('id', policyMapId);
		Test.setCurrentPage(currentPage);

		BlockChart_ControllerJW controller = new BlockChart_ControllerJW((rkl.JS_Search)null);

		System.assertEquals(null, controller.startDateMS);
		System.assertEquals(null, controller.endDateMS);
		System.assertEquals(null, controller.coveragesJSON);
		System.assertEquals(scaleConfig, controller.scaleConfigJSON);
		System.assertEquals(null, controller.yAxisIntervalJSON);
		System.assertEquals('100', controller.upperBoundValue);
	}

	public static testmethod void test_New_Constructor() {
		String name = 'test';
		String dataLevel = 'Policy';
		Double maximum = 100.0;
		String scaleConfig = '{"scale":"linear"}';
		String filterConfig = '{"coverage_line__c":["Building"],"program_year__c":"","name":""}';
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveNewPolicyMap(name, dataLevel, scaleConfig, maximum, filterConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Id policyMapId = (Id)response.get('id');

		Policy_Map__c policyMap = [SELECT Id, RecordTypeId FROM Policy_Map__c WHERE Id =: policyMapId];

		PolicyMap_New_Controller controller = new PolicyMap_New_Controller(new ApexPages.StandardController(policyMap));
	}

	public static testmethod void test_New_Redirect() {
		String name = 'test';
		String dataLevel = 'Policy';
		Double maximum = 100.0;
		String scaleConfig = '{"scale":"linear"}';
		String filterConfig = '{"coverage_line__c":["Building"],"program_year__c":"","name":""}';
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveNewPolicyMap(name, dataLevel, scaleConfig, maximum, filterConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Id policyMapId = (Id)response.get('id');

		Policy_Map__c policyMap = [SELECT Id, RecordTypeId FROM Policy_Map__c WHERE Id =: policyMapId];

		PolicyMap_New_Controller controller = new PolicyMap_New_Controller(new ApexPages.StandardController(policyMap));

		PageReference redirectRef = controller.attemptRedirect();
		System.assert(redirectRef != null, 'Redirect response should not be null.');
	}

	public static testmethod void test_SaveNewPolicyMap() {
		String name = 'test';
		String dataLevel = 'Policy';
		Double maximum = 100.0;
		String scaleConfig = '{"scale":"linear"}';
		String filterConfig = '{"coverage_line__c":["Building"],"program_year__c":"","name":""}';
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveNewPolicyMap(name, dataLevel, scaleConfig, maximum, filterConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Id policyMapId = (Id)response.get('id');

		Policy_Map__c policyMap = [SELECT Id, Name, Filter_Criteria__c, Data_Level__c, Vertical_Scale__c, Vertical_Maximum__c FROM Policy_Map__c WHERE Id =: policyMapId];
		System.assertEquals(name, policyMap.Name);
		System.assertEquals(dataLevel, policyMap.Data_Level__c);
		System.assertEquals(maximum, policyMap.Vertical_Maximum__c);
		System.assertEquals(scaleConfig, policyMap.Vertical_Scale__c);
		System.assertEquals(filterConfig, policyMap.Filter_Criteria__c);
	}

	public static testmethod void test_SavePolicyMap() {
		String name = 'test';
		String dataLevel = 'Policy';
		Double maximum = 100.0;
		String scaleConfig = '{"scale":"linear"}';
		String filterConfig = '{"coverage_line__c":["Building"],"program_year__c":"","name":""}';
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveNewPolicyMap(name, dataLevel, scaleConfig, maximum, filterConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Id policyMapId = (Id)response.get('id');

		filterConfig = '{}';
		name = 'test2';

		response = (Map<String, Object>)BlockChart_ControllerJW.savePolicyMap(policyMapId, filterConfig, name);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Policy_Map__c policyMap = [SELECT Id, Name, Filter_Criteria__c FROM Policy_Map__c WHERE Id =: policyMapId];
		System.assertEquals(name, policyMap.Name);
		System.assertEquals(filterConfig, policyMap.Filter_Criteria__c);
	}

	public static testmethod void test_SaveColors() {
		String policyDataJSON = '{"Name":"GL456","Broker_Amount__c":0.00,"Coverage_Line__c":"General Liability","Date_Policy_Effective__c":"2060-01-01","Date_Policy_Expiration__c":"2060-12-31","Notify_Excess_Carrier__c":false,"Occurrence_Attachment_Point__c":20000000,"Policy_Aggregate_Limit__c":55000000,"Policy_Basis__c":"Occurrence date","Policy_Occurrence_Limit__c":5000000,"Policy_Status__c":"Inactive","Primary__c":false,"Program_Year__c":"General Liability 2060 / 2060","Rating__c":"A","Broker_Paid__c":0.00,"Fees_Paid__c":0.00,"Gross_Premium_Paid__c":0.00,"Net_Premium_Paid__c":0.00,"Taxes_Paid__c":0.00,"Layer_Type__c":"Excess","Carrier_AM_Best_Rating__c":"A"}';
		Policy__c policy1 = (Policy__c)JSON.deserialize(policyDataJSON, Policy__c.class);
		Policy__c policy2 = (Policy__c)JSON.deserialize(policyDataJSON, Policy__c.class);

		insert policy1;
		insert policy2;

		String color1 = '#FFFFFF', color2 = '#000000';
		Map<String, String> saveColorsData = new Map<String, String> {
			policy1.Id => color1,
			policy2.Id => color2
		};
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveColors(JSON.serialize(saveColorsData));

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Map<Id, Policy__c> updatedPolicies = new Map<Id, Policy__c>([SELECT Id, Color__c FROM Policy__c WHERE Id IN: new String[]{ policy1.Id, policy2.Id }]);
		
		System.assertEquals(color1, updatedPolicies.get(policy1.Id).Color__c);
		System.assertEquals(color2, updatedPolicies.get(policy2.Id).Color__c);
	}

	public static testmethod void test_UpdateScale() {
		String name = 'test';
		String dataLevel = 'Policy';
		Double maximum = 100.0;
		String scaleConfig = '{"scale":"linear"}';
		String filterConfig = '{"coverage_line__c":["Building"],"program_year__c":"","name":""}';
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveNewPolicyMap(name, dataLevel, scaleConfig, maximum, filterConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Id policyMapId = (Id)response.get('id');

		scaleConfig = '{"scale":"logarithmic"}';
		response = (Map<String, Object>)BlockChart_ControllerJW.updateScale(policyMapId, scaleConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Policy_Map__c policyMap = [SELECT Id, Vertical_Scale__c FROM Policy_Map__c WHERE Id =: policyMapId];
		System.assertEquals(scaleConfig, policyMap.Vertical_Scale__c);
	}

	public static testmethod void test_UpdateUpperBounds() {
		String name = 'test';
		String dataLevel = 'Policy';
		Double maximum = 100.0;
		String scaleConfig = '{"scale":"linear"}';
		String filterConfig = '{"coverage_line__c":["Building"],"program_year__c":"","name":""}';
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveNewPolicyMap(name, dataLevel, scaleConfig, maximum, filterConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Id policyMapId = (Id)response.get('id');

		maximum = 150.0;
		response = (Map<String, Object>)BlockChart_ControllerJW.updateUpperBounds(policyMapId, maximum);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Policy_Map__c policyMap = [SELECT Id, Vertical_Maximum__c FROM Policy_Map__c WHERE Id =: policyMapId];
		System.assertEquals(maximum, policyMap.Vertical_Maximum__c);
	}

	public static testmethod void test_UpdateYAxisIntervals() {
		String name = 'test';
		String dataLevel = 'Policy';
		Double maximum = 100.0;
		String scaleConfig = '{"scale":"linear"}';
		String filterConfig = '{"coverage_line__c":["Building"],"program_year__c":"","name":""}';
		Map<String, Object> response = (Map<String, Object>)BlockChart_ControllerJW.saveNewPolicyMap(name, dataLevel, scaleConfig, maximum, filterConfig);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Id policyMapId = (Id)response.get('id');

		String yAxisIntervals = '[150, 180, 200, 210]';
		response = (Map<String, Object>)BlockChart_ControllerJW.updateYAxisIntervals(policyMapId, yAxisIntervals);

		System.assert((Boolean)response.get('success'), (String)response.get('message'));

		Policy_Map__c policyMap = [SELECT Id, Y_Axis_Ticks__c FROM Policy_Map__c WHERE Id =: policyMapId];
		System.assertEquals(yAxisIntervals, policyMap.Y_Axis_Ticks__c);
	}
}