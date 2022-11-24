/*===========================================================================
      Added to RK base RMIS product as 02/17/2015
 ===========================================================================*/
global class ChatterCopier {

    global ChatterCopier(Id oldParent, Id newParent){
        List<FeedItem> feedItems = new List<FeedItem>([select RelatedRecordId, ContentFileName, ContentSize, Body, CreatedDate, ParentId, Type
                                                       from FeedItem where ParentId =: oldParent]);
        Set<Id> feedCommentIds = new Set<Id>();
        for(FeedItem fi : feedItems){
            FeedCommentIds.add(fi.Id);
        }
        List<FeedComment> feedComments = new List<FeedComment>([select CommentBody, CommentType, FeedItemId, RelatedRecordId, CreatedDate
                                                                from FeedComment where FeedItemId in: feedCommentIds]);
        
        List<FeedItem> newFeedItems = new List<FeedItem>();
        List<FeedComment> newFeedComments = new List<FeedComment>();
        Map<Id,FeedItem> feedCommentMapping = new Map<Id,FeedItem>();
        
        for(FeedItem fi : feedItems){
            FeedItem newFeedItem = new FeedItem(RelatedRecordId = fi.RelatedRecordId,
                                          Body = fi.Body,
                                          CreatedDate = fi.CreatedDate,
                                          ParentId = newParent,
                                          Type = fi.Type);
            newFeedItems.add(newFeedItem);
            feedCommentMapping.put(fi.Id,newFeedItem);
        }
        if(newFeedItems.size()>0){
            insert newFeedItems;
            for(FeedComment fc : feedComments){
                Id newFeedItemId = feedCommentMapping.get(fc.FeedItemId).Id;
                FeedComment newFeedComment = new FeedComment(
                                                CommentBody = fc.CommentBody,
                                                CommentType = fc.CommentType,
                                                FeedItemId = newFeedItemId,
                                                RelatedRecordId = fc.RelatedRecordId,
                                                CreatedDate = fc.CreatedDate);
                newFeedComments.add(newFeedComment);
            }
            if(newFeedComments.size()>0){
                insert newFeedComments;
            }
        }
    }
    
}