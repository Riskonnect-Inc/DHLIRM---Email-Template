public class Notes_Controller {
    
    @AuraEnabled
    public static List<AdjusterNotesWrapper> getAdjusterRecords(String compData){
        Map<String, String> dataMap = (Map<String,String>) JSON.deserialize(compData, Map<String,String>.class);
        String recordId = dataMap.get('recordId');
        String category = dataMap.get('category') ;
        String source =dataMap.get('source');
        List<String> fieldNames = new List<String>();
        Date lastSixthMonth ;
        if(dataMap.get('timeRange') == 'LAST_N_MONTHS:6'){
            lastSixthMonth =Date.today().addMonths(-6);
            dataMap.put('timeRange','>= :lastSixthMonth');
        }
        else dataMap.put('timeRange','='+dataMap.get('timeRange'));
        for(String fld :Schema.getGlobalDescribe().get(dataMap.get('obj')).getDescribe().fields.getMap().keySet() ){
            if(fld.endsWith('__c'))fieldNames.add(fld.toLowerCase());
        }
        List<AdjusterNotesWrapper> adjNotesLst = new List<AdjusterNotesWrapper>();
        String query =' SELECT id,name,createddate,'+string.join(fieldNames, ',') +
            ' FROM '+dataMap.get('obj')  +
            ' WHERE '+dataMap.get('childName')+' = :recordId '+ (dataMap.get('timeRange') != '=ALL_TIME' ? 'AND CreatedDate'+dataMap.get('timeRange')  :'')+
              (category != 'ALL_CAT' ?' AND '+dataMap.get('catField')+' =:category ' :'')+
              (source != 'ALL' ? ' AND '+dataMap.get('sourceField')+' = :source ':'')+
            ' Order By Createddate desc ';
        List<sObject> resValue = Database.query(query);
        for(sObject adj :resValue){
            adjNotesLst.add(new AdjusterNotesWrapper(adj,dataMap));
        }
        return adjNotesLst;
    }

    // MDU: new method to load notes picklist options (category, source) and record types all at once:
    @AuraEnabled
    public static MetaResult getMeta(String notesTypeAPI, String parentId, String parentLookupAPI, String[] picklistFieldAPIs) {
        MetaResult res = new MetaResult();
        Schema.sObjectType notesType = Schema.getGlobalDescribe().get(notesTypeAPI);
        if (notesType == null) {
            err('Notes object type "' + notesTypeAPI + '" does not exist');
        }
        res.notesType = '' + notesType;
        res.notesLabel = notesType.getDescribe().getLabel();
        // resolve the lookup field from notes object to parent type:
        Id pId;
        try {
            pId = Id.valueOf(parentId);
        } catch (Exception ignore) {}
        if (pId == null) {
            err('Notes parent record Id "' + parentId + '" is invalid');
        }
        Schema.sObjectType parentType = pId.getSObjectType();
        Schema.sObjectField lkpTok;
        if (String.isNotBlank(parentLookupAPI)) {
            lkpTok = notesType.getDescribe().fields.getMap().get(parentLookupAPI);
            if (lkpTok == null) {
                err('Notes parent lookup field ' + notesType + '.' + parentLookupAPI + ' does not exist');
            }
        } else {
            for (Schema.sObjectField tok : notesType.getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult fDesc = tok.getDescribe();
                if (fDesc.getType() == Schema.DisplayType.Reference) {
                    Schema.sObjectType[] refTos = fDesc.getReferenceTo();
                    if (refTos.size() == 1 && refTos[0] == parentType) {
                        if (lkpTok != null) {
                            err('Notes parent lookup field was not specified, and could be resolved because multiple lookup fields on ' + 
                                notesType + ' point to ' + parentType + '(' + String.join(new List<String>{ '' + lkpTok, '' + tok }, ', ') + ')');
                        }
                        lkpTok = tok;
                    }
                }
            }
            if (lkpTok == null) {
                err('No lookup field exists from ' + notesType + ' to ' + parentType);
            }
        }
        Schema.DescribeFieldResult lkpDesc = lkpTok.getDescribe();
        if (lkpDesc.getType() != Schema.DisplayType.Reference) {
            err('The specified parent lookup field ' + notesType + '.' + lkpTok + ' is not a lookup type [' + lkpDesc.getType().name() + ']');
        }
        Schema.sObjectType[] lkpRefTos = lkpDesc.getReferenceTo();
        if (lkpRefTos.size() != 1 || lkpRefTos[0] != parentType) {
            err('The specified parent lookup field ' + notesType + '.' + lkpTok + ' points to ' + lkpRefTos[0] + ' when ' + parentType + ' was expected');
        }
        res.parentLookup = '' + lkpTok;
        RecordTypeInfo[] availableInfos = new RecordTypeInfo[]{};
        Map<Id, RecordType> recTypeMap = new Map<Id, RecordType>();
        for (RecordTypeInfo info : notesType.getDescribe().getRecordTypeInfos()) {
            if (info.isAvailable() && !info.isMaster()) {
                if (info.isDefaultRecordTypeMapping()) {
                    res.defaultRecordTypeIndex = availableInfos.size();
                }
                recTypeMap.put(info.getRecordTypeId(), null);
                availableInfos.add(info);
            }
        }
        if (recTypeMap.keySet().size() > 0) {
            recTypeMap = new Map<Id, RecordType>([ 
                SELECT Name, DeveloperName, Description 
                FROM RecordType 
                WHERE Id IN :recTypeMap.keySet() ]);
        }
        for (RecordTypeInfo info : availableInfos) {
            res.recordTypes.add(recTypeMap.get(info.getRecordTypeId()));
        }
        if (picklistFieldAPIs != null) {
            for (String pickerKey : picklistFieldAPIs) {
                if (String.isBlank(pickerKey)) {
                    continue;
                }
                Schema.sObjectField pickerTok = notesType.getDescribe().fields.getMap().get(pickerKey);
                if (pickerTok == null) {
                    err('Notes picklist field ' + notesTypeAPI + '.' + pickerKey + ' does not exist');
                }
                Schema.DescribeFieldResult pickerDesc = pickerTok.getDescribe();
                if (pickerDesc.getType() != Schema.DisplayType.Picklist) {
                    err('Notes field ' + notesTypeAPI + '.' + pickerTok + ' is not a picklist [' + pickerDesc.getType().name() + ']');
                }
                Picker picker = new Picker();
                picker.field = '' + pickerTok;
                res.picklistMap.put(pickerKey, picker);
                for (Schema.PicklistEntry opt : pickerDesc.getPickListValues()) {
                    picker.options.add(new Map<String, Object>{
                        'value' => opt.getValue(), 
                        'label' => opt.getLabel()
                    });
                }
            }
        }
        return res;
    }

    public class MetaResult {
        @AuraEnabled
        public String notesType;
        @AuraEnabled
        public String notesLabel;
        @AuraEnabled
        public String parentLookup;
        @AuraEnabled
        public RecordType[] recordTypes = new RecordType[]{};
        @AuraEnabled
        public Integer defaultRecordTypeIndex = 0;
        @AuraEnabled
        public Map<String, Picker> picklistMap = new Map<String, Picker>();
    }

    public class Picker {
        @AuraEnabled
        public String field;
        @AuraEnabled
        public Object[] options = new Object[]{};
    }

    static void err(String msg) {
        throw new AuraHandledException(msg);
    }
    
    @AuraEnabled
    public static object getSelectOptions(String fieldName, String obj) {
        Map<String,String> allOpts = new Map<String,String>();
        sObject sobj = Schema.getGlobalDescribe().get(obj).newSObject();
        Schema.sObjectType objType = sobj.getSObjectType();
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map< String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
        List< Schema.PicklistEntry > values = fieldMap.get(fieldName.toLowerCase()).getDescribe().getPickListValues();
        for (Schema.PicklistEntry a: values) {
            allOpts.put(a.getValue(), a.getLabel());
        }
        return allOpts;
    }

    @AuraEnabled
    public static String deleteRecordId(String idVal,String obj) {
        String name;
        String qry = 'SELECT Id,Name FROM '+obj +' WHERE Id=:idVal LIMIT 1';
        try{
            sobject adjNote = Database.query(qry);
            if(adjNote != null){
                name = (String)adjNote.get('Name');
                delete adjNote;
            }
            return name;
        }catch (Exception e) {
            throw new AuraHandledException('Something went wrong: '+ e.getMessage());    
        }
    }
    public class AdjusterNotesWrapper{
        @AuraEnabled
        public String id ;
        @AuraEnabled       
        public Object title;
        @AuraEnabled
        public Object body; 
        @AuraEnabled
        public String category;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String createdBy;
        @AuraEnabled
        public DateTime createdDate;
        public AdjusterNotesWrapper(sObject notes,Map<String,String> compDataMap){
            id =(String)notes.get('id');
            title=(compDataMap.get('titleAPI') != null && notes.get(compDataMap.get('titleAPI')) != null)?
                notes.get(compDataMap.get('titleAPI')) : null;
            body= (compDataMap.get('bodyAPI') != null && notes.get(compDataMap.get('bodyAPI')) != null)?
                notes.get(compDataMap.get('bodyAPI')) : null;
            category= (compDataMap.get('catField') != null && notes.get(compDataMap.get('catField')) != null)?
                (String)notes.get(compDataMap.get('catField')): null;
            type = (compDataMap.get('sourceField') != null && notes.get(compDataMap.get('sourceField')) != null)?
                (String)notes.get(compDataMap.get('sourceField')) : null;
            createdBy= (compDataMap.get('createdByAPI') != null && notes.get(compDataMap.get('createdByAPI')) != null)?
                (String)notes.get(compDataMap.get('createdByAPI')) : null;
            createdDate = (Datetime)notes.get('CreatedDate');
        }
    }
}