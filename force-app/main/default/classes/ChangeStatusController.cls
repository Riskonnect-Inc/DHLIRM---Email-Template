global class ChangeStatusController{

    public ChangeStatusController(ApexPages.StandardController controller) {
        
    }


public Schema.SObjectType objType {get;set;}
public List<SelectOption> picklistNames {get; set; }
public String labelName {get;set;}
public Id currentRecordId  {get;set;}
public String pickFld{get;set;}
public String objApi{get;set;}

public ChangeStatusController(){
    currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
    objType = currentRecordId.getSobjectType();
    labelName =objType.getDescribe().getLabel();
    if(objType.getDescribe().getLabel() == 'Patient Feedback')
    {
        pickFld = 'Status_of_Complaint__c';
        objApi=objType.getDescribe().getName();
    }
    if(objType.getDescribe().getLabel() == 'Peer Review')
    {
        pickFld = 'Status__c';
        objApi=objType.getDescribe().getName();
    }
    if(objType.getDescribe().getLabel() == 'Root Cause Analysis')
    {
        pickFld = 'Status__c';
        objApi=objType.getDescribe().getName();
    }
    if(objType.getDescribe().getLabel() == 'Patient Event')
    {
        pickFld = 'Patient_Event_Status__c';
        objApi=objType.getDescribe().getName();
    }
    
    picklistNames = getPicklistValues(objApi ,pickFld );
}

  @RemoteAction
    global static void savObje(String recId,String objName,String fldName,String statusVal){
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objName);
    sObject obj = targetType.newSObject();
    obj.put(fldName, statusVal);


       if(objName ==  'Peer_Review__c' )
        {
            
            if (statusVal == 'Closed')
            {
                obj.put('id', recId);
                obj.put(fldName, statusVal);
                obj.put('Date_Closed__c',  Date.today());
                update obj;
                
            }
            else
            { 
                 obj.put('id', recId);
                 obj.put(fldName, statusVal);
                 update obj;
             }
         }
         
         if(objName == 'Patient_Event__c')
         {
            
            if (statusVal=='Closed')
            {
                obj.put('id', recId);
                obj.put(fldName, statusVal);
                obj.put('Date_Event_Closed__c',  Date.today());
                update obj;
                
             } 
             else
             { 
               obj.put('id', recId);
               obj.put(fldName, statusVal);
               update obj;
              }
         }
         
         
          if(objName == 'Patient_Satisfaction__c'){

            Patient_Satisfaction__c pfd = [Select Date_Closed__c, Date_Resolved__c FROM Patient_Satisfaction__c WHERE Id = :recId];
            
            if (statusVal=='Closed - Resolved' && pfd.Date_Resolved__c == null)
            {
                obj.put('id', recId);
                obj.put(fldName, statusVal);
                obj.put('Date_Closed__c',  Date.today());
                obj.put('Date_Resolved__c', Date.today());
                obj.put('Feedback_Resolved__c', true);
                update obj;
                
             } 
            else if (statusVal=='Closed - Resolved' && pfd.Date_Resolved__c != null)
            {
                obj.put('id', recId);
                obj.put(fldName, statusVal);
                obj.put('Date_Closed__c', Date.today());
                obj.put('Feedback_Resolved__c', true);
                update obj;
            }
            else if (statusVal=='Closed - Unresolved')
            {
                obj.put('id', recId);
                obj.put(fldName, statusVal);
                obj.put('Date_Closed__c', Date.today());
                update obj;
            }
             else
             { 
               obj.put('id', recId);
               obj.put(fldName, statusVal);
               update obj;
              }
         }
         
         
          if(objName == 'Root_Cause_Analysis__c')
         {
            
            if (statusVal == 'Closed')
            {
                obj.put('id', recId);
                obj.put(fldName, statusVal);
                obj.put('Date_Closed__c',  Date.today());
                update obj;
                
             }
             else
             { 
                 obj.put('id', recId); 
                 obj.put(fldName, statusVal);  
                 update obj;
             }
         }
         
         
        
    }

 public List<SelectOption> getPicklistValues(String ObjectApi_name,String Field_name){ 
   
    List<SelectOption> lstPickvals=new List<SelectOption>();
    Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
    Sobject Object_name = targetType.newSObject();
    Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
    Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
    Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
    List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues();
   
    for (Schema.PicklistEntry a : pick_list_values) {
    lstPickvals.add(new SelectOption(a.getLabel(),a.getLabel()));
    }
         
   return lstPickvals;
    }
    
}