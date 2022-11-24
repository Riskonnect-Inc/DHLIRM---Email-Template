@isTest
public class ApproveRejectProperty_Test {
  public static testMethod void testAppRej(){
    
    Property__c p1 = new Property__c(Name='Test prop',Property_Id__c='1234',Active__c=true,Values_Collection_Email__c='test.admin@rkproduct.qa',Approval_Status__c='Pending Review');
    insert p1;
    
    Property_Value_Control__c pvc = new Property_value_Control__c(Evaluation_Date__c = system.today(),Total_Property_Values_Assigned__c=0);
    insert pvc;
      
      ApproveRejectProperty_Controller.getPVCList();
      ApproveRejectProperty_Controller.processProperty(p1.Id, pvc.Id, 'Test', 'Approve');
  }
  
  
}