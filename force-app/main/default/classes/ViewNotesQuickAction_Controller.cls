public class ViewNotesQuickAction_Controller {

    public List<Fields> fieldsLst {get; set;}
    public String objLabel {get; set;}
    public String recId {get; set;}
    public String objectNumber {get; set;}
    public String noteAPI {get; set;}
    public Boolean showNotes {get; set;}
    public String linkTarget {get; set;}

    @AuraEnabled
    public static ViewNotesWrapper getViewNotes(Id recordId) {
        String mainObj = recordId.getSObjectType().getDescribe().getName();
        ViewNotesWrapper retResult = new ViewNotesWrapper(mainObj);
        return retResult;
    }


    public class ViewNotesWrapper {
        private ViewNotes__c viewNotes;
        @AuraEnabled
        public String mainObject;
        @AuraEnabled
        public String childObject;
        @AuraEnabled
        public String noteCategoryFld;
        @AuraEnabled
        public Object noteCategories;
        @AuraEnabled
        public String noteCreatedDate;
        @AuraEnabled
        public String parentFieldset;

        public ViewNotesWrapper(String mainObj) {
            Map<String, ViewNotes__c> customSettingMap = new Map<String, ViewNotes__c>();
            for (String v : ViewNotes__c.getall().keySet()) {
                customSettingMap.put(v.toLowerCase(), ViewNotes__c.getValues(v));
            }
            viewNotes = customSettingMap.get(mainObj.toLowerCase());
            if (viewNotes == null) auraErr('The Custom Setting Does not Exist.');
            mainObject = viewNotes.Name;
            getNoteCategories();
        }
        public void getNoteCategories() {
            List<FieldWrapper> allOpts = new List<FieldWrapper>();
            Schema.SObjectType SObjectTypeObjMain = Schema.getGlobalDescribe().get(mainObject);
            Schema.DescribeSObjectResult DescribeSObjectResultMain = SObjectTypeObjMain.getDescribe();
            sObject sobj = Schema.getGlobalDescribe().get(viewNotes.Note_Object_API__c).newSObject();
            Schema.sObjectType objType = sobj.getSObjectType();
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            childObject = objDescribe.getName();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            String notesCatField = viewNotes.Note_Categories_API__c;
            if (fieldMap.get(notesCatField.toLowerCase()) != null) {
                List<Schema.PicklistEntry> values = fieldMap.get(notesCatField.toLowerCase()).getDescribe().getPickListValues();
                for (Schema.PicklistEntry a : values) {
                    allOpts.add(new FieldWrapper(a.getValue(), a.getLabel()));
                }
                noteCategories = allOpts;
                noteCategoryFld = fieldMap.get(notesCatField.toLowerCase()).getDescribe().getName();
            } else auraErr(notesCatField + 'does not exist in ' + viewNotes.Note_Object_API__c);
            String createdDate = viewNotes.Note_Created_Date_API__c;
            if (fieldMap.get(createdDate.toLowerCase()) != null) {
                noteCreatedDate = fieldMap.get(createdDate.toLowerCase()).getDescribe().getName();
            } else auraErr(createdDate + 'does not exist in ' + viewNotes.Note_Object_API__c);
            Schema.FieldSet fieldSetObj = DescribeSObjectResultMain.FieldSets.getMap().get(viewNotes.Parent_Fieldset__c);
            if (fieldSetObj == null) {
                auraErr(viewNotes.Parent_Fieldset__c + 'does not exist in ' + mainObject);
            }
            parentFieldset = viewNotes.Parent_Fieldset__c;
        }
        public Integer[] parseWindowSize(String windowSize) {
            Integer[] result = new Integer[] {};
            if (windowSize != null && windowSize.length() > 0) {
                String[] tokens = windowSize.split(',');
                if (tokens.size() == 2) {
                    result.add(Integer.valueOf(tokens[0].trim()));
                    result.add(Integer.valueOf(tokens[1].trim()));
                    return result;
                }
            }
            // if we got here then a parse exception occurred:
            System.assert(false);
            return null;
        }
    }
    class FieldWrapper {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        public FieldWrapper(String value, String label) {
            this.label = label;
            this.value = value;
        }
    }
    static void auraErr(String msg) {
        throw new AuraHandledException('[View Notes] ' + msg);
    }
    public SObject getObjectDetails() {
        SObject sObj ;
        String queryString;
        fieldsLst = new List<Fields>();
        List<String> fieldsetFlds = new List<String>();
        Map<String, String> fieldsMap = new Map<String, String>();
        String mainObject = ApexPages.currentPage().getParameters().get('mainObject');
        recId = ApexPages.currentPage().getParameters().get('recId');
        if (recId == null)auraErr('Record Id Cannot be null. Something went wrong.');
        ViewNotes__c viewNotes = ViewNotes__c.getValues(mainObject);
        if (mainObject != '') {
            queryString = 'SELECT ';
            SObjectType objType = Schema.getGlobalDescribe().get(viewNotes.Name);
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            objLabel = objDescribe.getLabel();

            map<String, Schema.FieldSet> fieldSetMap = objDescribe.fieldsets.getMap();
            Schema.FieldSet fs = fieldSetMap.get(viewNotes.Parent_Fieldset__c);
            for ( Schema.FieldSetMember fld : fs.getFields() ) {
                fieldsLst.add(new Fields(fld.getLabel(), fld.getFieldPath(), String.valueOf(fld.getType()).toLowerCase()));
                fieldsetFlds.add(fld.getFieldPath());

            }
            if (!fieldsetFlds.contains('Name')) {
                fieldsetFlds.add('Name');
            }
            if (!fieldsetFlds.contains('Id')) {
                fieldsetFlds.add('Id');
            }
            queryString += String.join(fieldsetFlds, ',') + ' FROM ' + viewNotes.Name + ' WHERE Id =: recId';
            sObj = Database.query(queryString);
            objectNumber = String.valueOf(sObj.get('Name'));
        }
        return sObj;
    }

    public class Fields {
        public String Label {get; set;}
        public String API {get; set;}
        public String fieldType {get; set;}
        public Fields(String Label, String API, String fieldType) {
            this.Label = Label;
            this.API = API;
            this.fieldType = fieldType;
        }
    }

    public String getDomainURL() {
        return 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
    }

    public sObject[] getDownloadActivities() {
        String recId = ApexPages.currentPage().getParameters().get('recId');
        String mainObject = ApexPages.currentPage().getParameters().get('mainObject');
        String orderBy = ApexPages.currentPage().getParameters().get('orderBy');
        String dateRange = ApexPages.currentPage().getParameters().get('dateRange');
        String category = ApexPages.currentPage().getParameters().get('category');
        String count = ApexPages.currentPage().getParameters().get('limitNotes');
        String target = ApexPages.currentPage().getParameters().get('target');
        linkTarget = (target != '' && target != null) ? target : '_blank';
        List<SObject> queryResLst = new List<SObject>();
        ViewNotes__c downloadConfig = ViewNotes__c.getValues(mainObject);
        String objAPI = downloadConfig.Note_Object_API__c;
        SObjectType objType = Schema.getGlobalDescribe().get(objAPI);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        noteAPI = objDescribe.getLabelPlural();
        List<String> catLst = new List<String>();

        if (String.isNotBlank(category)) {
            catLst = category.split(',');
        }
        String adjQuery = 'SELECT Id,Name,CreatedBy.Firstname,Createdby.LastName,CreatedBy.Name,Note_Category__c, CreatedDate, Note_Text_Rich__c,Note_Create_Date_Time__c FROM '
                          + objAPI + ' WHERE ' + downloadConfig.Name + ' = :recId AND IsDeleted = FALSE ' +
                          (category != null ? ' AND Note_Category__c IN :catLst ' : '') +
                          (dateRange != ''  && dateRange != null ? ' AND ' + downloadConfig.Note_Created_Date_API__c + ' = ' + dateRange + '' : '') +
                          (orderBy == 'asc' ? ' Order By ' + downloadConfig.Note_Created_Date_API__c + ' asc ' : ' Order By ' + downloadConfig.Note_Created_Date_API__c + ' desc ') +
                          (count != '' && count != null ? ' LIMIT ' + count + '' : '' ) +
                          ' ALL ROWS';
        queryResLst = Database.query(adjQuery);
        if (queryResLst.size() > 0 )showNotes = false;
        else showNotes = true;
        return queryResLst;
    }
}