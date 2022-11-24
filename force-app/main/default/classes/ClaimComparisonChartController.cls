/*===========================================================================
     Added to RK base RMIS product as 11/14/2014 
===========================================================================*/
public class ClaimComparisonChartController {
    public ClaimComparisonChartController() {
        
    }

    @RemoteAction
    public static Map<String, Object> getObjectDescribe(String objectName) {
        //Default to Claim__c if no value was passed in
        if (String.isBlank(objectName)) {
            objectName = 'Claim__c';
        }

        //Create result container
        Map<String, Object> result = new Map<String, Object>();

        //Find matching SObjectType for the object name passed in. If one is not found, throw an error
        Schema.SObjectType matchingSObjectType = Schema.getGlobalDescribe().get(objectName);
        if (matchingSObjectType == null) {
            result.put('error', true);
            result.put('message', 'Table: "' + objectName + '" does not exist in this org.');
            return result;
        }

        //Get the describe info for the current object and add this info to the result container
        Schema.DescribeSObjectResult sobjectDescribe = matchingSObjectType.getDescribe();
        result.put('label', sobjectDescribe.getLabel());
        result.put('fullName', sobjectDescribe.getName());
        result.put('localName', sobjectDescribe.getLocalName());

        //Get the describe info for each field on this object and add this info to the result container
        Map<String, Map<String, Object>> fieldResults = new Map<String, Map<String, Object>>();
        List<String> fieldNameArray = new List<String>();
        Map<String, Schema.SObjectField> allFields = sobjectDescribe.fields.getMap();
        for (String fieldName : allFields.keySet()) {
            Schema.DescribeFieldResult currentFieldDescribe = allFields.get(fieldName).getDescribe();
            Map<String, Object> fieldResult = new Map<String, Object>();
            fieldResult.put('label', currentFieldDescribe.getLabel());
            fieldResult.put('name', currentFieldDescribe.getName());
            fieldNameArray.add(currentFieldDescribe.getName());
            fieldResult.put('localName', currentFieldDescribe.getLocalName());
            fieldResult.put('displayType', currentFieldDescribe.getType().name());
            fieldResult.put('relName', currentFieldDescribe.getRelationshipName());
            fieldResult.put('relOrder', currentFieldDescribe.getRelationshipOrder());
            fieldResult.put('isCustom', currentFieldDescribe.isCustom());
            fieldResult.put('length', currentFieldDescribe.getLength());
            fieldResult.put('isRequired', !currentFieldDescribe.isNillable());
            List<Map<String, String>> picklistValues = new List<Map<String, String>>();
            if (currentFieldDescribe.isNillable() && currentFieldDescribe.getPicklistValues().size() > 0) {
                picklistValues.add(new Map<String, String> {'value' => '', 'label' => ''});
            }
            for (Schema.PicklistEntry picklistEntry : currentFieldDescribe.getPicklistValues()) {
                picklistValues.add(new Map<String, String> {'value' => picklistEntry.getValue(), 'label' => picklistEntry.getLabel()});
            }
            fieldResult.put('picklistValues', picklistValues);
            fieldResults.put(String.valueOf(fieldResult.get('name')), fieldResult);
        }
        result.put('fields', fieldResults);
        result.put('fieldNames', fieldNameArray);
        result.put('error', false);
        return result;
    }

    public class FieldSetQueryException extends Exception {}

    @RemoteAction
    public static List<Map<String, Object>> getFieldSettings(String objectName, String fieldSetName) {
        List<Map<String, Object>> response = new List<Map<String, Object>>();
        Schema.DescribeSObjectResult sobjectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Map<String, Schema.FieldSet> allFieldSets = sobjectDescribe.FieldSets.getMap();
        Schema.FieldSet targetFieldSet = allFieldSets.get(fieldSetName);
        if (targetFieldSet != null) {
            for (Schema.FieldSetMember field : targetFieldSet.getFields()) {
                Map<String, Object> fieldResponse = new Map<String, Object>();
                fieldResponse.put('fieldName', field.getFieldPath());
                fieldResponse.put('isEnabled', field.getRequired());
                response.add(fieldResponse);
            }
        } else {
            throw new FieldSetQueryException('No matching field set: "' + fieldSetName + '" on object: "' + objectName + '"');
        }
        return response;
    }

    public class RecordQueryException extends Exception {}

    @RemoteAction
    public static Map<String, Object> queryRecord(String tableName, List<String> fieldNames, String recordID) {
        if (String.isNotBlank(tableName) && fieldNames != null && fieldNames.size() > 0 && String.isNotBlank(recordID)) {
            String query = 'SELECT ';
            Boolean hasIDField = false;
            for (String fieldName : fieldNames) {
                query += fieldName + ',';
                if (fieldName.equalsIgnoreCase('id')) {
                    hasIDField = true;
                }
            }
            if (!hasIDField) {
                fieldNames.add('Id');
            }
            query = query.substring(0, query.lastIndexOf(',')) + ' FROM ' + tableName + ' WHERE ID = \'' + recordID + '\'';

            List<SObject> matchingRecords = Database.query(query);
            if (matchingRecords.size() > 0) {
                SObject matchingRecord = matchingRecords.get(0);
                Map<String, Object> response = new Map<String, Object>();
                for (String fieldName : fieldNames) {
                    if (fieldName.equalsIgnoreCase('id')) {
                        response.put(fieldName, String.valueOf(matchingRecord.get(fieldName))/*.substring(0, 15)*/);
                    } else {
                        Object fieldValue = matchingRecord.get(fieldName);
                        if (fieldValue instanceof Date && fieldValue != null) {
                            Date fieldValueDate = (Date)fieldValue;
                            response.put(fieldName, (DateTime.newInstance(fieldValueDate.year(), fieldValueDate.month(), fieldValueDate.day())).getTime());
                        } else if (fieldValue instanceof DateTime && fieldValue != null) {
                            response.put(fieldName, ((DateTime)fieldValue).getTime());
                        } else {
                            response.put(fieldName, fieldValue);
                        }
                    }
                }
                return response;
            
            //IF NO MATCHING RECORDS FOUND
            } else {
                //throw new RecordQueryException('No records found on table: "' + tableName + '" with ID: "' + recordID + '"');
                return null;
            }
            
        //IF INVALID INPUT PARAMETERS
        } else {
            String exceptionMessage = '';
            if (String.isBlank(tableName)) {
                exceptionMessage += 'Object name not specified,';
            }
            if (fieldNames == null || fieldNames.size() == 0) {
                exceptionMessage += 'Queried fields are not specified,';
            }
            if (String.isBlank(recordID)) {
                exceptionMessage += 'ID of record not specified,';
            }
            exceptionMessage = exceptionMessage.substring(0, exceptionMessage.lastIndexOf(','));
            throw new ClaimComparisonChartController.RecordQueryException('Missing data in query request: ' + exceptionMessage);
        }
    }

    @RemoteAction
    public static List<Map<String, Object>> querySimilarRecords(String tableName, List<String> fieldNames, String whereClause, String lastID, Integer chunkSize) {
        if (String.isNotBlank(tableName) && fieldNames != null && fieldNames.size() > 0) {
            String query = 'SELECT ';
            Boolean hasIDField = false;
            for (String fieldName : fieldNames) {
                query += fieldName + ',';
                if (fieldName.equalsIgnoreCase('id')) {
                    hasIDField = true;
                }
            }
            if (!hasIDField) {
                fieldNames.add('Id');
            }

            if (String.isNotBlank(whereClause)) {
                if (String.isNotBlank(lastID)) {
                    whereClause += ' AND ID > \'' + lastID + '\'';
                }
            } else {
                if (String.isNotBlank(lastID)) {
                    whereClause = 'ID > \'' + lastID + '\'';
                }
            }
            query = query.substring(0, query.lastIndexOf(',')) + ' FROM ' + tableName + (String.isNotBlank(whereClause)?(' WHERE ' + whereClause):'') + ' ORDER BY ID ASC LIMIT ' + chunkSize;

            List<SObject> matchingRecords = Database.query(query);
            if (matchingRecords.size() > 0) {
                List<Map<String, Object>> response = new List<Map<String, Object>>();

                for (SObject record : matchingRecords) {
                    Map<String, Object> recordResponse = new Map<String, Object>();
                    for (String fieldName : fieldNames) {
                        if (fieldName.equalsIgnoreCase('id')) {
                            recordResponse.put(fieldName, String.valueOf(record.get(fieldName)).substring(0, 15));
                        } else {
                            Object fieldValue = record.get(fieldName);
                            if (fieldValue instanceof Date && fieldValue != null) {
                                Date fieldValueDate = (Date)fieldValue;
                                recordResponse.put(fieldName, (DateTime.newInstance(fieldValueDate.year(), fieldValueDate.month(), fieldValueDate.day())).getTime());
                            } else if (fieldValue instanceof DateTime && fieldValue != null) {
                                recordResponse.put(fieldName, ((DateTime)fieldValue).getTime());
                            } else {
                                recordResponse.put(fieldName, fieldValue);
                            }
                        }
                    }
                    response.add(recordResponse);
                }
                return response;            
            //IF NO MATCHING RECORDS FOUND
            } else {
                throw new RecordQueryException('No records found on table: "' + tableName + '" with conditions: "' + whereClause + '"');
            }
            
        //IF INVALID INPUT PARAMETERS
        } else {
            String exceptionMessage = '';
            if (String.isBlank(tableName)) {
                exceptionMessage += 'Object name not specified,';
            }
            if (fieldNames == null || fieldNames.size() == 0) {
                exceptionMessage += 'Queried fields are not specified,';
            }
            exceptionMessage = exceptionMessage.substring(0, exceptionMessage.lastIndexOf(','));
            throw new ClaimComparisonChartController.RecordQueryException('Missing data in query request: ' + exceptionMessage);
        }
    }

    @RemoteAction
    public static List<Map<String, Object>> getInDevelopmentClaims(List<String> fieldNames, String whereClause, Integer ageOfClaim, String lastID, Integer chunkSize) {
        //SELECT Claim__c, Claim__r.Date_of_Loss__c, SUM(Indemnity_PD_Reserve__c) indemnityPDRes, SUM(Medical_BI_Reserve__c) medicalBIRes, SUM(Expense_Reserve__c) expenseRes, SUM(Recovery_Paid__c) recoveryRec FROM Claim_Transaction__c WHERE Age_of_Claim__c <= 758 AND Claim__c IN (SELECT ID FROM Claim__c WHERE (Coverage_Major__c='PROF')) GROUP BY Claim__c, Claim__r.Date_of_Loss__c
        //NET_INCURRED__C = GROSS_INCURRED__C + recoveryRec
        //GROSS_INCURRED__C = indemnityPDRes + medicalBIRes + expenseRes
        if (String.isNotBlank(whereClause)) {
            if (String.isNotBlank(lastID)) {
                whereClause += ' AND ID > \'' + lastID + '\'';
            }
        } else {
            if (String.isNotBlank(lastID)) {
                whereClause = 'ID > \'' + lastID + '\'';
            }
        }
        String claimQuery = 'SELECT ID FROM Claim__c' + (String.isNotBlank(whereClause)?' WHERE ' + whereClause :'') + ' ORDER BY ID ASC LIMIT ' + chunkSize;
        List<SObject> matchingClaims = Database.query(claimQuery);
        String claimIDsSOQLList = '';
        if (matchingClaims.size() > 0) {
            for (SObject claim : matchingClaims) {
                claimIDsSOQLList += '\'' + claim.get('ID') + '\',';
            }
            claimIDsSOQLList = claimIDsSOQLList.substring(0, claimIDsSOQLList.lastIndexOf(','));
        }

        if (String.isNotBlank(claimIDsSOQLList)) {
            Set<String> doNotDirectQuery = new Set<String> {'Net_Incurred__c', 'Gross_Incurred__c', 'Age_of_Claim__c'};
            Set<String> validFieldNames = new Set<String>();
            String extraFieldNames = '';
            if (fieldNames != null && fieldNames.size() > 0) {
                String query = 'SELECT Claim__c,';
                Boolean hasIDField = false;
                for (String fieldName : fieldNames) {
                    if (!doNotDirectQuery.contains(fieldName)) {
                        extraFieldNames += 'Claim__r.' + fieldName + ',';
                        validFieldNames.add(fieldName);
                    }
                }
                query += extraFieldNames + ' SUM(Indemnity_PD_Reserve__c) indemnityPDRes, SUM(Medical_BI_Reserve__c) medicalBIRes, SUM(Expense_Reserve__c) expenseRes, SUM(Recovery_Paid__c) recoveryRec FROM Claim_Transaction__c WHERE Age_of_Claim__c <= ' + ageOfClaim + ' AND Claim__c IN (' + claimIDsSOQLList + ') GROUP BY Claim__c' + (String.isNotBlank(extraFieldNames)?',' + extraFieldNames.substring(0, extraFieldNames.lastIndexOf(',')):'');
                
                List<AggregateResult> matchingRecords = Database.query(query);
                List<Map<String, Object>> response = new List<Map<String, Object>>();
                if (matchingRecords.size() > 0) {

                    for (AggregateResult record : matchingRecords) {
                        Map<String, Object> recordResponse = new Map<String, Object>();
                        
                        Double grossIncurred = ((Double)record.get('indemnityPDRes')) + ((Double)record.get('medicalBIRes')) + ((Double)record.get('expenseRes')),
                            netIncurred = grossIncurred + ((Double)record.get('recoveryRec'));

                        recordResponse.put('Net_Incurred__c', roundIntegerToPlace(netIncurred, 2));
                        recordResponse.put('Gross_Incurred__c', roundIntegerToPlace(grossIncurred, 2));
                        recordResponse.put('Id', record.get('Claim__c'));

                        for (String fieldName : validFieldNames) {
                            Object fieldValue = record.get(fieldName);
                            if (fieldValue instanceof Date && fieldValue != null) {
                                Date fieldValueDate = (Date)fieldValue;
                                recordResponse.put(fieldName, (DateTime.newInstance(fieldValueDate.year(), fieldValueDate.month(), fieldValueDate.day())).getTime());
                            } else if (fieldValue instanceof DateTime && fieldValue != null) {
                                recordResponse.put(fieldName, ((DateTime)fieldValue).getTime());
                            } else {
                                recordResponse.put(fieldName, fieldValue);
                            }
                        }
                        response.add(recordResponse);
                    }
                }
                return response;
            } else {
                String exceptionMessage = '';
                if (fieldNames == null || fieldNames.size() == 0) {
                    exceptionMessage += 'Queried fields are not specified,';
                }
                exceptionMessage = exceptionMessage.substring(0, exceptionMessage.lastIndexOf(','));
                throw new ClaimComparisonChartController.RecordQueryException('Missing data in query request: ' + exceptionMessage);
            }
        //IF INVALID INPUT PARAMETERS
        } else {
            throw new RecordQueryException('No records found on table: "Claim__c" with conditions: "' + whereClause + '"');
        }
    }

    public static Double roundIntegerToPlace(Double num, Integer decimalPlaces) {
        if (num == null) { return 0; }
        Decimal decimalPlace = Math.pow(10, decimalPlaces);
        return Math.round(num * decimalPlace) / decimalPlace;
    }


    @RemoteAction
    public static String formatMSInLocaleDateTime(Long timeInMS) {
        return DateTime.newInstance(timeInMS).format();
    }

    @RemoteAction
    public static String formatMSInLocaleDate(Long timeInMS) {
        DateTime asDateTime = DateTime.newInstance(timeInMS);
        return asDateTime.dateGMT().format();
    }
}