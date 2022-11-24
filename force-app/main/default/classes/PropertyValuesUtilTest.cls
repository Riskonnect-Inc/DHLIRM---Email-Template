/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
    ===========================================================================*/
    
@isTest
private class PropertyValuesUtilTest {
    
    static testMethod void testUnbatchedUtil()
       {
           Property_Value_Control__c pvc = new Property_Value_Control__c(Status__c='New', Adjustment_rate__c=2, evaluation_date__c = System.today(), email_option__c='One per person');
           insert pvc;
           
           Property__c p1 = new Property__c(Active__c = true, Name='test prop1',Property_ID__c='1234');
           Property__c p2 = new Property__c(Active__c = false, Name='test prop2',Property_ID__c='4567');
           
           insert p1;
           insert p2;
           
           Property_Value__c pv1 = new Property_Value__c(property_Value_Control__c = pvc.id,property__c = p1.Id);
           insert pv1;
           
           p1.Current_Property_Value__c = pv1.id;
           update p1;
           
           PropertyValuesUtil.unbatchedUtil(pvc);  
           PropertyValuesUtil pUtil = new PropertyValuesUtil(pvc, new List<Property_Value__c> {pv1}, new List<Property__c> {p1,p2});
           pUtil.resetRenewal();                  
       }

}