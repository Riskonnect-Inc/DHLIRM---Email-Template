@IsTest
public class RKHierarchyTree_Controller_Test {
	public static testMethod void test_getCustomSetting() {
		Schema.SObjectType customSettingType = Schema.getGlobalDescribe().get('rkl__Hierarchy_Settings__c');
		SObject customSettingsInstance = customSettingType.newSObject();
		customSettingsInstance.put('rkl__Hierarchy_Object__c', 'rkl__RK_Hierarchy_Node__c');
		customSettingsInstance.put('rkl__NodeCode__c', 'rkl__Node_Code__c');
		customSettingsInstance.put('rkl__NodeKey__c', 'rkl__Node_Key__c');
		customSettingsInstance.put('rkl__NodeName__c', 'rkl__Node_Name__c');
		customSettingsInstance.put('rkl__ParentNode__c', 'rkl__Parent_Node__c');
		customSettingsInstance.put('rkl__ParentNodeKey__c', 'rkl__Parent_Node_Key__c');
		customSettingsInstance.put('rkl__Is_Leaf__c', 'rkl__Is_Leaf__c');
		insert customSettingsInstance;

		String customSettingJSON = RKHierarchyTree_Controller.getCustomSetting();
	}

	public static testMethod void test_getRootRecords() {
		Schema.SObjectType customSettingType = Schema.getGlobalDescribe().get('rkl__Hierarchy_Settings__c');
		SObject customSettingsInstance = customSettingType.newSObject();
		customSettingsInstance.put('rkl__Hierarchy_Object__c', 'rkl__RK_Hierarchy_Node__c');
		customSettingsInstance.put('rkl__NodeCode__c', 'rkl__Node_Code__c');
		customSettingsInstance.put('rkl__NodeKey__c', 'rkl__Node_Key__c');
		customSettingsInstance.put('rkl__NodeName__c', 'rkl__Node_Name__c');
		customSettingsInstance.put('rkl__ParentNode__c', 'rkl__Parent_Node__c');
		customSettingsInstance.put('rkl__ParentNodeKey__c', 'rkl__Parent_Node_Key__c');
		customSettingsInstance.put('rkl__Is_Leaf__c', 'rkl__Is_Leaf__c');
		insert customSettingsInstance;

		String customSettingJSON = RKHierarchyTree_Controller.getCustomSetting();
		SObject[] rootRecords = RKHierarchyTree_Controller.getRootRecords(customSettingJSON);
	}

	public static testMethod void test_getPathToRootIds() {
		Schema.SObjectType customSettingType = Schema.getGlobalDescribe().get('rkl__Hierarchy_Settings__c');
		SObject customSettingsInstance = customSettingType.newSObject();
		customSettingsInstance.put('rkl__Hierarchy_Object__c', 'rkl__RK_Hierarchy_Node__c');
		customSettingsInstance.put('rkl__NodeCode__c', 'rkl__Node_Code__c');
		customSettingsInstance.put('rkl__NodeKey__c', 'rkl__Node_Key__c');
		customSettingsInstance.put('rkl__NodeName__c', 'rkl__Node_Name__c');
		customSettingsInstance.put('rkl__ParentNode__c', 'rkl__Parent_Node__c');
		customSettingsInstance.put('rkl__ParentNodeKey__c', 'rkl__Parent_Node_Key__c');
		customSettingsInstance.put('rkl__Is_Leaf__c', 'rkl__Is_Leaf__c');
		insert customSettingsInstance;

		Schema.SObjectType hierarchyType = Schema.getGlobalDescribe().get('rkl__RK_Hierarchy_Node__c');

		SObject rootHierarchy = hierarchyType.newSObject();
		rootHierarchy.put('rkl__Node_Code__c', '0001');
		insert rootHierarchy;

		SObject level1Hierarchy = hierarchyType.newSObject();
		level1Hierarchy.put('rkl__Node_Code__c', '0002');
		level1Hierarchy.put('rkl__Parent_Node_Key__c', '0001');
		level1Hierarchy.put('rkl__Parent_Node__c', rootHierarchy.Id);
		insert level1Hierarchy;

		Test.startTest();

		String customSettingJSON = RKHierarchyTree_Controller.getCustomSetting();
		Id[] pathToRootIds = RKHierarchyTree_Controller.getPathToRootIds(level1Hierarchy.Id, customSettingJSON);

		Test.stopTest();
	}

	public static testMethod void test_getChildren() {
		Schema.SObjectType customSettingType = Schema.getGlobalDescribe().get('rkl__Hierarchy_Settings__c');
		SObject customSettingsInstance = customSettingType.newSObject();
		customSettingsInstance.put('rkl__Hierarchy_Object__c', 'rkl__RK_Hierarchy_Node__c');
		customSettingsInstance.put('rkl__NodeCode__c', 'rkl__Node_Code__c');
		customSettingsInstance.put('rkl__NodeKey__c', 'rkl__Node_Key__c');
		customSettingsInstance.put('rkl__NodeName__c', 'rkl__Node_Name__c');
		customSettingsInstance.put('rkl__ParentNode__c', 'rkl__Parent_Node__c');
		customSettingsInstance.put('rkl__ParentNodeKey__c', 'rkl__Parent_Node_Key__c');
		customSettingsInstance.put('rkl__Is_Leaf__c', 'rkl__Is_Leaf__c');
		insert customSettingsInstance;

		Schema.SObjectType hierarchyType = Schema.getGlobalDescribe().get('rkl__RK_Hierarchy_Node__c');

		SObject rootHierarchy = hierarchyType.newSObject();
		rootHierarchy.put('rkl__Node_Code__c', '0001');
		insert rootHierarchy;

		SObject level1Hierarchy = hierarchyType.newSObject();
		level1Hierarchy.put('rkl__Node_Code__c', '0002');
		level1Hierarchy.put('rkl__Parent_Node_Key__c', '0001');
		level1Hierarchy.put('rkl__Parent_Node__c', rootHierarchy.Id);
		insert level1Hierarchy;

		Test.startTest();

		String customSettingJSON = RKHierarchyTree_Controller.getCustomSetting();

		SObject[] rootChildren = RKHierarchyTree_Controller.getChildren(rootHierarchy.Id, customSettingJSON);

		Test.stopTest();
	}

	public static testMethod void test_startRebuild() {
		RKHierarchyTree_Controller.startRebuild();
	}

	public static testMethod void test_getBatchProgress() {
		Id jobId = RKHierarchyTree_Controller.startRebuild();
		SObject jobDetails = RKHierarchyTree_Controller.getBatchProgress(jobId);
	}
}