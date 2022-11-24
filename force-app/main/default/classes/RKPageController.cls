/*===========================================================================
     Added to RK base RMIS product as  6/1/2015
    ===========================================================================*/
    
global virtual class RKPageController {

    public static String getBasePath() {
        String baseURL = Site.getBaseURL();
        if (String.isBlank(baseURL)) {
            baseURL = URL.getSalesforceBaseURL().toExternalForm();
        }
        return baseURL;
    }

    @RemoteAction
    global static Map<String, Object> initialize() {
        Map<String, Object> initialParams = new Map<String, Object>();
        DateTime now = System.now();
        initialParams.put('locale', UserInfo.getLocale());
        initialParams.put('date_today', Date.newInstance(now.year(), now.month(), now.day()).format());
        initialParams.put('date_first', Date.newInstance(2010, 1, 1).format());
        initialParams.put('sessionId', UserInfo.getSessionId());
        initialParams.put('apiBaseURL', URL.getSalesforceBaseURL().toExternalForm());
        initialParams.put('basePathURL', getBasePath());
        return initialParams;
    }


    public class NoObjectSpecifiedException extends Exception {}
    public class ObjectDoesNotExistException extends Exception {}

    @RemoteAction
    global static Map<String, Object> getObjectDescribe(String objectName) {
        if (String.isBlank(objectName)) {
            throw new NoObjectSpecifiedException('No object type specified for describe.');
        }

        Map<String, Object> response = new Map<String, Object>();

        //Find matching SObjectType for the object name passed in. If one is not found, throw an error
        Schema.SObjectType matchingSObjectType = Schema.getGlobalDescribe().get(objectName);
        if (matchingSObjectType == null) {
            throw new ObjectDoesNotExistException('Object: "' + objectName + '" not found in this org.');
        }

        //Get the describe info for the current object and add this info to the response container
        Schema.DescribeSObjectResult sobjectDescribe = matchingSObjectType.getDescribe();
        response.put('label', sobjectDescribe.getLabel());
        response.put('fullName', sobjectDescribe.getName());
        response.put('localName', sobjectDescribe.getLocalName());

        //Get the describe info for each field on this object and add this info to the response container
        Map<String, Map<String, Object>> fieldResults = new Map<String, Map<String, Object>>();
        Map<String, String> fieldRelNames = new Map<String, String>();
        List<String> fieldNameArray = new List<String>();
        Map<String, Schema.SObjectField> allFields = sobjectDescribe.fields.getMap();
        for (String fieldName : allFields.keySet()) {
            Schema.DescribeFieldResult currentFieldDescribe = allFields.get(fieldName).getDescribe();
            Map<String, Object> fieldResult = new Map<String, Object>();
            String fieldDisplayType = currentFieldDescribe.getType().name();
            fieldResult.put('label', currentFieldDescribe.getLabel());
            fieldResult.put('name', currentFieldDescribe.getName());
            fieldNameArray.add(currentFieldDescribe.getName());
            fieldResult.put('localName', currentFieldDescribe.getLocalName());
            fieldResult.put('displayType', fieldDisplayType);
            fieldResult.put('relName', currentFieldDescribe.getRelationshipName());
            if (String.isNotBlank((String)fieldResult.get('relName'))) {
                fieldRelNames.put((String)fieldResult.get('relName'), (String)fieldResult.get('name'));
            }
            fieldResult.put('relOrder', currentFieldDescribe.getRelationshipOrder());
            fieldResult.put('isCustom', currentFieldDescribe.isCustom());
            fieldResult.put('length', currentFieldDescribe.getLength());
            fieldResult.put('required', currentFieldDescribe.isCreateable() &&
                            !currentFieldDescribe.isNillable() &&
                            !currentFieldDescribe.isDefaultedOnCreate() &&
                            !fieldDisplayType.equalsIgnoreCase('boolean'));
            fieldResult.put('updateable', currentFieldDescribe.isUpdateable());
            if (fieldDisplayType.equalsIgnoreCase('reference')) {
                List<Schema.SObjectType> referenceTo = currentFieldDescribe.getReferenceTo();
                if (referenceTo != null && referenceTo.size() > 0) {
                    fieldResult.put('referenceTo', referenceTo[0].getDescribe().getName());
                }
            }
            Map<String, String> picklistValues = new Map<String, String>();
            List<String> picklistValuesInOrder = new List<String>();
            picklistValues.put('null', '--None--');
            picklistValuesInOrder.add('null');
            for (Schema.PicklistEntry picklistEntry : currentFieldDescribe.getPicklistValues()) {
                String picklistValue = picklistEntry.getValue();
                String picklistLabel = picklistEntry.getLabel();
                picklistValues.put(picklistValue, picklistLabel);
                picklistValuesInOrder.add(picklistValue);
            }
            if (fieldDisplayType.equalsIgnoreCase('picklist') || fieldDisplayType.equalsIgnoreCase('multipicklist')) {
                fieldResult.put('picklistValues', picklistValues);
                fieldResult.put('picklistValuesInOrder', picklistValuesInOrder);
            }
            fieldResults.put(String.valueOf(fieldResult.get('name')).toLowerCase(), fieldResult);
        }
        response.put('fields', fieldResults);
        response.put('fieldRelNames', fieldRelNames);
        response.put('fieldNames', fieldNameArray);
        response.put('error', false);

        return response;
    }

    @RemoteAction
    global static List<SObject> query(String objectName, List<String> selectFields, String whereClause, String orderBy, Integer limitAmt, Integer offset) {
        if (limitAmt == -1) {
            limitAmt = 50000;
        }

        Boolean containsIDField = false;
        for (String field : selectFields) {
            if (field.equalsIgnoreCase('ID')) {
                containsIDField = true;
                break;
            }
        }

        if (!containsIDField) {
            selectFields.add('id');
        }

        String query = 'SELECT ';
        for (String field : selectFields) {
            query += field + ',';
        }
        query = query.substring(0, query.lastIndexOf(',')) + ' FROM ' + objectName;
        if (String.isNotBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        if (String.isNotBlank(orderBy)) {
            query += ' ORDER BY ' + orderBy;
        }
        query += ' LIMIT ' + limitAmt;
        if (offset > -1) {
            query += ' OFFSET ' + offset;
        }

        List<SObject> records = Database.query(query);
        return records;
    }

    public class NoMatchingSObjectException extends Exception {}
    public class InvalidFieldNameException extends Exception {}
    public class InvalidFieldValueException extends Exception {}
    public class InsertRecordException extends Exception {}
    public class UpdateRecordException extends Exception {}

    public static SObject fillSObject(String objectName, Map<String, Map<String, Object>> objectData, Set<String> fieldNames) {
        SObjectType newSObjectType = Schema.getGlobalDescribe().get(objectName);
        if (newSObjectType != null) {
            SObject newRecord = newSObjectType.newSObject();
            for (String fieldName : objectData.keySet()) {
                fieldNames.add(fieldName.toLowerCase());
                Map<String, Object> fieldData = objectData.get(fieldName);
                try {
                    if (fieldData.get('type') == 'date') {
                        DateTime asDateTime = DateTime.newInstance(((Decimal)fieldData.get('value')).longValue());
                        newRecord.put(fieldName, asDateTime.dateGMT());
                    } else if (fieldData.get('type') == 'datetime') {
                        newRecord.put(fieldName, DateTime.newInstance(((Decimal)fieldData.get('value')).longValue()));
                    } else if (fieldData.get('type') == 'lookup') {
                        newRecord.put(fieldName, (String)fieldData.get('value'));
                    } else {
                        newRecord.put(fieldName, fieldData.get('value'));
                    }
                } catch (TypeException e) {
                    throw new InvalidFieldValueException('Invalid value for field: "' + fieldName + '", "' + fieldData.get('value') + '". Original Error: "' + e.getMessage() + '". Original Stack Trace: "' + e.getStackTraceString() + '"');
                } catch (Exception e) {
                    throw new InvalidFieldNameException('Invalid field: "' + fieldName + '" on object: "' + objectName + '". Original Error: "' + e.getMessage() + '". Original Stack Trace: "' + e.getStackTraceString() + '"');
                }
            }
            return newRecord;
        } else {
            throw new NoMatchingSObjectException('No SObject by Name: "' + objectName + '"');
        }
    }

    private static Map<String, Object> createRequeryResponse(SObject newRecord, Set<String> fieldNames) {
        Map<String, Object> response = new Map<String, Object>();
        for (String fieldName : fieldNames) {
            Object fieldValue;
            if (fieldName.indexOf('.') > -1) {
                fieldValue = RKPageController.getRelatedFieldValueFromSObject(newRecord, fieldName);
            } else {
                fieldValue = newRecord.get(fieldName);
            }

            if (fieldValue instanceof Date) {
                Date asDate = ((Date)fieldValue);
                DateTime asDateTime = DateTime.newInstance(asDate.year(), asDate.month(), asDate.day());
                response.put(fieldName, asDateTime.getTime());
            } else if (fieldValue instanceof DateTime) {
                response.put(fieldName, ((DateTime)fieldValue).getTime());
            } else {
                response.put(fieldName, fieldValue);
            }
        }
        return response;
    }

    @RemoteAction
    global static Map<String, Object> insertRecord(String objectName, Map<String, Map<String, Object>> objectData, List<String> returnedFields) {
        Set<String> fieldNames = new Set<String>(returnedFields);
        if (!fieldNames.containsAll(new List<String> {'ID', 'iD', 'Id', 'id'})) {
            fieldNames.add('id');
        }

        SObject newRecord = fillSObject(objectName, objectData, fieldNames);

        try {
            insert newRecord;
        } catch (Exception e) {
            throw new InsertRecordException('Failed to insert record. Original Error: "' + e.getMessage() + '". Original Stack Trace: "' + e.getStackTraceString() + '". SObject JSON: \\n' + JSON.serialize(newRecord));
        }

        List<SObject> reQueried = RKPageController.query(objectName, new List<String>(fieldNames), 'ID = \'' + newRecord.ID + '\'', 'ID ASC', 1, -1);
        newRecord = reQueried[0];

        return createRequeryResponse(newRecord, fieldNames);
    }

    @RemoteAction
    global static Map<String, Object> updateRecord(String objectName, Map<String, Map<String, Object>> objectData, List<String> returnedFields) {
        Set<String> fieldNames = new Set<String>(returnedFields);
        if (!fieldNames.containsAll(new List<String> {'ID', 'iD', 'Id', 'id'})) {
            fieldNames.add('id');
        }

        SObject newRecord = fillSObject(objectName, objectData, fieldNames);

        try {
            update newRecord;
        } catch (Exception e) {
            throw new UpdateRecordException('Failed to update record. Original Error: "' + e.getMessage() + '". Original Stack Trace: "' + e.getStackTraceString() + '". SObject JSON: \\n' + JSON.serialize(newRecord));
        }

        List<SObject> reQueried = RKPageController.query(objectName, new List<String>(fieldNames), 'ID = \'' + newRecord.ID + '\'', 'ID ASC', 1, -1);

        return createRequeryResponse(reQueried[0], fieldNames);
    }

    public static Object getRelatedFieldValueFromSObject(SObject record, String accessor) {
        List<String> relatedAccessors = accessor.split('\\.');
        SObject relatedObject = record;
        Integer fieldCounter = 0;
        while (fieldCounter < relatedAccessors.size() - 1 && relatedObject != null) {
            relatedObject = relatedObject.getSObject(relatedAccessors[fieldCounter]);
            fieldCounter++;
        }
        if (relatedObject != null) {
            return relatedObject.get(relatedAccessors[relatedAccessors.size() - 1]);
        }
        return null;
    }


    /*==========================================================
                        WHERE CLAUSE CONSTRUCTS
    ==========================================================*/
    public class WhereClause {
        WhereToken topLevelToken;

        public WhereClause() {}

        public WhereClause(WhereToken topLevelToken) {
            this.topLevelToken = topLevelToken;
        }

        public WhereClause setTopLevelToken(WhereToken topLevelToken) {
            this.topLevelToken = topLevelToken;
            return this;
        }

        public String resolveToString() {
            return topLevelToken.resolveToString();
        }
    }

    public abstract class WhereToken {
        public abstract String resolveToString();
    }

    public class NullToken extends WhereToken {
        String nullvalue = 'NULL';

        public override String resolveToString() {
            return '';
        }
    }

    public class FieldBlock extends WhereToken {
        String fieldName,
               comparisonOperator,
               value;

        public FieldBlock(String fieldName, String comparisonOperator, String value) {
            setFieldName(fieldName)
            .setComparisonOperator(comparisonOperator)
            .setValue(value);
        }

        public FieldBlock setFieldName(String fieldName) {
            this.fieldName = fieldName;
            return this;
        }

        public FieldBlock setComparisonOperator(String comparisonOperator) {
            this.comparisonOperator = comparisonOperator;
            return this;
        }

        public FieldBlock setValue(String value) {
            this.value = value;
            return this;
        }

        public override String resolveToString() {
            return fieldName + ' ' + comparisonOperator + ' ' + value;
        }
    }

    public abstract class ConditionBlock extends WhereToken {
        String conditionOperator;
        List<WhereToken> childTokens;

        public void init(List<WhereToken> childTokens) {
            if (childTokens == null) {
                this.childTokens = new List<WhereToken>();
            } else {
                this.childTokens = childTokens;
            }
        }

        public ConditionBlock addChildToken(WhereToken childToken) {
            childTokens.add(childToken);
            return this;
        }

        public ConditionBlock addChildTokens(List<WhereToken> childTokens) {
            this.childTokens.addAll(childTokens);
            return this;
        }

        public override String resolveToString() {
            if (childTokens == null || childTokens.size() == 0) {
                return '';
            }

            String asString = '(';
            for (WhereToken childToken : childTokens) {
                asString += childToken.resolveToString() + ' ' + conditionOperator + ' ';
            }
            return asString.substring(0, asString.lastIndexOfIgnoreCase(' ' + conditionOperator)) + ')';
        }
    }

    public class AndCondition extends ConditionBlock {
        public AndCondition() {this(null);}

        public AndCondition(List<WhereToken> childTokens) {
            this.conditionOperator = 'AND';
            super.init(childTokens);
        }
    }

    public class OrCondition extends ConditionBlock {
        public OrCondition() {this(null);}

        public OrCondition(List<WhereToken> childTokens) {
            this.conditionOperator = 'OR';
            super.init(childTokens);
        }
    }
}