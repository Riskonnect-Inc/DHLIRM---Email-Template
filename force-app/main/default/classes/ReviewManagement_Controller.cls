public with sharing class ReviewManagement_Controller {

    @AuraEnabled
    public static ReviewRecordsWrapper getReviewMgmtData(String compData) {
        RequestWrapper dataMap = (RequestWrapper) JSON.deserialize(compData, RequestWrapper.class);
        try {
            Schema.DescribeSObjectResult describeSObjectResultObj1 = Schema.getGlobalDescribe().get(dataMap.object1API).getDescribe();
            Schema.DescribeSObjectResult describeSObjectResultObj2 = Schema.getGlobalDescribe().get(dataMap.object2API).getDescribe();
            Schema.DescribeSObjectResult describeSObjectResultObj3 = Schema.getGlobalDescribe().get(dataMap.object3API).getDescribe();
            List<ObjectDescribeWrapper> filterLst = new List<ObjectDescribeWrapper>();
            filterLst.add(new ObjectDescribeWrapper(describeSObjectResultObj1.getLabelPlural(), dataMap.object1API));
            filterLst.add(new ObjectDescribeWrapper(describeSObjectResultObj2.getLabelPlural(), dataMap.object2API));
            filterLst.add(new ObjectDescribeWrapper(describeSObjectResultObj3.getLabelPlural(), dataMap.object3API));

            Map<String, Schema.SObjectField> objectFields1 = describeSObjectResultObj1.fields.getMap();
            Map<String, Schema.SObjectField> objectFields2 = describeSObjectResultObj2.fields.getMap();
            Map<String, Schema.SObjectField> objectFields3 = describeSObjectResultObj3.fields.getMap();

            Map<String, List<String>> newColumns = (Map<String, List<String>>) JSON.deserialize(dataMap.newColumns, Map<String, List<String>>.class);
            Map<String, List<String>> progColumns = (Map<String, List<String>>) JSON.deserialize(dataMap.progressColumns, Map<String, List<String>>.class);

            List<FieldDescribeWrapper> newFieldsetWrapper = new List<FieldDescribeWrapper>();
            List<FieldDescribeWrapper> progFieldsetWrapper = new List<FieldDescribeWrapper>();

            Map<String, String> newObj1ColMap = new Map<String, String>();
            Map<String, String> newObj2ColMap = new Map<String, String>();
            Map<String, String> newObj3ColMap = new Map<String, String>();

            Map<String, String> progObj1ColMap = new Map<String, String>();
            Map<String, String> progObj2ColMap = new Map<String, String>();
            Map<String, String> progObj3ColMap = new Map<String, String>();

            if (objectFields1.get(dataMap.statusFld1.toLowerCase()) == null || objectFields2.get(dataMap.statusFld2.toLowerCase()) == null ||
                    objectFields3.get(dataMap.statusFld3.toLowerCase()) == null) {
                throw new MyCustomException('Invalid Status field.');
            }
            Integer i = 1;
            for (String n : newColumns.keySet()) {
                List<String> colLst = newColumns.get(n);
                if (colLst.size() == 3) {
                    String label = 'Label_' + i;
                    String unqLnk = null;
                    Schema.SObjectField fldObj1, fldObj2, fldObj3;
                    if (colLst[0].contains('.')) {
                        fldObj1 = getSObjectField(colLst[0], objectFields1.get(getLookupField(colLst[0])));
                    } else {
                        fldObj1 = objectFields1.get(colLst[0].toLowerCase());
                    }
                    if (colLst[1].contains('.')) {
                        fldObj2 = getSObjectField(colLst[1], objectFields2.get(getLookupField(colLst[1])));
                    } else {
                        fldObj2 = objectFields2.get(colLst[1].toLowerCase());
                    }
                    if (colLst[2].contains('.')) {
                        fldObj3 = getSObjectField(colLst[2], objectFields3.get(getLookupField(colLst[2])));
                    } else {
                        fldObj3 = objectFields3.get(colLst[2].toLowerCase());
                    }
                    if (fldObj1 == null || fldObj2 == null || fldObj3 == null) {
                        throw new MyCustomException('Field is not found in  \'New\' tab of column ' + n + ' of object ' + (fldObj1 == null ? dataMap.object1API : fldObj2 == null ? dataMap.object2API : dataMap.object3API ));
                    }
                    String obj1DT = String.valueOf(fldObj1.getDescribe().getType());
                    if (obj1DT.equals(String.valueOf(fldObj2.getDescribe().getType())) && obj1DT.equals(String.valueOf(fldObj3.getDescribe().getType()))) {
                        newObj1ColMap.put(colLst[0], label);
                        newObj2ColMap.put(colLst[1], label);
                        newObj3ColMap.put(colLst[2], label);

                        String fieldType = String.valueOf(fldObj1.getDescribe().getType());

                        if (fieldType == 'REFERENCE') {
                            unqLnk = createUniquelinkName(colLst[0]);
                            newObj1ColMap.put(getReferenceName(colLst[0]), unqLnk);
                            newObj2ColMap.put(getReferenceName(colLst[1]), unqLnk);
                            newObj3ColMap.put(getReferenceName(colLst[2]), unqLnk);
                        } else if (colLst[0].equalsIgnoreCase('name') && colLst[1].equalsIgnoreCase('name') && colLst[2].equalsIgnoreCase('name')) {
                            unqLnk = createUniquelinkName(label);
                            fieldType = 'url';
                        }
                        newFieldsetWrapper.add(new FieldDescribeWrapper(n, label, fieldType, unqLnk));

                    } else {
                        throw new MyCustomException('Data Types of fields must match of column ' + n + ' in \'New\' tab.');
                    }
                    i++;
                } else {
                    throw new MyCustomException('Invalid column values in \'New\' tab. Each column must have 3 fields.');
                }
            }
            for (String n : progColumns.keySet()) {
                List<String> colLst = progColumns.get(n);
                if (colLst.size() == 3) {
                    String label = 'Label_' + i;
                    String unqLnk = null;
                    Schema.SObjectField fldObj1, fldObj2, fldObj3;
                    if (colLst[0].contains('.')) {
                        fldObj1 = getSObjectField(colLst[0], objectFields1.get(getLookupField(colLst[0])));
                    } else {
                        fldObj1 = objectFields1.get(colLst[0].toLowerCase());
                    }
                    if (colLst[1].contains('.')) {
                        fldObj2 = getSObjectField(colLst[1], objectFields2.get(getLookupField(colLst[1])));
                    } else {
                        fldObj2 = objectFields2.get(colLst[1].toLowerCase());
                    }
                    if (colLst[2].contains('.')) {
                        fldObj3 = getSObjectField(colLst[2], objectFields3.get(getLookupField(colLst[2])));
                    } else {
                        fldObj3 = objectFields3.get(colLst[2].toLowerCase());
                    }
                    if (fldObj1 == null || fldObj2 == null || fldObj3 == null) {
                        throw new MyCustomException('Field is not found in \'In Progress\' tab column ' + n + ' of object ' + (fldObj1 == null ? dataMap.object1API : fldObj2 == null ? dataMap.object2API : dataMap.object3API ));
                    }
                    String obj1DT = String.valueOf(fldObj1.getDescribe().getType());
                    if (obj1DT.equals(String.valueOf(fldObj2.getDescribe().getType())) && obj1DT.equals(String.valueOf(fldObj3.getDescribe().getType()))) {
                        progObj1ColMap.put(colLst[0], label);
                        progObj2ColMap.put(colLst[1], label);
                        progObj3ColMap.put(colLst[2], label);

                        String fieldType = String.valueOf(fldObj1.getDescribe().getType());

                        if (fieldType == 'REFERENCE') {
                            unqLnk = createUniquelinkName(colLst[0]);
                            progObj1ColMap.put(getReferenceName(colLst[0]), unqLnk);
                            progObj2ColMap.put(getReferenceName(colLst[1]), unqLnk);
                            progObj3ColMap.put(getReferenceName(colLst[2]), unqLnk);
                        } else if (colLst[0].equalsIgnoreCase('name') && colLst[1].equalsIgnoreCase('name') && colLst[2].equalsIgnoreCase('name')) {
                            unqLnk = createUniquelinkName(label);
                            fieldType = 'url';
                        }
                        progFieldsetWrapper.add(new FieldDescribeWrapper(n, label, fieldType, unqLnk));

                    } else {
                        throw new MyCustomException('Data Types of fields must match of column ' + n + ' of in \'In Progress\' tab');
                    }
                    i++;
                } else {
                    throw new MyCustomException('Invalid column values in \'In Progress\' tab. Each column must have 3 fields.');
                }
            }
            Map<String, List<Object>> newRecordsData = new Map<String, List<Object>>();
            Map<String, List<Object>> progRecordsData = new Map<String, List<Object>>();

            newRecordsData.put(dataMap.object1API, queryRecordData(dataMap.object1API, dataMap.statusFld1, 'New', newObj1ColMap, newObj1ColMap.containsKey('Id')));
            newRecordsData.put(dataMap.object2API, queryRecordData(dataMap.object2API, dataMap.statusFld2, 'New', newObj2ColMap, newObj2ColMap.containsKey('Id')));
            newRecordsData.put(dataMap.object3API, queryRecordData(dataMap.object3API, dataMap.statusFld3, 'New', newObj3ColMap, newObj3ColMap.containsKey('Id')));


            progRecordsData.put(dataMap.object1API, queryRecordData(dataMap.object1API, dataMap.statusFld1, 'In Progress', progObj1ColMap, progObj1ColMap.containsKey('Id')));
            progRecordsData.put(dataMap.object2API, queryRecordData(dataMap.object2API, dataMap.statusFld2, 'In Progress', progObj2ColMap, progObj2ColMap.containsKey('Id')));
            progRecordsData.put(dataMap.object3API, queryRecordData(dataMap.object3API, dataMap.statusFld3, 'In Progress', progObj3ColMap, progObj3ColMap.containsKey('Id')));


            ReviewRecordsWrapper retResult = new ReviewRecordsWrapper();
            retResult.newColumnsData = newFieldsetWrapper;
            retResult.progColumnsData = progFieldsetWrapper;
            retResult.newRecordsData = newRecordsData;
            retResult.progRecordsData = progRecordsData;
            retResult.newObjFilters =  filterLst;
            retResult.progObjFilters =  filterLst;
            return retResult;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }

    public static List<Object> queryRecordData(String objAPI, String statusFld, String comparator, Map<String, String> fieldsetMap, Boolean containsId) {
        Id currentUserId = userInfo.getUserId();
        List<Object> returnLst = new List<Object>();
        List<String> fieldsLst = new List<String>(fieldsetMap.keyset());
        String query = 'SELECT ' + (!containsId ? 'Id,' : '') + String.join(fieldsLst, ',') + ' FROM ' + objAPI +
                       ' WHERE ' + statusFld + '=:comparator AND Assigned_Reviewer__c =:currentUserId Order By CreatedDate desc ';
        List<sObject> recordLst = Database.query(query);
        for (sObject record : recordLst) {
            Map<String, Object> returnMap = new Map<String, Object>();
            for (String fld : fieldsetMap.keyset()) {
                if (fld.contains('.')) {
                    List<String> fldsLst = fld.split('\\.');
                    String val;
                    sObject sub = record.getSObject(fldsLst[0]);
                    for (Integer i = 1 ; sub != null && i < fldsLst.size(); i++) {
                        if (i == fldsLst.size() - 1) {
                            val = (String)sub.get(fldsLst[i]);
                        } else sub = sub.getSObject(fldsLst[i]);
                    }
                    returnMap.put(fieldsetMap.get(fld), val);
                } else if (fld.equalsIgnoreCase('name')) {
                    returnMap.put(fieldsetMap.get(fld), 'lightning/r/' + (String)record.get('Id') + '/view');
                    returnMap.put(fieldsetMap.get(fld) + '__LinkLabel', (String)record.get(fld));
                } else {
                    Object fieldValue = record.get(fld);
                    if (fieldValue instanceof Date) {
                        returnMap.put(fieldsetMap.get(fld), ((Date)fieldValue).format());
                    } else if (fieldValue instanceof DateTime) {
                        returnMap.put(fieldsetMap.get(fld), ((DateTime)fieldValue).date().format());
                    } else {
                        returnMap.put(fieldsetMap.get(fld), String.valueOf(fieldValue));
                    }
                }
            }
            if (!returnMap.containsKey('Id')) {
                returnMap.put('Id', String.valueOf(record.get('Id')));
            }
            returnLst.add(returnMap);
        }
        return returnLst;

    }
    private static String getReferenceName(String refApi) {
        if (refApi.endsWithIgnoreCase('__c')) {
            return refApi.removeEndIgnoreCase('__c') + '__r.Name';
        } else if (refApi.endsWithIgnoreCase('Id')) {
            return refApi.removeEndIgnoreCase('Id') + '.Name';
        } else return null;

    }
    private static String createUniquelinkName(String refApi) {
        if (refApi.endsWithIgnoreCase('__c')) {
            return refApi.removeEndIgnoreCase('__c') + '__LinkLabel';
        } else  return refApi + '__LinkLabel';
    }
    private static String getLookupField(String relField) {
        List<String> fldsLst = relField.split('\\.');
        String field;
        if (fldsLst[0].endsWithIgnoreCase('__r')) {
            field = fldsLst[0].replace('__r', '__c');
        } else {
            field = fldsLst[0] + 'Id';
        }
        return field.toLowerCase();
    }
    //Only 2 Arbitrary Depth is allowed
    private static Schema.SObjectField getSObjectField(String relField, Schema.SObjectField mainSobj) {
        List<String> fldsLst = relField.split('\\.');
        if (mainSobj == null ) throw new MyCustomException('The field ' + fldsLst[0] + ' does not exist. ');
        if (fldsLst.size() > 2) throw new MyCustomException('The allowed arbitrary depth is 2.');
        List<Schema.SObjectType> sObjChildObj = mainSobj.getDescribe().getReferenceTo();

        return sObjChildObj[0].getDescribe().fields.getMap().get(fldsLst[1].toLowerCase());
    }
    public class FieldDescribeWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String fieldName {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public Boolean sortable {get; set;}
        @AuraEnabled
        public Integer initialWidth {get; set;}
        @AuraEnabled
        public Map<String, Object> typeAttributes {get; set;}

        public FieldDescribeWrapper(String label, String fieldName, String type, String linkName) {
            Map<String, String> dataTypeMap = new Map<String, String> {
                'string' => 'text',
                'date' => 'date',
                'datetime' => 'date',
                'reference' => 'url'
            };

            this.label = label;
            this.fieldName = fieldName;
            this.type = dataTypeMap.get(type.toLowerCase()) != null ?  dataTypeMap.get(type.toLowerCase()) : type;
            this.sortable = true;
            if (this.type == 'url') {
                typeAttributes = new Map<String, Object>();
                typeAttributes.put('label', new Map<String, String> {'fieldName' => linkName});
                typeAttributes.put('target', '_blank');
            } else if (this.type == 'date') {
                this.type = 'text';
            } else if (this.type == 'datetime') {
                this.type = 'text';
            }

            initialWidth = 250;
        }
    }

    public class ObjectDescribeWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String fieldPath {get; set;}

        public ObjectDescribeWrapper(String label, String fieldPath) {
            this.label = label;
            this.fieldPath = fieldPath;
        }
    }
    public class RequestWrapper {
        public String object1API {get; set;}
        public String object2API {get; set;}
        public String object3API {get; set;}
        public String statusFld1 {get; set;}
        public String statusFld2 {get; set;}
        public String statusFld3 {get; set;}
        public String newColumns {get; set;}
        public String progressColumns {get; set;}
    }
    public class ReviewRecordsWrapper {
        @AuraEnabled
        public List<FieldDescribeWrapper> newColumnsData {get; set;}
        @AuraEnabled
        public List<FieldDescribeWrapper> progColumnsData {get; set;}
        @AuraEnabled
        public Map<String, List<Object>> newRecordsData {get; set;}
        @AuraEnabled
        public Map<String, List<Object>> progRecordsData {get; set;}
        @AuraEnabled
        public List<ObjectDescribeWrapper> newObjFilters {get; set;}
        @AuraEnabled
        public List<ObjectDescribeWrapper> progObjFilters {get; set;}
    }
    public class MyCustomException extends Exception {}
}