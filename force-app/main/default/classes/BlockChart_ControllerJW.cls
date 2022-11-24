global with sharing class BlockChart_ControllerJW {

    public Object policySearchConfig {get; private set;}
    public Object policySectionSearchConfig {get; private set;}
    public Object policyParticipantSearchConfig {get; private set;}

    public String policyGridFieldsConfig {get; private set;}
    public String policySectionGridFieldsConfig {get; private set;}
    public String policyParticipantGridFieldsConfig {get; private set;}

    public Object policyMapSearchConfig {get; private set;}

    public Object attachmentSearchConfig {get; private set;}

    public Policy_Map__c policyMap {get; set;}

    public String currentPolicyMapId {get; private set;}
    public Boolean newPolicyMode {get; private set;}

    public String startDateMS {get; private set;}
    public String endDateMS {get; private set;}
    public String coveragesJSON {get; private set;}

    public String dataLevel {get; private set;}
    public String scaleConfigJSON {get; private set;}
    public String yAxisIntervalJSON {get; private set;}
    public String upperBoundValue {get; private set;}

    public BlockChart_ControllerJW(ApexPages.StandardController stndController) {
        this((rkl.JS_Search)null);
    }

    public BlockChart_ControllerJW(rkl.JS_Search ignore) {
        policyGridFieldsConfig = JSON.serialize(getGridFields('Policy__c'));
        policySectionGridFieldsConfig = JSON.serialize(getGridFields('Policy_Section__c'));
        policyParticipantGridFieldsConfig = JSON.serialize(getGridFields('Policy_Participant__c'));

        policySearchConfig = rkl.RKSearch.consumeConfig(new Map<String, Object> {
            'objectApi' => 'Policy__c',
            'resultFields' => 'PolicyMapSearchResults',
            'searchFields' => 'PolicyMapSearchFilters',
            'filtersOpen' => true,
            'type' => 'unRelatedList',
            'links' => true,
            'relOptions' => new Map<String,Object>{'del' => false, 'add' => false, 'edit' => false},
            'title' => 'Add Policies to Map',
            'operatorOrders' => new Map<String, Object> {
                'Text' => new String[]{'C', '!C', '=', '!=', 'SW', 'EW'},
                'Pick' => new String[]{'I', 'E', '=', '!='}
            }
        });

        policySearchConfig = JSON.serialize(policySearchConfig);

        policySectionSearchConfig = rkl.RKSearch.consumeConfig(new Map<String, Object> {
            'objectApi' => 'Policy_Section__c',
            'resultFields' => 'PolicyMapSearchResults',
            'searchFields' => 'PolicyMapSearchFilters',
            'filtersOpen' => true,
            'type' => 'unRelatedList',
            'links' => true,
            'relOptions' => new Map<String,Object>{'del' => false, 'add' => false, 'edit' => false},
            'title' => 'Add Policy Sections to Map',
            'operatorOrders' => new Map<String, Object> {
                'Text' => new String[]{'C', '!C', '=', '!=', 'SW', 'EW'},
                'Pick' => new String[]{'I', 'E', '=', '!='}
            }
        });

        policySectionSearchConfig = JSON.serialize(policySectionSearchConfig);

        policyParticipantSearchConfig = rkl.RKSearch.consumeConfig(new Map<String, Object> {
            'objectApi' => 'Policy_Participant__c',
            'resultFields' => 'PolicyMapSearchResults',
            'searchFields' => 'PolicyMapSearchFilters',
            'filtersOpen' => true,
            'type' => 'unRelatedList',
            'links' => true,
            'relOptions' => new Map<String, Object>{'del' => false, 'add' => false, 'edit' => false},
            'title' => 'Add Policy Participants to Map',
            'operatorOrders' => new Map<String, Object> {
                'Text' => new String[]{'C', '!C', '=', '!=', 'SW', 'EW'},
                'Pick' => new String[]{'I', 'E', '=', '!='}
            }
        });

        policyParticipantSearchConfig = JSON.serialize(policyParticipantSearchConfig);

        newPolicyMode = true;
        currentPolicyMapId = ApexPages.currentPage().getParameters().get('id');
        upperBoundValue = 'null';
        if (currentPolicyMapId != null) {
            newPolicyMode = false;
            policyMap = [
                SELECT 
                    Id, Name, Data_Level__c, Filter_Criteria__c,
                    Coverages__c, Start_Date__c, End_Date__c, Vertical_Scale__c,
                    Vertical_Maximum__c, Y_Axis_Ticks__c
                FROM Policy_Map__c
                WHERE Id =: currentPolicyMapId
            ];

            if (policyMap.Start_Date__c != null) {
                startDateMS = String.valueOf(DateTime.newInstanceGMT(policyMap.Start_Date__c, Time.newInstance(0, 0, 0, 0)).getTime());
            }

            if (policyMap.End_Date__c != null) {
                endDateMS = String.valueOf(DateTime.newInstanceGMT(policyMap.End_Date__c, Time.newInstance(0, 0, 0, 0)).getTime());
            }

            if (policyMap.Coverages__c != null) {
                coveragesJSON = JSON.serialize(policyMap.Coverages__c.split(';'));
            }

            if (String.isNotBlank(policyMap.Vertical_Scale__c)) {
                scaleConfigJSON = policyMap.Vertical_Scale__c;
            }

            if (String.isNotBlank(policyMap.Y_Axis_Ticks__c)) {
                yAxisIntervalJSON = policyMap.Y_Axis_Ticks__c;
            }

            if (policyMap.Vertical_Maximum__c != null) {
                upperBoundValue = String.valueOf(policyMap.Vertical_Maximum__c);
            }

            if (String.isNotBlank(policyMap.Data_Level__c)) {
                dataLevel = policyMap.Data_Level__c;
            }
        }
    }

    @RemoteAction
    global static Object saveNewPolicyMap(String policyMapName, String dataLevel, String scaleConfig, Double upperBounds, String filtersJSON){
        Policy_Map__c policyMap = new Policy_Map__c(
            Name = policyMapName,
            Filter_Criteria__c = filtersJSON,
            Data_Level__c = dataLevel,
            Vertical_Scale__c = scaleConfig,
            Vertical_Maximum__c = upperBounds
        );
        insert policyMap;

        return new Map<String,Object>{'success' => true, 'message' => 'Success', 'id' => policyMap.Id};
    }

    @RemoteAction
    global static Object savePolicyMap(Id id, String filtersJSON, String name) {
        Policy_Map__c policyMap = [SELECT Id FROM Policy_Map__c WHERE Id =: id FOR UPDATE];
        policyMap.Filter_Criteria__c = filtersJSON;
        if(String.isNotBlank(name)){
            policyMap.Name = name;
        }
        update policyMap;

        return new Map<String, Object> {'success' => true, 'message' => 'Success', 'id' => policyMap.Id};
    }

    @RemoteAction
    global static Object saveColors(String colorMapJson){
        Map<String,Object> colorMap = (Map<String,Object>)JSON.deserializeUntyped(colorMapJson);
        Set<String> colorMapIdsSet = colorMap.keySet();
        List<String> colorMapIds = new List<String>(colorMapIdsSet);

        if (colorMapIds.size() > 0) {
            Id firstId = Id.valueOf(colorMapIds[0]);
            Schema.SObjectType objectType = firstId.getSobjectType();

            SObject[] matchingRecords = Database.query('SELECT Id, Color__c FROM ' + objectType + ' WHERE Id IN: colorMapIdsSet FOR UPDATE');
            for (SObject matchingRecord : matchingRecords) {
                String color = String.valueOf(colorMap.get(matchingRecord.Id));
                matchingRecord.put('Color__c', color);
            }

            try {
                update matchingRecords;
            } catch (Exception e) {
                return new Map<String, Object> {'success' => false, 'message' => e.getMessage()};
            }
            return new Map<String,Object> {'success' => true, 'message' => 'Policy colors saved successfully'};
        }

        return new Map<String, Object> {'success' => true, 'message' => 'No policy colors to save'};
    }

    @RemoteAction
    global static Object updateScale(Id policyMapId, String scaleConfig) {
        try {
            Policy_Map__c policyMap = [SELECT Id FROM Policy_Map__c WHERE Id =: policyMapId FOR UPDATE];
            policyMap.Vertical_Scale__c = scaleConfig;
            update policyMap;

            return new Map<String, Object> {'success' => true, 'message' => 'Policy Map scale saved successfully'};
        } catch (Exception e) {
            return new Map<String, Object> {'success' => false, 'message' => e.getMessage()};
        }
    }

    @RemoteAction
    global static Object updateUpperBounds(Id policyMapId, Double upperBounds) {
        try {
            Policy_Map__c policyMap = [SELECT Id FROM Policy_Map__c WHERE Id =: policyMapId FOR UPDATE];
            policyMap.Vertical_Maximum__c = upperBounds;
            update policyMap;

            return new Map<String, Object> {'success' => true, 'message' => 'Policy Map upper bounds saved successfully'};
        } catch (Exception e) {
            return new Map<String, Object> {'success' => false, 'message' => e.getMessage()};
        }
    }

    @RemoteAction
    global static Object updateYAxisIntervals(Id policyMapId, String intervalValues) {
        try {
            Policy_Map__c policyMap = [SELECT Id FROM Policy_Map__c WHERE Id =: policyMapId FOR UPDATE];
            policyMap.Y_Axis_Ticks__c = intervalValues;
            update policyMap;

            return new Map<String, Object> {'success' => true, 'message' => 'Policy Map upper y-axis intervals saved successfully'};
        } catch (Exception e) {
            return new Map<String, Object> {'success' => false, 'message' => e.getMessage()};
        }
    }

    private static List<Map<String, String>> getGridFields(String objectName) {
        List<Map<String, String>> fieldDatas = new List<Map<String, String>>();
        
        try {
            for (String fieldName : rkl.DescribeHandler.getFieldSetFields(objectName, 'PolicyMapGrid').keySet()) {
                Schema.DescribeFieldResult fieldDescribe = rkl.DescribeHandler.getFieldDescribe(objectName, fieldName);

                fieldDatas.add(new Map<String, String> {
                    'name' => fieldName.toLowerCase(),
                    'label' => fieldDescribe.getLabel(),
                    'type' => String.valueOf(fieldDescribe.getType()).toLowerCase()
                });
            }
        } catch (Exception e) {}

        return fieldDatas;
    }
}