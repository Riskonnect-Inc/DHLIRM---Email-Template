public class DerivedRecord_Controller {
    @AuraEnabled
    public static String getObjectLabel(Id sourceId) {
        // Create response wrapper
        AuraResponse response = new AuraResponse();

        try {
            //Note: added to check if the claim have been already connected.
            Intake__c intake = [Select id, converted_to_claim__c from Intake__c where id =: sourceId];
            if(intake != null){
                if (intake.converted_to_claim__c){
                    return 'EXIST';
                }
            }
            // Retrieve object label from source Id
            response.payload = sourceId.getSObjectType().getDescribe().getLabel();
        } catch (Exception e) {
            // Catch any error thrown and pass the error info down to the client via the response wrapper
            response.error = e.getMessage();
            response.errorStack = e.getStackTraceString();
        }

        // Serialize and return the response wrapper
        return JSON.serialize(response);
    }

    @AuraEnabled
    public static String checkIfHasBeenConverted(Id sourceId, String sObjectName, String sObjectLabel) {
        // Create response wrapper
        AuraResponse response = new AuraResponse();

        try {
            // Parse out the destination object's name from the full API name
            /*String sObjectName_Clean = '';
            String[] sObjectName_Parts = sObjectName.split('__');
            if (sObjectName_Parts.size() == 3) {
                sObjectName_Clean = sObjectName_Parts[1];
            } else {
                sObjectName_Clean = sObjectName_Parts[0];
            }*/

            String sObjectName_Clean = sObjectLabel.replaceAll(' ', '_');

            // Determine the "converted to" flag field name
            String convertedFlagFieldName = 'converted_to_' + sObjectName_Clean.toLowerCase() + '__c';

            // Retrieve source sobject describe info
            Schema.SObjectType sourceSObjectType = sourceId.getSObjectType();
            String sourceSObjectName = String.valueOf(sourceSObjectType);

            if (sourceSObjectType.getDescribe().fields.getMap().containsKey(convertedFlagFieldName)) {
                // Retrieve the source record from the DB
                SObject sourceRecord = Database.query('SELECT Id, ' + convertedFlagFieldName + ' FROM ' + sourceSObjectName + ' WHERE Id =: sourceId');

                // If the field has been set to true, that signals that the record has already been converted
                response.payload = (Boolean)sourceRecord.get(convertedFlagFieldName);
            } else {
                // If the field doesn't exist, then it won't be blocked from being converted
                response.payload = false;
            }
        } catch (Exception e) {
            // Catch any error thrown and pass the error info down to the client via the response wrapper
            response.error = e.getMessage();
            response.errorStack = e.getStackTraceString();
        }

        // Serialize and return the response wrapper
        return JSON.serialize(response);
    }

    @AuraEnabled
    public static String convertRecord(Id sourceId, String configName, String sObjectLabel, String sObjectName) {
        // Create response wrapper
        AuraResponse response = new AuraResponse();

        try {
            // Call to the derived records process
            rkl.DerivedRecordUtils.DerivedResult derivedResult = rkl.DerivedRecordUtils.deriveRecord(configName, sourceId);

            // TODO: Enable this once it has been exposed in RKL
            /*if (derivedResult.errors != null && derivedResult.errors.size() > 0) {
                throw new AuraActionException(String.join(derivedResult.errors, '\n'));
            }*/

            // Parse out the destination object's name from the full API name
            /*String sObjectName_Clean = '';
            String[] sObjectName_Parts = sObjectName.split('__');
            if (sObjectName_Parts.size() == 3) {
                sObjectName_Clean = sObjectName_Parts[1];
            } else {
                sObjectName_Clean = sObjectName_Parts[0];
            }*/

            String sObjectName_Clean = sObjectLabel.replaceAll(' ', '_');

            // Determine the "converted to" flag field name
            String convertedFlagFieldName = 'converted_to_' + sObjectName_Clean.toLowerCase() + '__c';

            // Retrieve source sobject describe info
            Schema.SObjectType sourceSObjectType = sourceId.getSObjectType();
            String sourceSObjectName = String.valueOf(sourceSObjectType);

            // Check if the target "converted to" field exists on the source object
            if (sourceSObjectType.getDescribe().fields.getMap().containsKey(convertedFlagFieldName)) {
                // Retrieve the source record from the DB
                SObject sourceRecord = Database.query('SELECT Id FROM ' + sourceSObjectName + ' WHERE Id =: sourceId');

                // Update the "converted to" flag
                sourceRecord.put(convertedFlagFieldName, true);

                // Update the source record
                update sourceRecord;
            }
        } catch (Exception e) {
            // Catch any error thrown and pass the error info down to the client via the response wrapper
            response.error = e.getMessage();
            response.errorStack = e.getStackTraceString();
        }

        // Serialize and return the response wrapper
        return JSON.serialize(response);
    }

    @AuraEnabled
    public static String getApplicableConfigs(Id sourceId) {
        // Create response wrapper
        AuraResponse response = new AuraResponse();

        try {
            // Validate record id
            if (String.isBlank(sourceId)) {
                throw new AuraActionException('Invalid source record Id.');
            }

            // Retrieve API name of source record
            String sObjectType = String.valueOf(sourceId.getSobjectType());

            // Build source record query, needed to check record type
            String sourceRecordQuery = 'SELECT Id, RecordTypeId FROM ' + sObjectType + ' WHERE Id =: sourceId';

            // Query for source record and validate response
            SObject[] sourceRecords = Database.query(sourceRecordQuery);
            if (sourceRecords.size() == 0) {
                throw new AuraActionException('Could not find source record. It may have been deleted.');
            }

            // Retrieve source record from query response
            SObject sourceRecord = sourceRecords[0];
            String sourceRecordTypeDeveloperName = '';

            // Check if the source record has a record type, and if so retrieve its developer name. This will be used later to match against a derived record config
            if (sourceRecord.get('RecordTypeId') != null) {
                // Retrieve the record type id from the source record
                Id sourceRecordTypeId = (Id)sourceRecord.get('RecordTypeId');

                // Build query string for source record type
                String sourceRecordTypeQuery = 'SELECT Id, DeveloperName FROM RecordType WHERE Id =: sourceRecordTypeId';

                // Query for source record type and validate response
                RecordType[] sourceRecordTypes = Database.query(sourceRecordTypeQuery);
                if (sourceRecordTypes.size() == 0) {
                    throw new AuraActionException('Could not find source record type. It may have been deleted.');
                }

                // Retrieve source record type from query response
                RecordType sourceRecordType = sourceRecordTypes[0];

                // Retrieve source record type developer name
                sourceRecordTypeDeveloperName = sourceRecordType.DeveloperName;
            }

            // Build query string for matching derived record configs
            String derivedRecordConfigQuery = 'SELECT Id, Name, rkl__Destination_Object__c FROM rkl__Derived_Record_Config__c WHERE rkl__Source_Object__c =: sObjectType AND rkl__Source_Record_Type__c =: sourceRecordTypeDeveloperName ORDER BY Id ASC';

            // Query for matching derived record configs and validate response
            SObject[] derivedRecordConfigs = Database.query(derivedRecordConfigQuery);
            if (derivedRecordConfigs.size() == 0) {
                throw new AuraActionException('Could not find any applicable derived record configs.');
            }

            // Build payload structure for derived record config data
            List<Map<String, String>> derivedRecordConfigData = new List<Map<String, String>>();
            response.payload = derivedRecordConfigData;

            // Fill payload with derived record config data
            for (SObject derivedRecordConfig : derivedRecordConfigs) {
                // Create internal payload structure for this particular config record
                Map<String, String> configData = new Map<String, String>();
                derivedRecordConfigData.add(configData);

                // Retrieve field data from config record
                String targetSObjectName = (String)derivedRecordConfig.get('rkl__Destination_Object__c');
                Schema.DescribeSObjectResult targetSObjectDescribe = Schema.getGlobalDescribe().get(targetSObjectName).getDescribe();
                String targetSObjectLabel = targetSObjectDescribe.getLabel();

                // Populate internal payload structure with this config record's field data
                configData.put('label', targetSObjectLabel);
                configData.put('name', targetSObjectName);
                configData.put('config_name', (String)derivedRecordConfig.get('name'));
            }
        } catch (Exception e) {
            // Catch any error thrown and pass the error info down to the client via the response wrapper
            response.error = e.getMessage();
            response.errorStack = e.getStackTraceString();
        }

        // Serialize and return the response wrapper
        return JSON.serialize(response);
    }

    public class AuraActionException extends Exception {}

    public class AuraResponse {
        public String error {get; set;}
        public String errorStack {get; set;}
        public Object payload {get; set;}
    }
}