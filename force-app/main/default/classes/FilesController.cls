public class FilesController {
    
    // =======================================================================================================================================================
    // MDU 4-19-2018: rewrites of some controller methods, for proper traversal of ContentDocument/ContentDocumentLink/ContentVerison file records:
    
    // Fetches file details, partitioned by categories:
    @AuraEnabled
    public static CategoryDetail[] loadCategories(Id claimId) {
        String picklist = picklist(claimId);
        Set<Id> latestVerScope = new Set<Id>();
        // find all files associated with the given claim by querying the ContentDocumentLink table; furthermore, the "LatestPublishedVersionId" thru-parent 
        // reference gives us the latest version of each associated file:
        for (ContentDocumentLink link : [ 
                SELECT ContentDocument.LatestPublishedVersionId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :claimId ]) {
            latestVerScope.add(link.ContentDocument.LatestPublishedVersionId);
        }
        String query = 
            'SELECT Title, ContentDocumentId, FileType, FileExtension, Description, ContentSize, ' + picklist + ', CreatedDate' + 
            ' FROM ContentVersion' + 
            ' WHERE Id IN :latestVerScope' + 
            ' ORDER BY Title ASC';
        List<ContentVersion> sObjDataLst = new List<ContentVersion>();
        sObjDataLst = Database.query(query);
        Map<String, CategoryDetail> catKeyToDetailLC = new Map<String, CategoryDetail>();
        for (ContentVersion ver : sObjDataLst) {
            String catKey = ver.get(picklist) == null ? 'Uncategorized' : (String) ver.get(picklist);
            CategoryDetail cat = catKeyToDetailLC.get(catKey.toLowerCase());
            if (cat == null) {
                catKeyToDetailLC.put(catKey.toLowerCase(), cat = new CategoryDetail(catKey));
            }
            cat.files.add(ver);
        }
        CategoryDetail[] cats = new CategoryDetail[]{};
        // to build the list of category-detail objects, we loop through the Category picklist values so that we add the categories in their preferred order:
        for (String catKey : getCategories(picklist, 'ContentVersion')) {
            CategoryDetail cat = catKeyToDetailLC.get(catKey.toLowerCase());
            if (cat != null) {
                cats.add(cat);
            }
        }
        return cats;
    }
    
    public class CategoryDetail {
        public String catKey {get; private set;}
        @AuraEnabled 
        public String catLabel {get; private set;}
        @AuraEnabled 
        public ContentVersion[] files {get; private set;} 
        
        public CategoryDetail(String catKey) { 
            this.catKey = catKey; // if null, then this implies the default "Uncategorized" category
            this.catLabel = catKey;
            this.files = new ContentVersion[]{};
        }
    }
    
    // MDU: enhanced this method to resolve the passed-in document IDs to their latest content versions; it also guarantees a return ordering congruent to that 
    // of the passed-in content document IDs:
    //Fetching the uploaded file details for passing it to the categories section
    @AuraEnabled
    public static ContentVersion[] getCurrentfiles(String[] uploadedFileIds, String Picklist) {
        Map<Id, Id> docToLatestVer = new Map<Id, Id>();
        String docIds = '';
        for (ContentDocument doc : [ 
            SELECT LatestPublishedVersionId 
            FROM ContentDocument 
            WHERE Id IN :uploadedFileIds ]) {
                docToLatestVer.put(doc.Id, doc.LatestPublishedVersionId);
                docIds = docIds + '\''+doc.LatestPublishedVersionId+'\',';
            }
        docIds = docIds.removeEnd(',');
        string query;
        query = 'SELECT Title, FileType, Description,FileExtension, ContentSize, '+Picklist+' FROM ContentVersion WHERE Id IN ('+docIds+')';
        List<contentversion> sObjDataLst = new List<contentversion>();
        sObjDataLst = Database.query(query);
        Map<Id, ContentVersion> verMap = new Map<Id, ContentVersion>(sObjDataLst);
        ContentVersion[] vers = new ContentVersion[]{};
        for (String docKey : uploadedFileIds) {
            Id docId;
            try {
                docId = Id.valueOf(docKey);
            } catch (Exception ignore) {}
            vers.add(verMap.get(docToLatestVer.get(docId)));
        }
        return vers;
    }
    
    //Updating the uploaded files with its categories and description.
    @AuraEnabled 
    public static ContentVersion[] updatefiles(String[] uploadedFileIds, String description, String picklist, 
            Boolean descriptioncheck, Boolean Categoriescheck, List<ContentVersion> lstContent, String picklistvalue) {
        // ensure we only perform final DML on the latest content versions of the referenced files (they may have changed in the meantime):
        Map<Id, ContentVersion> verReadableMap = new Map<Id, ContentVersion>(lstContent != null ? lstContent : new ContentVersion[]{});
        Map<Id, ContentVersion> docToVerReadable = new Map<Id, ContentVersion>();
        Map<Id, ContentVersion> docToVerWritable = new Map<Id, ContentVersion>();
        for (ContentVersion ver : [ 
                SELECT ContentDocument.LatestPublishedVersionId 
                FROM ContentVersion 
                WHERE ContentDocumentId IN :uploadedFileIDs OR Id IN :verReadableMap.keySet() ]) {
            Id docId = ver.ContentDocumentId;
            ContentVersion readableVer = verReadableMap.get(ver.Id);
            if (readableVer != null) {
                docToVerReadable.put(docId, readableVer);
            }
            // if this is the latest version for the referenced file, then use it as the file's writable version:
            if (ver.Id == ver.ContentDocument.LatestPublishedVersionId) {
                docToVerWritable.put(docId, ver);
                // else if we don't yet have a writable for this referenced file, then create a new empty one based on the referenced file's latest version:
            } else if (!docToVerWritable.containsKey(docId)) {
                docToVerWritable.put(docId, new ContentVersion(Id = ver.ContentDocument.LatestPublishedVersionId));
            }
        }
        ContentVersion[] updates = new ContentVersion[]{};
        for (String docKey : uploadedFileIds) {
            Id docId;
            try {
                docId = Id.valueOf(docKey);
            } catch (Exception ignore) {}
            ContentVersion verWritable = docToVerWritable.get(docId);
            if (verWritable != null) {
                updates.add(verWritable);
                ContentVersion verReadable = docToVerReadable.get(docId);
                if (verReadable != null) {
                    verWritable.Description = verReadable.Description;
                }
                if (verReadable != null) {
                    verWritable.put(picklistvalue,verReadable.Categories__c);
                }
            }
        }
        update updates;
        return updates;
    }
    
    // =======================================================================================================================================================
    
    //For getting the values of the categories
    @AuraEnabled
    public static List<String> getCategories(String picklist, string contentversion) {
        List<String> options = new List<String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(contentversion);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(picklist).getDescribe();
        for (Schema.PicklistEntry f : fieldResult.getPicklistValues()) {
            options.add(f.getLabel());
        }
        return options;
    }
    
    //For deleting the files
    @AuraEnabled
    public static String deleteRecordId(String idVal, String obj) {
        if (String.isBlank(idVal)) {
            return null;
        }
        String name;
        sObject[] del = Database.query('SELECT Title FROM ' + obj + ' WHERE Id = :idVal');
        if (!del.isEmpty()) {
            name = (String) del[0].get('Title');
            delete del;
        }
        return name;
    }
    
    //For getting the picklist field name which change according to the object
    @AuraEnabled
    public static String picklist(Id sId) {
        DescribeSObjectResult describeResult = ContentVersion.getSObjectType().getDescribe();	
        List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
        
        String rt;
        String st = 'CAT_'+sId.getsobjecttype();
        for(String s : fieldNames){
            if(s.equalsIgnoreCase(st)){
                rt = s;
                
            }
        }
        return rt;
    }
}