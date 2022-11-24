/*===========================================================================
      Added to RK base RMIS product as 04/08/2014
    AUTHOR: Jason Bradley
    ===========================================================================*/

@isTest
public class ChatterExtractFeedTest {
    public static testMethod void testMethod1() {
        Test.StartTest();
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;
        
        PageReference testPage = new PageReference('/apex/ChatterExtractFeedContainer');
        testPage.getParameters().put('id', testAccount.ID);
        testPage.getParameters().put('startDate', '3/15/2012');
        testPage.getParameters().put('endDate', '12/12/2013');
        Test.setCurrentPage(testPage);
        
        //FeedItem testChatterPost = new FeedItem(Body='Test Post', ParentID=testAccount.ID);
        //insert testChatterPost;
        
        //FeedComment testComment = new FeedComment(CommentBody='Test Comment Body', FeedItemID=testChatterPost.ID);
        //insert testComment;
        
        Attachment testAttachment = new Attachment();
        testAttachment.ParentID = testAccount.ID;
        
        //FeedItem testComment8 = new FeedItem(Body='Test Comment Body', ParentID=testAccount.ID, ContentFileName=testAttachment.Name, ContentData=testAttachment.Body);
        //insert testComment8;
        
        //FeedItem testComment3 = new FeedItem(Body='Test Comment Body', ParentID=testAccount.ID, LinkUrl='http://www.google.com');
        //insert testComment3;
        
        //FeedItem testComment4 = new FeedItem(Body='Test Comment Body', ParentID=testAccount.ID, LinkUrl='http://www.google.com', ContentFileName=testAttachment.Name, ContentData=testAttachment.Body);
        //insert testComment4;
        
        
        ChatterExtractFeedContainerController testClass = new ChatterExtractFeedContainerController();
        String attachmentName = testClass.getAttachmentName('Test Attachment');
        System.assertEquals(attachmentName, 'Attachment Name: Test Attachment');
        String linkURL = testClass.getLinkURL('Test URL');
        System.assertEquals(linkURL, 'Link URL: Test URL');
        ChatterExtractFeedContainerController.ChatterPost testPost = new ChatterExtractFeedContainerController.ChatterPost();
        testPost.setTitle('Test Title').setBody('Test Body').setPosterID('Test Poster ID').setTimeOfPost('Test Time Of Post').setAttachmentName('Test Attachment Name').setLinkURL('Test Link URL');
        ChatterExtractFeedContainerController.ChatterPost testPost2 = new ChatterExtractFeedContainerController.ChatterPost('Title', 'body', 'timeOfPost');
        ChatterExtractFeedContainerController.ChatterPostComment testComment2 = new ChatterExtractFeedContainerController.ChatterPostComment('postername', 'body', 'timeOfPost', UserInfo.getUserId());
        
        testPost.addComment(createTestComment()).addComment(createTestComment());
        Component.Apex.OutputPanel testPanel = testClass.createChatterFeedItem(testPost);
        
        testClass.createErrorMessage('Error Message');
        
        testPage.getParameters().put('id', testAccount.ID);
        testPage.getParameters().put('startDate', '');
        testPage.getParameters().put('endDate', '12/12/2013');
        Test.setCurrentPage(testPage);
        ChatterExtractFeedContainerController testClass2 = new ChatterExtractFeedContainerController();
        
        testPage.getParameters().put('id', testAccount.ID);
        testPage.getParameters().put('startDate', '12/12/2013');
        testPage.getParameters().put('endDate', '');
        Test.setCurrentPage(testPage);
        ChatterExtractFeedContainerController testClass3 = new ChatterExtractFeedContainerController();
        
        testPage.getParameters().put('id', testAccount.ID);
        testPage.getParameters().put('startDate', '12/12/2013');
        testPage.getParameters().put('endDate', 'asdf');
        Test.setCurrentPage(testPage);
        ChatterExtractFeedContainerController testClass4 = new ChatterExtractFeedContainerController();
        
        testPage.getParameters().put('id', testAccount.ID);
        testPage.getParameters().put('startDate', '12/12/2013332');
        testPage.getParameters().put('endDate', '');
        Test.setCurrentPage(testPage);
        ChatterExtractFeedContainerController testClass5 = new ChatterExtractFeedContainerController();
        
        testPage.getParameters().put('id', testAccount.ID);
        testPage.getParameters().put('startDate', '12/12/2013');
        testPage.getParameters().put('endDate', '1/12/2013');
        Test.setCurrentPage(testPage);
        ChatterExtractFeedContainerController testClass6 = new ChatterExtractFeedContainerController();
        
        testPage.getParameters().put('id', '');
        testPage.getParameters().put('startDate', '12/12/2013');
        testPage.getParameters().put('endDate', '1/12/2013');
        Test.setCurrentPage(testPage);
        ChatterExtractFeedContainerController testClass7 = new ChatterExtractFeedContainerController();
        
        testPage.getParameters().put('id', '01IG00000028BWJ');
        testPage.getParameters().put('startDate', '12/12/2013');
        testPage.getParameters().put('endDate', '1/12/2013');
        Test.setCurrentPage(testPage);
        ChatterExtractFeedContainerController testClass8 = new ChatterExtractFeedContainerController();
        
        Test.StopTest();
    }
    
    public static testMethod void testSecondController() {
        Test.StartTest();
        PageReference testPage = new PageReference('/apex/ChatterExtractPage');
        ChatterExtractPageController testController = new ChatterExtractPageController(null);
        Test.StopTest();
    }
    
    public static ChatterExtractFeedContainerController.ChatterPostComment createTestComment() {
        ChatterExtractFeedContainerController.ChatterPostComment newComment = new ChatterExtractFeedContainerController.ChatterPostComment();
        newComment.setPosterName('Test Poster Name').setBody('Test Body').setTimeOfPost('Test Time of Post').setPosterID(UserInfo.getUserId());
        return newComment;
    }
}