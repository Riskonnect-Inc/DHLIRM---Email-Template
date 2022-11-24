public class RKHierarchyTree_Controller {

    private static String rklHierarchySettingName = 'rkl__Hierarchy_Settings__c';

    private static Map<String, String> rklHierarchySettingFieldMappings = new Map<String, String> {
        'rkl__Hierarchy_Object__c' => 'sObjectName',
        'rkl__NodeCode__c' => 'codeField',
        'rkl__NodeKey__c' => 'keyField',
        'rkl__NodeName__c' => 'nameField',
        'rkl__ParentNode__c' => 'parentField',
        'rkl__ParentNodeKey__c' => 'parentKeyField',
        'rkl__Is_Leaf__c' => 'isLeafField'
    };

    @AuraEnabled
    public static String getCustomSetting() {
        Map<String, Object> response = new Map<String, Object>();

        Id currentUserId = UserInfo.getUserId();
        Id currentProfileId = UserInfo.getProfileId();
        Id currentOrgId = UserInfo.getOrganizationId();

        Schema.SObjectType customSettingType = Schema.getGlobalDescribe().get(rklHierarchySettingName);
        if (customSettingType != null) {
            // Query for the hierarchy settings instance that applies to the current user/profile
            String[] queryFields = new List<String>(rklHierarchySettingFieldMappings.keySet());
            String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM ' + rklHierarchySettingName + ' WHERE SetupOwnerId =: currentUserId OR SetupOwnerId =: currentProfileId OR SetupOwnerId =: currentOrgId LIMIT 1';

            SObject[] matchingCustomSettings = Database.query(query);
            if (matchingCustomSettings.size() > 0) {
                // Map each of these source fields to the target generic field
                SObject matchingCustomSetting = matchingCustomSettings[0];
                for (String sourceFieldName : rklHierarchySettingFieldMappings.keySet()) {
                    response.put(rklHierarchySettingFieldMappings.get(sourceFieldName), matchingCustomSetting.get(sourceFieldName));
                }
            }
        }

        // Serialize and return the response
        return JSON.serialize(response);
    }

    @AuraEnabled
    public static SObject[] getRootRecords(String pageConfigJSON) {
        Map<String, String> pageConfig = (Map<String, String>)JSON.deserialize(pageConfigJSON, Map<String, String>.class);

        String sObjectName = pageConfig.get('sObjectName');
        String[] fields = new String[]{};
        for (String key : pageConfig.keySet()) {
            if (!key.equals('sObjectName') && String.isNotBlank(pageConfig.get(key))) {
                fields.add(pageConfig.get(key));
            }
        }

        return Database.query('SELECT ' + String.join(fields, ',') + ' FROM ' + sObjectName + ' WHERE ' + pageConfig.get('parentField') + ' = null');
    }

    private static String parentQuery_Format = 'SELECT Id, {0}.{0}.{0}.{0}.{1} FROM {2} WHERE Id =: {3}';
    // NOTE: Only works with custom lookup/MD fields
    private static Id[] getPathToRootIds(Id targetId, String sObjectName, String parentField) {
        Id[] parentIds = new Id[]{targetId};

        String parentFieldRel = parentField.replaceAll('(?i)__c$', '__r');
        String queryString = String.format(parentQuery_Format, new String[]{parentFieldRel, parentField, sObjectName, 'lastId'});
        Id lastId = targetId;

        while (lastId != null) {
            SObject lastRecord = Database.query(queryString);

            // Can't check __r without throwing exception. However, __c version is automatically included when __r is queried
            while (String.isNotBlank((Id)lastRecord.get(parentField))) {
                try {
                    lastRecord = lastRecord.getSObject(parentFieldRel);
                } catch (SObjectException e) {
                    // Must be at the end of the related object chain. Break out of the loop.
                    break;
                }
                parentIds.add(lastRecord.Id);
            }

            Id endOfChainId = (Id)lastRecord.get(parentField);
            if (endOfChainId != null) {
                parentIds.add(endOfChainId);
            }
            lastId = endOfChainId;
        }

        return parentIds;
    }

    @AuraEnabled
    public static Id[] getPathToRootIds(Id targetId, String pageConfigJSON) {
        Map<String, String> pageConfig = (Map<String, String>)JSON.deserialize(pageConfigJSON, Map<String, String>.class);

        String sObjectName = pageConfig.get('sObjectName');
        String parentField = pageConfig.get('parentField');
        
        return getPathToRootIds(targetId, sObjectName, parentField);
    }

    private static String childQuery_Format = 'SELECT Id, Name, {0} FROM {1} WHERE {2} =: {3}';
    @AuraEnabled
    public static SObject[] getChildren(Id parentId, String pageConfigJSON){
        Map<String, String> pageConfig = (Map<String, String>)JSON.deserialize(pageConfigJSON, Map<String, String>.class);

        String sObjectName = pageConfig.get('sObjectName');
        String parentField = pageConfig.get('parentField');
        String nameField = pageConfig.get('nameField');

        String queryString = String.format(childQuery_Format, new String[]{nameField, sObjectName, parentField, 'parentId'});

        return Database.query(queryString);
    }

    @AuraEnabled
    public static Id startRebuild() {
        return rkl.HierarchyTreeBuilder.startBuilder();
    }

    @AuraEnabled
    public static SObject getBatchProgress(Id jobId) {
        return [SELECT ID, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, ExtendedStatus FROM AsyncApexJob WHERE ID =: jobId LIMIT 1];
    }
}