@isTest
public class FlowAttachmentsToFilesTest {
	
    @isTest
    public static void testConvertAttachments(){
        Claim__c testClaim = new Claim__c(Date_of_Loss__c = System.today(), Name = 'TestClaim123');
        insert testClaim;
        Attachment testAttachment = new Attachment();
        testAttachment.Body = blob.valueOf('test');
        testAttachment.Name = 'Test.txt';
        testAttachment.ParentId = testClaim.Id;
        insert testAttachment;
        FlowAttachmentsToFiles.request req = new FlowAttachmentsToFiles.request();
        req.IDs = testAttachment.Id;
        req.parentId = testClaim.Id;
        FlowAttachmentsToFiles.convertAttachments(New List<FlowAttachmentsToFiles.request>{ req });
    }
}