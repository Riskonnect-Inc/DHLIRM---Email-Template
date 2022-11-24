/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
     Updated 11/2016
===========================================================================*/

/*Sindhu Suru for the Approve/reject button on the property detail page - 5/5/15*/

public class ApproveRejectPropertyController{
    public Property__c prop{get;set;}
    public string pvCtrl{get;set;}
    public string value{get;set;}
    public List<selectOption> items{get{
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Approve','Approve'));
        options.add(new SelectOption('Reject','Reject'));
        
        return options;
        }}
    public Integer pvcSize {get{ 
        return pvc.size();}}
        
    public List<SelectOption> pvc {
        get{
            List<Property_Value_Control__c> pvcList = [select id, Collection_Name__c, Evaluation_Date__c from Property_value_Control__c where status__c = 'In Progress'];
            List<SelectOption> options = new List<SelectOption>();
            for(Property_Value_Control__c pCtrl : pvcList ){
                options.add(new SelectOption(pCtrl.id,pCtrl.Collection_Name__c + ', '+pCtrl.Evaluation_Date__c.format()));
            }
            return options;}}
 
    public ApproveRejectPropertyController(ApexPages.StandardController stdController){
        Property__c stdProp = (Property__c)stdCOntroller.getRecord();
        this.prop = [select id,Values_Collection_Email__c,Approval_Status__c,Approval_Comments__c from Property__c where id=: stdProp.id ];
    }
     
    public void processProperty() {
        Property_Value_Control__c propValCtr;
        if(this.value == 'Approve')
            prop.Approval_Status__c = 'Approved';
        else if(this.value == 'Reject')
            prop.Approval_Status__c = 'Rejected';
            
        if(pvCtrl != null && pvCtrl != ''){ 
            propValCtr = [select id, Evaluation_Date__c, Total_Property_Values_Assigned__c from Property_Value_Control__c where id =: pvCtrl limit 1];
        }else if(pvcSize == 1){
            propValCtr = [select id, Evaluation_Date__c, Total_Property_Values_Assigned__c from Property_Value_Control__c where status__c = 'In Progress' limit 1];
        }
        
        //Create new property Value record for the new property
        Property_Value__c pv = new Property_Value__c();
        pv.Property__c = prop.Id;
        pv.Values_Collection_Email__c = prop.Values_Collection_Email__c;
        if(propValCtr != null){
            pv.Evaluation_Date__c = propValCtr.Evaluation_Date__c;
            pv.Property_Value_Control__c = propValCtr.Id;
            
            propValCtr.Total_Property_Values_Assigned__c += 1;
            
        }
        try{
            insert pv;
            prop.Current_Property_Value__c = pv.Id;
            update prop;
            update propValCtr;
        }catch(exception e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error Occured while updating the property '+e.getMessage());
            ApexPages.addMessage(myMsg);
        }
    }
}