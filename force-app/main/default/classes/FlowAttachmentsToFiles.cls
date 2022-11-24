public class FlowAttachmentsToFiles {
	
    @InvocableMethod
    public static List<Result> convertAttachments(List<Request> requests){
        List<Result> results = new List<Result>();
        List<ContentVersion> fileList = new List<ContentVersion>();

            for (Request req : requests){
                    
                
                Set<Id> attachIds = new Set<Id>();
                if (string.isNotBlank( req.IDs)){
                    attachIds.addAll((List<Id>)req.IDs.remove(' ').split(';'));
                } else {
                    attachIds.addAll(req.IDList);
                }
                system.debug(attachIds);
                List<Attachment> attachments = [select id, name, body from Attachment where Id in :attachIds];
                for (Attachment a : attachments){
                    ContentVersion file = new ContentVersion();
                    file.VersionData = a.body;
                    file.PathOnClient = a.name;
                    file.FirstPublishLocationId = req.parentId;
                    //file.Title = a.name;
                    file.CAT_Claim__c = req.category;
                    file.CAT_Intake__c = req.category;
                    fileList.add(file);
                }
            } 
        
        insert fileList;
        
        return results;
    }
    
    public class Request {
        @InvocableVariable
        public string category;
        
        @InvocableVariable
        public string IDs;
        
        @InvocableVariable
        public Id parentId;
        
        @InvocableVariable
        public List<Id> IDList;
    }
    
    public class Result {
        @InvocableVariable
        public List<Id> contentDocumentIds;
        
        @InvocableVariable
        public string status;
        
        @InvocableVariable
        public string message;
    }
}