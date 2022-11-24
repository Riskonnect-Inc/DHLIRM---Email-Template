/*
=================================================================================================
|       AUTHOR      |       DATE        |                      DESCRIPTION                      |
=================================================================================================
|   Jason Bradley   |   May 1, 2018     | Added dynamic configuration + Migrate to Lightning    |
-------------------------------------------------------------------------------------------------
|                   |                   |                                                       |
*/
@IsTest
public class FishBoneController_Test {
	public static testMethod void test_Constructor_NoId() {
		PageReference testPage = Page.FishBone;

		// Quick value to ensure it doesn't complain about a blank config
		testPage.getParameters().put('config', 'test');

		Test.setCurrentPage(testPage);

		FishBoneController.FishboneException fishboneException;
		try {
			FishBoneController controller = new FishBoneController();
		} catch (FishBoneController.FishboneException e) {
			fishboneException = e;
		}

		System.assertNotEquals(null, fishboneException);
		System.assertEquals(FishBoneController.ERR_PARAM_NO_ID, fishboneException.getMessage());
	}

	public static testMethod void test_Constructor_NoConfig() {
		PageReference testPage = Page.FishBone;

		// Quick value to ensure it doesn't complain about a blank config
		testPage.getParameters().put('id', 'test');

		Test.setCurrentPage(testPage);

		FishBoneController.FishboneException fishboneException;
		try {
			FishBoneController controller = new FishBoneController();
		} catch (FishBoneController.FishboneException e) {
			fishboneException = e;
		}

		System.assertNotEquals(null, fishboneException);
		System.assertEquals(FishBoneController.ERR_PARAM_NO_CONFIG, fishboneException.getMessage());
	}

	public static testMethod void test_Constructor_InvalidConfig() {
		PageReference testPage = Page.FishBone;

		// Populate with acceptable value to avoid throwing parse exceptions
		testPage.getParameters().put('id', UserInfo.getProfileId());
		testPage.getParameters().put('config', 'test');

		Test.setCurrentPage(testPage);

		FishBoneController.FishboneException fishboneException;
		try {
			FishBoneController controller = new FishBoneController();
		} catch (FishBoneController.FishboneException e) {
			fishboneException = e;
		}

		System.assertNotEquals(null, fishboneException);
		System.assertEquals(FishBoneController.ERR_PARAM_INVALID_CONFIG, fishboneException.getMessage());
	}

	public static testMethod void test_buildQueryFromConfig() {
		FishBoneController.FishboneConfig config = new FishBoneController.FishboneConfig();
		config.sObjectName = 'TEST';
		config.branchConfig = new Map<String, String> {
			'TEST_LABEL' => 'TEST_FIELD__C',
			'TEST_LABEL_2' => 'TEST_FIELD2__C'
		};

		String expectedQueryString = 'SELECT TEST_FIELD__C, TEST_FIELD2__C FROM TEST WHERE Id = \'' + UserInfo.getProfileId() + '\'';
		String generatedQueryString = FishBoneController.buildQueryFromConfig(config, UserInfo.getProfileId());
		System.assertEquals(expectedQueryString, generatedQueryString);
	}

	public static testMethod void test_normalizeParams() {
		Map<String, String> testParams = new Map<String, String> {
			'PARAM1' => 'TEST',
			'param2' => 'TEST2'
		};

		Map<String, String> normalizedParams = FishBoneController.normalizeParams(testParams);

		for (String key : testParams.keySet()) {
			System.assert(normalizedParams.containsKey(key.toLowerCase()));
			System.assertEquals(testParams.get(key), normalizedParams.get(key.toLowerCase()));
		}
	}

	public static testMethod void test_FishBoneNode() {
		String expectedJSON = '{"name":"","children":[{"name":"ROOT","children":[{"name":"1","children":[{"name":"a","children":[]},{"name":"b","children":[]},{"name":"c","children":[]},{"name":"d","children":[]},{"name":"e","children":[]}]},{"name":"2","children":[{"name":"a","children":[]},{"name":"b","children":[]},{"name":"c","children":[]},{"name":"d","children":[]},{"name":"e","children":[]}]},{"name":"3","children":[{"name":"a","children":[]},{"name":"b","children":[]},{"name":"c","children":[]},{"name":"d","children":[]},{"name":"e","children":[]}]},{"name":"4","children":[{"name":"a","children":[]},{"name":"b","children":[]},{"name":"c","children":[]},{"name":"d","children":[]},{"name":"e","children":[]}]},{"name":"5","children":[{"name":"a","children":[]},{"name":"b","children":[]},{"name":"c","children":[]},{"name":"d","children":[]},{"name":"e","children":[]}]}]}]}';

		FishboneController.FishboneNode testNode = new FishboneController.FishboneNode();
		FishboneController.FishboneNode rootNode = testNode.addChild('ROOT').addChildren('1,2,3,4,5', ',');
		for (FishboneController.FishboneNode childNode : rootNode.children) {
		    childNode.addChildren('a;b;c;d;e', ';');
		}
		System.assertEquals(expectedJSON, testNode.toJSON());
	}

	public static testMethod void test_CaptureCoverage() {
		Contact testContact = new Contact();
		testContact.FirstName = 'FIRST';
		testContact.LastName = 'LAST';
		insert testContact;

		FishBoneController.FishboneConfig config = new FishBoneController.FishboneConfig();
		config.sObjectName = 'Contact';
		config.branchConfig = new Map<String, String> {
			'First Name' => 'FirstName'
		};

		PageReference testPage = Page.FishBone;

		// Quick value to ensure it doesn't complain about a blank config
		testPage.getParameters().put('config', EncodingUtil.urlEncode(JSON.serialize(config), 'UTF-8'));
		testPage.getParameters().put('id', testContact.Id);

		Test.setCurrentPage(testPage);

		FishBoneController controller = new FishBoneController();

		SObject controller_Record = controller.record;
		FishBoneController.FishboneConfig controller_Config = controller.config;
		String controller_FishboneData = controller.fishboneData;
	}
}