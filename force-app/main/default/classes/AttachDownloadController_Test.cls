/*===========================================================================
     Added to RK base RMIS product as 05/21/2014
 ===========================================================================*/
@isTest
public class AttachDownloadController_Test {
    public static testmethod void testAttachDownloadController() {
        Claim__c testClaim = new Claim__c();
        testClaim.Date_of_Loss__c = System.today();
        insert testClaim;
        
        Attachment testAttachment = new Attachment();
        testAttachment.Name = 'TestAttachment.txt';
        testAttachment.Body = Blob.valueOf('TEST BODY');
        testAttachment.ParentId = testClaim.ID;
        insert testAttachment;
        
        PageReference testPage = new PageReference('/apex/ZipAttachments?id=' + testClaim.ID);
        Test.setCurrentPage(testPage);
        
        AttachDownloadController testController = new AttachDownloadController();
        String jsonFormat = testController.getAttachmentsJSON();
        
        String[] ser = new String[]{};
        for (Attachment a: [Select Id, Name, ContentType From Attachment Where ParentId=:testClaim.ID]) {
            ser.add(a.Name);
            ser.add(EncodingUtil.base64Encode([Select Body From Attachment Where Id=:a.Id].Body));
        }
        
        String expectedResult = JSON.serialize(ser);
        
        System.assertEquals(expectedResult, jsonFormat);
    }
    
    public static testmethod void testAttachDownoadControllerExtension() {
        Claim__c testClaim = new Claim__c();
        testClaim.Date_of_Loss__c = System.today();
        insert testClaim;
        
        Attachment testAttachment = new Attachment();
        testAttachment.Name = 'TestAttachment.txt';
        testAttachment.Body = Blob.valueOf('TEST BODY');
        testAttachment.ParentId = testClaim.ID;
        insert testAttachment;
        
        PageReference testPage = new PageReference('/apex/ZipAttachments');
        Test.setCurrentPage(testPage);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(testClaim);
        AttachDownloadController testController = new AttachDownloadController(stdController);
        String jsonFormat = testController.getAttachmentsJSON();
        
        String[] ser = new String[]{};
        for (Attachment a: [Select Id, Name, ContentType From Attachment Where ParentId=:testClaim.ID]) {
            ser.add(a.Name);
            ser.add(EncodingUtil.base64Encode([Select Body From Attachment Where Id=:a.Id].Body));
        }
        
        String expectedResult = JSON.serialize(ser);
        
        System.assertEquals(expectedResult, jsonFormat);
    }
}