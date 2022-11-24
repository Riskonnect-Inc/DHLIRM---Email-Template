@isTest
public class RenewalControlController_Test {
    @isTest
    public static void testSuccessMethod() {
        rkl__Renewal_Control__c renewal = new rkl__Renewal_Control__c();
        insert renewal;
        RenewalControl_Controller.getGrpPercCompleted(renewal.Id);
        RenewalControl_Controller.Renewal_Utils(renewal.Id);
    }     
}