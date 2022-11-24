/*
 * Mike Ulveling
 */
 
 /*===========================================================================
     Added to RK base RMIS product as 05/21/2014
 ===========================================================================*/
    
public class AttachDownloadController {
    public Id parentId {get; private set;}
    //sObject[] attachList;
    //public String attachListJSON {get{
    //    return JSON.serialize(attachList);
    //}}
    
    public String recordName {get;private set;}
    private Map<String,List<String>> myAttachments {get;private set;}
    public String myAttachmentsJSON {get;private set;}
    
    public AttachDownloadController() {
        parentId = (Id) ApexPages.currentPage().getParameters().get('id');
        recordName = (String) Database.query('Select Name From ' + parentId.getSObjectType() + ' Where Id=\'' + parentId + '\'')[0].get('Name');
        myAttachments = new Map<String,List<String>>();
        
        List<Attachment> attachments = [Select Id, Name From Attachment Where ParentId=:parentId];
        if(attachments.size()>0){
            myAttachments.put('Attachment',new List<String>());
            for(Attachment a : attachments){
                myAttachments.get('Attachment').add(a.Id);
            }
        }
        List<FeedItem> feedItems = [select Type from FeedItem where ParentId =: parentId];
        Set<Id> feedCommentIds = new Set<Id>();
        for(FeedItem fi : feedItems){
            FeedCommentIds.add(fi.Id);
            if(fi.Type=='ContentPost'){
                if(myAttachments.containsKey('ChatterFeed')){
                    myAttachments.get('ChatterFeed').add(fi.Id);
                } else{
                    myAttachments.put('ChatterFeed',new List<String>{fi.Id});
                }
            }
        }
        if(myAttachments.containsKey('ChatterFeed')){
            List<FeedComment> feedComments = [select CommentType, RelatedRecordId from FeedComment where FeedItemId in: feedCommentIds];
            for(FeedComment fc : feedComments){
                if(fc.CommentType == 'ContentComment'){
                    if(myAttachments.containsKey('ChatterComment')){
                        myAttachments.get('ChatterComment').add(fc.RelatedRecordId);
                    } else{
                        myAttachments.put('ChatterComment',new List<String>{fc.RelatedRecordId});
                    }
                }
            }
        }
        myAttachmentsJSON = JSON.serialize(myAttachments);
        //attachList = [Select Name, ContentType From Attachment Where ParentId=:parentId];
    }
    
    public AttachDownloadController(ApexPages.StandardController stdCtrl) {
        ApexPages.currentPage().getHeaders().put('Access-Control-Allow-Origin', 'https://cs18.salesforce.com');
    
        parentId = stdCtrl.getRecord().Id;
        recordName = (String) Database.query('Select Name From ' + stdCtrl.getRecord().getSObjectType() + ' Where Id=\'' + parentId + '\'')[0].get('Name');
        //attachList = [Select Name, ContentType From Attachment Where ParentId=:parentId];
    }
    
    public String getAttachmentsJSON() {
        String[] ser = new String[]{};
        for (Attachment a: [Select Id, Name, ContentType From Attachment Where ParentId=:parentId]) {
            ser.add(a.Name);
            // !! queries that select Blob data cannot be bulkified:
            ser.add(EncodingUtil.base64Encode([Select Body From Attachment Where Id=:a.Id].Body));
        }
        
        return JSON.serialize(ser);
    }
}