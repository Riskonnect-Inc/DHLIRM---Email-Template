@isTest
private class PropertiesWorldMapController_Test {

	@isTest static void test_method_one() {
		PageReference pg = new PageReference('rka__PropertyMapViewer');
        Test.setCurrentPage(pg);
        pg.getParameters().put('incID', '');
        PropertiesWorldMap_Controller propMap = new PropertiesWorldMap_Controller(new ApexPages.StandardController(new Property__c()));
        PageReference re = propMap.onLoad();
	}
}