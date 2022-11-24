/*===========================================================================
     Added to RK base RMIS product as  05/26/2015
   ===========================================================================*/
    
@isTest
private class TimelineControllerTest {
    
    @isTest static void test_method_one() {

        Root_Cause_Analysis__c base = new Root_Cause_Analysis__c();
        insert base;
        List<Timeline__c> timelineEvents = new List<Timeline__c>();
        timelineEvents.add(
            new Timeline__c(Root_Cause_Analysis__c = base.id,
                            Label__c = 'test1',
                            Timeline_Event_Date__c = Date.today()));
        timelineEvents.add(
            new Timeline__c(Root_Cause_Analysis__c = base.id,
                            Label__c = 'test1',
                            Timeline_Event_Date__c = Date.today()));
        timelineEvents.add(
            new Timeline__c(Root_Cause_Analysis__c = base.id,
                            Label__c = 'test1',
                            Timeline_Event_date_time__c = System.now()));
        insert timelineEvents;

        Test.setCurrentPageReference(new PageReference('Page.Timeline_beta'));
        System.currentPageReference().getParameters().put('Id', base.id);
        System.currentPageReference().getParameters().put('field', 'Root_Cause_Analysis__c');
        TimelineController timelineControllerMain = new TimelineController();
        System.assertEquals(timelineControllerMain.header1,'Root Cause Analysis:');
        // Implement test code
    }
    
    @isTest static void test_method_two() {
    }
    
}