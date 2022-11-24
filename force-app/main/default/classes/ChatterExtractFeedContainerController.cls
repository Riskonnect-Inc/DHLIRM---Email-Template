/*===========================================================================
      Added to RK base RMIS product as  04/08/2014
    AUTHOR: Jason Bradley
 ===========================================================================*/
public class ChatterExtractFeedContainerController {
    
    public transient Component.Apex.OutputPanel thePanel {get; set;}
    
    private List<FeedItem> posts {get; set;}
    
    private Boolean dateTimeParsingError {get; set;}
    
    private Map<String, String> mapIdToUserPhotoThumb {get; set;}

    private Boolean showAllPosts {get; set;}

    private List<TopicAssignment> allTopicAssignmentsOnParentRecord {get; set;}
    
    public ChatterExtractFeedContainerController() {
        showAllPosts = false;
        dateTimeParsingError = false;
        thePanel = new Component.Apex.OutputPanel();
        String recordID = ApexPages.currentPage().getParameters().get('id');
        String startDateRange = ApexPages.currentPage().getParameters().get('startDate');
        String endDateRange = ApexPages.currentPage().getParameters().get('endDate');
        String hashtagFilter = ApexPages.currentPage().getParameters().get('htFilter'); 
        allTopicAssignmentsOnParentRecord = new List<TopicAssignment>();
        
        Date startDate, endDate;
        
        mapIdToUserPhotoThumb = new Map<String, String>();
        List<User> allUsers = Database.query(new al.SOQLBuilder().selectx(new List<String>{'ID', 'SmallPhotoUrl'}).fromx('User').toSOQL());
        for (User user: allUsers) {
            mapIdToUserPhotoThumb.put(user.ID, user.SmallPhotoUrl);
        }
        
        if (al.StringUtils.isBlank(startDateRange)) {
            startDate = Date.newInstance(1970, 1, 1);
            startDateRange = '1/1/1970';
        } else {
            try {
                startDate = Date.parse(startDateRange);
            } catch (Exception e) {
                //String was not in the correct format
                dateTimeParsingError = true;
            }
        }
        
        if (al.StringUtils.isBlank(endDateRange)) {
            endDate = Date.today().addDays(1);
            endDateRange = ((DateTime)endDate).format('M/d/yyyy');
        } else {
            try {
                endDate = Date.parse(endDateRange);
            } catch (Exception e) {
                //String was not in the correct format
                dateTimeParsingError = true;
            }
        }

        if (al.StringUtils.isBlank(startDateRange) && al.StringUtils.isBlank(endDateRange)) {
            showAllPosts = true;
        }
        
        if (endDate < startDate) {
            endDate = startDate.addDays(1);
        }
        
        if (recordID != null && recordID != '' && recordID != 'null' && !dateTimeParsingError) {
            //System.debug('The ID is not null or blank: \'' + recordID + '\'');
            //System.debug([FIND :recordID IN ID Fields RETURNING SObject]);
            try {
                posts = Database.query(new al.SOQLBuilder().selectx(new List<String>{'ID', 'CreatedDate', 'Body', 'ContentFileName', 'LinkUrl', 'LastModifiedDate', 'InsertedById', 'CreatedBy.FirstName', 'CreatedBy.LastName', 'Parent.Name', 'CommentCount', 'ParentID'}). 
                        selectx(new al.SOQLBuilder().selectx(new List<String>{'ID', 'CommentBody', 'CreatedDate', 'InsertedById', 'CreatedBy.FirstName', 'CreatedBy.LastName'})
                        .fromx('FeedComments')).
                        selectx(new al.SOQLBuilder().selectx(new List<String>{'CreatedBy.FirstName', 'CreatedBy.LastName'})
                        .fromx('FeedLikes')).
                        selectx(new al.SOQLBuilder().selectx(new List<String>{'ID', 'NewValue', 'OldValue', 'FieldName', 'FeedItemId'})
                        .fromx('FeedTrackedChanges'))
                    .fromx('FeedItem')
                    .wherex(new al.AndCondition()
                        .add(new al.FieldCondition('ParentID').equals(recordID))
                        .add(new al.FieldCondition('LastModifiedDate').greaterThanOrEqualTo(DateTime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0)))
                        .add(new al.FieldCondition('LastModifiedDate').lessThanOrEqualTo(DateTime.newInstance(endDate.year(), endDate.month(), endDate.day(), 24, 0, 0))))
                        .toSOQL());
                
                if (String.isNotBlank(hashtagFilter)) {
                    List<ID> postIDs = new List<ID>();
                    for (FeedItem post : posts) {
                        postIDs.add(post.ID);
                    }

                    Topic topicFilter = [SELECT ID, Name FROM Topic WHERE Name=:hashtagFilter LIMIT 1];

                    allTopicAssignmentsOnParentRecord = [SELECT ID, EntityID, TopicID FROM TopicAssignment WHERE EntityID IN: postIDs AND TopicID =: topicFilter.ID];

                    List<ID> filteredPostIDs = new List<ID>();

                    for (TopicAssignment topicAssignment : allTopicAssignmentsOnParentRecord) {
                        filteredPostIDs.add(topicAssignment.EntityID);
                    }

                    posts = [SELECT ID, CreatedDate, Body, ContentFileName, LinkUrl, LastModifiedDate, InsertedById, CreatedBy.FirstName, CreatedBy.LastName, Parent.Name, CommentCount, ParentID, (SELECT ID, CommentBody, CreatedDate, InsertedById, CreatedBy.FirstName, CreatedBy.LastName FROM FeedComments), (SELECT CreatedBy.FirstName, CreatedBy.LastName FROM FeedLikes) FROM FeedItem WHERE ID IN: filteredPostIDs ORDER BY CreatedDate DESC];
                }

                //allTopicAssignmentsOnParentRecord = [SELECT ID, EntityID, TopicID FROM TopicAssignment WHERE EntityID IN: postIDs];

                
                //SObject objectBeingViewed = Database.search('FIND {' + recordID + '} IN ID Fields');
                SObject objectBeingViewed = Database.query(new al.SOQLBuilder().selectx(new List<String>{'ID', 'Name'}).fromx(String.valueOf(((ID)recordID).getSObjectType())).wherex(new al.FieldCondition('ID').equals(recordID)).toSOQL());

                String objectLabel = objectBeingViewed.getSObjectType().getDescribe().getLabel();

                //String headerMain = 'Chatter Feed';
                //String headerClaimNumber = '[' + objectBeingViewed.get('Name') + ']';
                String objectIDLabel = objectLabel + ': ' + objectBeingViewed.get('Name');
                String headerDateRange = startDateRange + ' to ' + endDateRange;

                thePanel.childComponents.add(new Component.Apex.OutputText(value='<div class="header"><div class="headerLeft"></div><div class="headerRight"><div>' + objectIDLabel + '</div><div>' + headerDateRange + '</div><div>' + hashtagFilter + '</div></div></div>', escape=false));
                
                for (FeedItem post : posts) {
                    ChatterPost newPost = new ChatterPost().setTitle(post.CreatedBy.FirstName + ' ' + post.CreatedBy.LastName).setBody(post.Body).setPosterID(post.InsertedById).setTimeOfPost(post.CreatedDate.format('MMMMMMMM dd, yyyy - hh:mm a')).setAttachmentName(getAttachmentName(post.ContentFileName)).setLinkURL(getLinkURL(post.LinkUrl));
                    for (FeedComment comment : post.FeedComments) {
                        newPost.addComment(new ChatterPostComment(comment.CreatedBy.FirstName + ' ' + comment.CreatedBy.LastName, comment.CommentBody, comment.CreatedDate.format('MMMMMMMM dd, yyyy - hh:mm a'), comment.InsertedById));
                    }
                    for (FeedTrackedChange trackedChange : post.FeedTrackedChanges) {
                        newPost.addTrackedChange(new ChatterPostTrackedChange(trackedChange.FieldName, String.valueOf(trackedChange.OldValue), String.valueOf(trackedChange.NewValue)));
                    }
                    thePanel.childComponents.add(createChatterFeedItem(newPost));
                }
            } catch (Exception e) {
                System.debug(e);
                System.debug('AT LINE NUMBER: ' + e.getLineNumber());
                System.debug('STACK TRACE: ' + e.getStackTraceString());
                createErrorMessage('An invalid ID has been specified in the id URL paremeter.');
            }
        } else if (dateTimeParsingError) {
            System.debug('Invalid Date String: [ Start Date: ' + startDateRange + ',   End Date: ' + endDateRange + ' ]');
            createErrorMessage('Invalid Date String: [ Start Date: ' + startDateRange + ', End Date: ' + endDateRange + ' ]');
        } else {
            System.debug('The ID is null or blank');
            createErrorMessage('The record\'s id must be specified in the id URL parameter in order to view the Chatter posts on that record.');
        }
    }
    
    public String getAttachmentName(String attachmentNameOnFile) {
        if (al.StringUtils.isNotBlank(attachmentNameOnFile)) {
            return 'Attachment Name: ' + attachmentNameOnFile;
        }
        return null;
    }
    
    public String getLinkURL(String linkURLOnFile) {
        if (al.StringUtils.isNotBlank(linkURLOnFile)) {
            return 'Link URL: ' + linkURLOnFile;
        }
        return null;
    }
    
    public Component.Apex.OutputPanel createChatterFeedItem(ChatterPost post) {
        Component.Apex.OutputPanel newPost = new Component.Apex.OutputPanel();
        
        Component.Apex.OutputText postBody = new Component.Apex.OutputText();
        String photoURL = mapIdToUserPhotoThumb.get(post.posterID);
        if (al.StringUtils.isNotBlank(post.attachmentName) && al.StringUtils.isBlank(post.linkURL)) {
            postBody.value = '<div class="postDiv"><div class="postDivContent"><img src="' + photoURL + '" class="userPhoto"/><h2 class="userName">' + post.title + '</h2><br/>' + (post.body==null?'':post.body) + '<br/><h2>' + post.attachmentName + '</h2></div><div class="timeOfPostFeed"><h2>' + post.timeOfPost + '</h2></div></div>';
        } else if (al.StringUtils.isBlank(post.attachmentName) && al.StringUtils.isNotBlank(post.linkURL)) {
            postBody.value = '<div class="postDiv"><div class="postDivContent"><img src="' + photoURL + '" class="userPhoto"/><h2 class="userName">' + post.title + '</h2><br/>' + (post.body==null?'':post.body) + '<br/><h2>' + post.linkURL + '</h2></div><div class="timeOfPostFeed"><h2>' + post.timeOfPost + '</h2></div></div>';
        } else if (post.body == null) {
            String postBodyContent = 'changed ';
            for (Integer trackedChangeCounter = 0; trackedChangeCounter < post.trackedChanges.size(); trackedChangeCounter++) {
                ChatterPostTrackedChange trackedChange = post.trackedChanges.get(trackedChangeCounter);
                if (post.trackedChanges.size() > 1) {
                    if (trackedChangeCounter == post.trackedChanges.size() - 1) {
                        postBodyContent = postBodyContent.substring(0, postBodyContent.length() - 2);
                        postBodyContent += ', and ' + trackedChange.fieldName + ' from ' + trackedChange.oldValue + ' to ' + trackedChange.newValue + '.';
                    } else {
                        postBodyContent += trackedChange.fieldName + ' from ' + trackedChange.oldValue + ' to ' + trackedChange.newValue + ', ';
                    }
                } else {
                    postBodyContent += trackedChange.fieldName + ' from ' + trackedChange.oldValue + ' to ' + trackedChange.newValue + '.';
                }
            }

            postBody.value = '<div class="postDiv"><div class="postDivContent"><img src="' + photoURL + '" class="userPhoto"/><h2 class="userName">' + post.title + ' ' + postBodyContent + '</h2><br/>' + '</div><div class="timeOfPostFeed"><h2>' + post.timeOfPost + '</h2></div></div>';
        } else {
            postBody.value = '<div class="postDiv"><div class="postDivContent"><img src="' + photoURL + '" class="userPhoto"/><h2 class="userName">' + post.title + '</h2><br/>' + post.body + '</div><div class="timeOfPostFeed"><h2>' + post.timeOfPost + '</h2></div></div>';
        }
        postBody.escape = false;
        newPost.childComponents.add(postBody);
        
        for (ChatterPostComment comment : post.comments) {
            newPost.childComponents.add(createChatterFeedComment(comment));
        }
        
        newPost.style = 'padding: 5px;';
        return newPost;
    }
    
    public Component.Apex.OutputPanel createChatterFeedComment(ChatterPostComment comment) {
        Component.Apex.OutputPanel newComment = new Component.Apex.OutputPanel();
        String commentPhotoURL = mapIdToUserPhotoThumb.get(comment.posterID);
        Component.Apex.OutputText commentBody = new Component.Apex.OutputText();
        commentBody.value = '<div class="commentDiv"><div class="commentDivContent"><img src="' + commentPhotoURL + '" class="userPhoto"/><h2 class="userName">' + comment.posterName + '</h2><br/>' + comment.body + '</div><div class="timeOfPostComment"><h2>' + comment.timeOfPost + '</h2></div></div>';
        commentBody.escape = false;
        newComment.childComponents.add(commentBody);
        
        return newComment;
    }
    
    public void createErrorMessage(String errorMessage) {
        Component.Apex.OutputText errorText = new Component.Apex.OutputText();
        errorText.value = '<div class="errorMessage">' + errorMessage + '</div>';
        errorText.escape = false;
        thePanel.childComponents.add(errorText);
    }
    
    public class ChatterPost {
        public String title {get; set;}
        public String body {get; set;}
        public String attachmentName {get; set;}
        public String linkURL {get; set;}
        public String posterID {get; set;}
        public String timeOfPost {get; set;}
        public List<ChatterPostComment> comments {get; set;}
        public List<ChatterPostTrackedChange> trackedChanges {get; set;}
        
        public ChatterPost() {comments = new List<ChatterPostComment>(); trackedChanges = new List<ChatterPostTrackedChange>();}
        public ChatterPost(String title, String body, String timeOfPost) {
            this.title = title;
            this.body = body;
            comments = new List<ChatterPostComment>();
            trackedChanges = new List<ChatterPostTrackedChange>();
            this.timeOfPost = timeOfPost;
        }
        
        public ChatterPost setTitle(String title) {
            this.title = title;
            return this;
        }
        
        public ChatterPost setBody(String body) {
            this.body = body;
            return this;
        }
        
        public ChatterPost setPosterID(String id) {
            posterID = id;
            return this;
        }
        
        public ChatterPost addComment(ChatterPostComment comment) {
            comments.add(comment);
            return this;
        }

        public ChatterPost addTrackedChange(ChatterPostTrackedChange trackedChange) {
            trackedChanges.add(trackedChange);
            return this;
        }
        
        public ChatterPost setTimeOfPost(String timeOfPost) {
            this.timeOfPost = timeOfPost;
            return this;
        }
        
        public ChatterPost setAttachmentName(String attachmentName) {
            this.attachmentName = attachmentName;
            return this;
        }
        
        public ChatterPost setLinkURL(String linkURL) {
            this.linkURL = linkURL;
            return this;
        }
    }
    
    public class ChatterPostComment {
        public String posterName {get; set;}
        public String body {get; set;}
        public String timeOfPost {get; set;}
        public String posterID {get; set;}
        
        public ChatterPostComment() {}
        public ChatterPostComment(String posterName, String body, String timeOfPost, String posterID) {
            this.posterName = posterName;
            this.body = body;
            this.timeOfPost = timeOfPost;
            this.posterID = posterID;
        }
        
        public ChatterPostComment setPosterName(String posterName) {
            this.posterName = posterName;
            return this;
        }
        
        public ChatterPostComment setBody(String body) {
            this.body = body;
            return this;
        }
        
        public ChatterPostComment setTimeOfPost(String timeOfPost) {
            this.timeOfPost = timeOfPost;
            return this;
        }
        
        public ChatterPostComment setPosterId(String posterID) {
            this.posterID = posterID;
            return this;
        }
    }

    public class ChatterPostTrackedChange {
        public String oldValue {get; set;}
        public String newValue {get; set;}
        public String fieldName {get; set;}

        public ChatterPostTrackedChange() {}
        public ChatterPostTrackedChange(String fieldName, String oldValue, String newValue) {
            this.fieldName = fieldName;
            this.oldValue = oldValue;
            this.newValue = newValue;
        }

        public ChatterPostTrackedChange setFieldName(String fieldName) {
            this.fieldName = fieldName;
            return this;
        }

        public ChatterPostTrackedChange setOldValue(String oldValue) {
            this.oldValue = oldValue;
            return this;
        }

        public ChatterPostTrackedChange setNewValue(String newValue) {
            this.newValue = newValue;
            return this;
        }
    }
}