@isTest
private class AddEntity_Controller_Test
{
	@isTest
	static void addEntityTest()
	{
		AddEntity_Controller testController = new AddEntity_Controller();
		testController.pageLoad();
		AddEntity_Controller.retrieveTemplate(new Map<String,Object>{'templateName' => 'property'});
		AddEntity_Controller.retrieveTemplate(new Map<String,Object>{'templateName' => 'hierarchy'});


		rkl__Renewal_Hierarchy__c testOrgStruct = new rkl__Renewal_Hierarchy__c(
			name = 'test',
			rkl__Object_API_Name__c = 'rkl__RK_Hierarchy_Node__c',
			rkl__Assignment_Lookup_API_Name__c = 'rkl__Hierarchy__c',
			rkl__Object_Label_API_Name__c = 'rkl__Node_Name__c',
			rkl__Assignment_Contact_API_Name__c = 'rkl__Assigned_Contact__c'
		);
		insert testOrgStruct;
		rkl__Renewal_Control__c testControl = new rkl__Renewal_Control__c(
			rkl__Portal_Group__c = 'test',
			rkl__Renewal_Hierarchy__c = testOrgStruct.Id
			);
		insert testControl;
		rkl__RK_Hierarchy_Node__c testHier = new rkl__RK_Hierarchy_Node__c();
		insert testHier;
		try{
			AddEntity_Controller.kickOffAddEntity(testControl.Id, testOrgStruct.Id, testHier.Id);
		} catch (Exception e){

		}
		try{
			AddEntity_Controller.pollAddEntityProcess(testControl.Id, testOrgStruct.Id, testHier.Id);
		} catch (Exception e){
			
		}
	}
}