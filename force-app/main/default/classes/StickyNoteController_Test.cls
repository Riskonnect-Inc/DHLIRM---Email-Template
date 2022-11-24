/*===========================================================================
     Added to RK base RMIS product as  11/05/2014
      ===========================================================================*/
  
@isTest
public class StickyNoteController_Test {
    public static testmethod void testStickNoteController() {
        User currentUser = [SELECT ID, StickyNote__c FROM User WHERE ID =: UserInfo.getUserId() LIMIT 1];
        StickyNoteController testController = new StickyNoteController(new ApexPages.StandardController(currentUser));
        testController.stickynote = 'TEST';
        testController.SaveRecord();
        currentUser = [SELECT ID, StickyNote__c FROM User WHERE ID =: UserInfo.getUserId() LIMIT 1];
        System.assertEquals('TEST', currentUser.StickyNote__c);        
    }
}