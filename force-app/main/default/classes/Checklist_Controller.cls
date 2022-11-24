public class Checklist_Controller {
    
    @AuraEnabled
    public static List<ChecklistWrapper> getRecord(Id recordId,String objName, String strFieldSetName){
        List<ChecklistWrapper> fieldsetData = new List<ChecklistWrapper>();
        List<String> fieldsLst = new List<String>();
        List<sObject> sObjData = new List<sObject>();
        objName = (objName != null && objName != '')?objName : (recordId != null) ? recordId.getSObjectType().getDescribe().getName() : null;
        Schema.SObjectType SObjectTypeObj =  Schema.getGlobalDescribe().get(objName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        
        if(fieldSetObj != null){
            for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
                fieldsetData.add(new ChecklistWrapper(String.valueOf(eachFieldSetMember.getLabel()) , 
                                                      String.valueOf(eachFieldSetMember.getFieldPath()), 
                                                      String.valueOf(eachFieldSetMember.getType()).toLowerCase()));
                fieldsLst.add(String.valueOf(eachFieldSetMember.getFieldPath()));
            }
        }
        if(!fieldsLst.isEmpty() && recordId != null && objName != null){  
            String query = 'SELECT Id, ' + String.join(fieldsLst, ',') + ' FROM '+objName +' WHERE Id= :recordId ';
            sObjData= Database.query(query);
            fieldsLst.clear();
            for(ChecklistWrapper d :fieldsetData){
                if(sObjData.size() >0) d.isValid(sObjData[0]);
            }
        }
        return fieldsetData;
    }
    
    public class ChecklistWrapper {
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled       
        public String fieldName {get;set;}
        @AuraEnabled
        public String type {get;set;} 
        @AuraEnabled
        public Boolean complete=false;   
        //Create and set three variables label, fieldname and type 
        public ChecklistWrapper(String name, String fieldName, String type){
            this.name = name;
            this.fieldName = fieldName;   
            this.type = type;   
        }
        public void isValid(sObject sObj ){
            Set<String> fieldValues = new Set<String>{'true','yes','n/a','not applicable'};
                if(type == 'boolean' || type== 'picklist'){
                    String val= sObj.get(fieldName) != null ? String.valueOf(sObj.get(fieldName)).toLowerCase() : '';
                    if(fieldValues.contains(val))complete = true;
                }
            else{
                if(sObj.get(fieldName) != null) complete = true;
            }
        }
    }
}