@isTest
private class FilesControllertest {
    static testMethod void Testfiles() {
        string claimsid;
        Claim__c clm = new Claim__c(Date_of_Loss__c=System.today());
        insert clm;
        contentversion content = new contentversion();
        content.PathOnClient ='A.txt';
        content.Title='A';
        content.Categories__c='Uncategorized';
        content.Description='Test';
        content.FirstPublishLocationId=clm.Id;
        content.versiondata=EncodingUtil.base64Decode('This is version data');
        insert content;
        
        List<Id> contentdocumentId = new List<Id>();
        List<Id> contentversionId = new List<Id>();
        for (contentversion link : [ 
            SELECT Id,ContentDocumentId from contentversion where Firstpublishlocationid =:clm.Id ]) {
                contentdocumentId.add(link.ContentDocumentId);
                contentversionId.add(link.Id);
            }
        List<contentversion> lstfiles = new List<contentversion>();
        for (contentversion files : [ 
            SELECT Title, ContentDocumentId, FileType, Description, ContentSize, Categories__c, CreatedDate 
            FROM ContentVersion 
            WHERE Firstpublishlocationid =:clm.Id ]) {
                lstfiles.add(files);
            }
        Object Picklist=FilesController.picklist(claimsid=clm.Id);
        Object loadCategories=FilesController.loadCategories(claimsid=clm.Id);
        Object getCurrentfiles=Filescontroller.getCurrentfiles(contentdocumentId,'CAT_Claim__c');
        object updatefiles=Filescontroller.updatefiles(contentversionId, 'Test','Uncategorized',true,true,lstfiles,'CAT_Claim__c');
        object deleteRecordId = Filescontroller.deleteRecordId(contentversionId[0],'Contentdocument');
        object deleteRecordIdnull = Filescontroller.deleteRecordId('','Contentdocument');
        object overallpicklist = PickListController.getPickListValuesIntoList('ContentVersion','CAT_Claim__c');
        Set<Id> latestVerScope = new Set<Id>();
        for (ContentDocumentLink link : [ 
            SELECT ContentDocument.LatestPublishedVersionId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = 'a1d6A000000ECn3QAG' ]) {
                latestVerScope.add(link.ContentDocument.LatestPublishedVersionId);
            }
    }
}