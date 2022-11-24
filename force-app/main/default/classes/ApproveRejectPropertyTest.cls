/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
     Updated 11/2016
===========================================================================*/
@isTest
private class ApproveRejectPropertyTest {
  
  public static testMethod void testAppRej(){
    
    Property__c p1 = new Property__c(Name='Test prop',Property_Id__c='1234',Active__c=true,Values_Collection_Email__c='test.admin@rkproduct.qa',Approval_Status__c='Pending Review');
    insert p1;
    
    Property_Value_Control__c pvc = new Property_value_Control__c(Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
    insert pvc;
    
    ApexPages.StandardController sc = new ApexPages.standardController(p1);
        ApproveRejectPropertyController arp = new ApproveRejectPropertyController(sc);
        
        arp.value = 'Approve';
        arp.pvCtrl = pvc.id;
        system.assertEquals(arp.pvCtrl,(string)pvc.Id);
        
        arp.processProperty(); 
        List<selectOption> lstpvc = arp.Pvc;
        Integer totalPvc =  arp.PvcSize;
        List<selectOption> lst = arp.Items;
  }
  
  

}