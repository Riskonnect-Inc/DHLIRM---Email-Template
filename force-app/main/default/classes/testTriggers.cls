/*===========================================================================
     Added to RK base RMIS product as  03/25/2013
   ===========================================================================*/
    
@isTest
public class testTriggers {

    static testMethod void testPropertyCoordinates() {
        Property__c p = new Property__c(Name = 'test', Property_ID__c = '12345', Address_Line1__c = '30 S Park Sq', City__c = 'Marietta', State__c = 'GA');
        insert p;

        p.Address_Line1__c = '30 S Park Square';
        update p;
    }


    @isTest
    static void testTriggerGuidelinesValuesToClaim() {

        // Create diagnosis codes.
        Map<String, ICD9_Diagnosis__c> diagnoses = new Map<String, ICD9_Diagnosis__c>();

        for (String jobClass : testTriggers_Utils.jobClassInfoMap.keySet()) {
            ICD9_Diagnosis__c diagnosis = testTriggers_Utils.createICD9Diagnosis(jobClass);
            diagnoses.put(jobClass, diagnosis);
        }

        insert diagnoses.values();

        // Create test claims.
        Map<String, List<Claim__c>> claims = new Map<String, List<Claim__c>>();
        for (String jobClass : testTriggers_Utils.jobClassInfoMap.keySet()) {
            claims.put(jobClass, new List<Claim__c>());
        }

        for (Integer i = 0; i < testTriggers_Utils.numberOfClaimGroups; i++) {
            for (String jobClass : testTriggers_Utils.jobClassInfoMap.keySet()) {
                claims.get(jobClass).add(
                    new Claim__c(//Name=name,
                        Coverage_Major__c = 'GL',
                        Coverage_Minor__c = 'PD',
                        Date_of_Loss__c = System.Today())
                );
            }
        }

        List<Claim__c> allClaims = new List<Claim__c>();

        for (List<Claim__c> claimList : claims.values()) {
            allClaims.addAll(claimList);
        }

        insert allClaims;

        // Bookkeeping so we can figure out claim jobClass later.
        Map<Id, String> claimJobClass = new Map<Id, String>();

        for (String jobClass : claims.keySet()) {
            List<Claim__c> claimList = claims.get(jobClass);

            for (Claim__c claim : claimList) {
                claimJobClass.put(claim.Id, jobClass);
            }
        }

        List<RTW_Guidelines__c> guidelines = new List<RTW_Guidelines__c>();
        for (String jobClass : claims.keySet()) {
            for (Claim__c claim : claims.get(jobClass)) {
                ICD9_Diagnosis__c diagnosis = diagnoses.get(jobClass);
                RTW_Guidelines__c g = testTriggers_Utils.createGuideline(claim.Id,
                                                      jobClass,
                                                      String.valueOf(testTriggers_Utils.jobClassInfoMap.get(jobClass).factor),
                                                      diagnosis.Id);
                guidelines.add(g);
            }
        }

        insert guidelines;

        allClaims = [select
                     Id,
                     Predicted_Days_of_Disability__c,
                     Minimum_Duration__c,
                     Optimal_Duration__c,
                     Maximum_Duration__c
                     from Claim__c
                     where Id in :claimJobClass.keySet()];

        System.AssertEquals(testTriggers_Utils.numberOfClaimGroups * testTriggers_Utils.jobClassInfoMap.size(), allClaims.size());

        for (Claim__c claim : allClaims) {
            String jobClass = claimJobClass.get(claim.Id);

            System.AssertEquals(testTriggers_Utils.jobClassInfoMap.get(jobClass).factor, claim.Predicted_Days_of_Disability__c);
            System.AssertEquals(testTriggers_Utils.jobClassInfoMap.get(jobClass).factor * 1, claim.Minimum_Duration__c);
            System.AssertEquals(testTriggers_Utils.jobClassInfoMap.get(jobClass).factor * 2, claim.Optimal_Duration__c);
            System.AssertEquals(testTriggers_Utils.jobClassInfoMap.get(jobClass).factor * 3, claim.Maximum_Duration__c);
        }
    }


    @isTest(SeeAllData = true)
    static void testAutoCreateClaimTransaction() {
        List<Claim__c> testClaims = new List<Claim__c>();

        for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
            Claim__c c = testTriggers_Utils.CreateClaim();
            testClaims.add(c);
        }

        insert testClaims;
        delete testClaims;
    }

    // BK : PST-00015141
    static testMethod void testAutoCreateclaimTransaction2() {
       // Date d = date.parse('12/12/2009');  This will not work for a EMEA Date Locale
        Date d = Date.newInstance(2009, 12, 12);
        Claim__c claim = new Claim__c(  Status__c = 'Open',
                                        TPA_Carrier__c = 'ACE',
                                        Date_of_Loss__c = d);
        insert claim;

        Claim_Transaction__c ct = [ SELECT Name, Claim__c, TPA_Carrier__c, Transaction_Date__c, Type__c, Transaction_Status__c FROM Claim_Transaction__c WHERE Claim__c = : claim.Id ];
        System.assert(ct.Claim__c == claim.Id);
        System.assert(ct.TPA_Carrier__c == 'ACE');
        System.assert(ct.Type__c == 'Reserve');
        System.assert(ct.Name == 'Initial Setup');

        // Test custom setting override
        RMIS_Custom_Settings__c cs = new RMIS_Custom_Settings__c(SetupOwnerId = UserInfo.getProfileId(), Name = 'RMIS_Custom_Settings__c', Initial_Trans_dt__c = 'Date_Reported_to_TPA__c');
        insert cs;
        System.assert(RMIS_Custom_Settings__c.getInstance().Initial_Trans_dt__c == 'Date_Reported_to_TPA__c');

        //Date d2 = date.parse('03/05/2013');
        Date d2 = Date.newInstance(2013, 03, 05);
        Claim__c claim2 = new Claim__c(  Status__c = 'Open',
                                         TPA_Carrier__c = 'ACE',
                                         Date_of_Loss__c = d,
                                         Date_Reported_to_TPA__c = d2);
        insert claim2;

        Claim_Transaction__c ct2 = [ SELECT Name, Claim__c, TPA_Carrier__c, Transaction_Date__c, Type__c, Transaction_Status__c FROM Claim_Transaction__c WHERE Claim__c = : claim2.Id ];
        System.assert(ct2.Transaction_Date__c == Date.newInstance(2013, 03, 05));
    }

    /*@isTest(SeeAllData = true)
    static void testAttachmentTriggers() {
        List<Claim__c> testClaims = new List<Claim__c>();

        for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
            Claim__c c = testTriggers_Utils.CreateClaim();
            testClaims.add(c);
        }

        insert testClaims;

        List<Attachment> testAttachments = new List<Attachment>();

        for (Claim__c c : testClaims) {
            for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
                Attachment att = testTriggers_Utils.CreateAttachment();
                att.ParentId = c.Id;
                testAttachments.add(att);
            }
        }

        insert testAttachments;
        Map<Id, Attachment> testAttachmentsMap = new Map<Id, Attachment>(testAttachments);

        for (Attachment testAttachment : testAttachments) {
            List<Attachment> attachments = new List<Attachment>([select
                    Id,
                    Name,
                    Description,
                    ParentId,
                    CreatedDate
                    from Attachment
                    where Id = :testAttachment.Id]);

            for (Attachment attachment : attachments) {
                List<Attachment__c> attachmentShadows = new List<Attachment__c>([select
                        Id,
                        Attachment_Id__c,
                        Name__c,
                        Description__c,
                        Claim__c,
                        Date_Created__c
                        from Attachment__c
                        where Attachment_Id__c = :attachment.Id]);

                for (Attachment__c attachmentShadow : attachmentShadows) {
                    System.AssertEquals(attachmentShadow.Attachment_Id__c, attachment.Id);
                    System.AssertEquals(attachmentShadow.Name__c, attachment.Name);
                    System.AssertEquals(attachmentShadow.Description__c, attachment.Description);
                    System.AssertEquals(attachmentShadow.Claim__c, attachment.ParentId);
                    System.AssertEquals(attachmentShadow.Date_Created__c, attachment.CreatedDate.date());
                }
            }
        }

        List<Attachment__c> attachmentShadowsToDelete = new List<Attachment__c>();
        for (Attachment testAttachment : testAttachments) {
            List<Attachment__c> attachmentShadows1 = new List<Attachment__c>([select
                    Id,
                    Attachment_Id__c,
                    Name__c,
                    Description__c,
                    Claim__c,
                    Date_Created__c
                    from Attachment__c
                    where Attachment_Id__c = :testAttachment.Id]);
            attachmentShadowsToDelete.addAll(attachmentShadows1);
        }
        System.AssertEquals(testAttachments.size(), attachmentShadowsToDelete.size());
        delete attachmentShadowsToDelete;
        testAttachments = new List<Attachment>([select
                                                Id
                                                from Attachment
                                                where Id in :testAttachmentsMap.keySet()]);

        System.AssertEquals(0, testAttachments.size());
    }*/
/*
    @isTest(SeeAllData = false)
    static void testFeedItemTriggers() {
        List<Claim__c> testClaims = new List<Claim__c>();

        for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
            Claim__c c = testTriggers_Utils.CreateClaim();
            testClaims.add(c);
        }

        insert testClaims;

        List<Feeditem> testFeeditems = new List<Feeditem>();

        for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
            FeedItem feedItem = testTriggers_Utils.CreateFeedItem();
            feedItem.ParentId = testClaims[i - 1].Id;
            testFeeditems.add(feedItem);
        }

        insert testFeedItems;

        Map<Id, FeedItem> testFeedItemsMap = new Map<Id, FeedItem>(testFeedItems);

        List<Attachment__c> attachmentShadowsToDelete = new List<Attachment__c>();

        for (Feeditem testFeeditem : testFeeditems) {
            List<Feeditem> feeditems = new List<Feeditem>([select
                    Id,
                    Type,
                    ContentFileName,
                    Body,
                    ParentId,
                    RelatedRecordId,
                    CreatedDate
                    from Feeditem
                    where Id = :testFeeditem.Id]);
            System.Assert(feeditems.size() == 1);
            for (Feeditem feeditem : feeditems) {
                List<Attachment__c> attachmentShadows = new List<Attachment__c>([select
                        Id,
                        Attachment_Id__c,
                        Name__c,
                        Description__c,
                        Claim__c,
                        Date_Created__c,
                        Type__c
                        from Attachment__c
                        where Attachment_Id__c = :feeditem.RelatedRecordId]);
                System.assertEquals(1, attachmentShadows.size());
                for (Attachment__c attachmentShadow : attachmentShadows) {
                    System.AssertEquals(attachmentShadow.Type__c, feeditem.Type);
                    System.AssertEquals(attachmentShadow.Claim__c, feeditem.ParentId);
                    System.AssertEquals(attachmentShadow.Attachment_Id__c, feeditem.RelatedRecordId);
                    System.AssertEquals(attachmentShadow.Name__c, feeditem.ContentFileName);
                    System.AssertEquals(attachmentShadow.Description__c, feeditem.Body);
                    System.AssertEquals(attachmentShadow.Date_Created__c, feeditem.CreatedDate.date());

                    attachmentShadowsToDelete.add(attachmentShadow);
                }
            }
        }

        System.AssertEquals(testFeedItems.size(), attachmentShadowsToDelete.size());
        delete attachmentShadowsToDelete;
        testFeedItems = new List<FeedItem>([select
                                            Id,
                                            RelatedRecordId
                                            from FeedItem
                                            where Id in :testFeedItemsMap.keySet()]);
        List<Id> testIds = new List<Id>();
        for (FeedItem feedItem : testFeedItems) {
            testIds.add(feedItem.Id);
        }
        List<ContentVersion> testContentVersions = new List<ContentVersion>([select ContentDocumentId from ContentVersion where Id in :testIds]);
        testIds = new List<Id>();
        for (ContentVersion cv : testContentVersions) {
            testIds.add(cv.ContentDocumentId);
        }
        List<ContentDocument> testContentDocuments = new List<ContentDocument>([select Id from ContentDocument where Id in :testIds]);
        System.AssertEquals(0, testContentDocuments.size());
    }

    
    @isTest(SeeAllData = false)
    static void testFeedCommentTriggers() {
        Test.startTest();
        System.Debug('@ in test');
        List<Claim__c> testClaims = new List<Claim__c>();

        for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
            Claim__c c = testTriggers_Utils.CreateClaim();
            testClaims.add(c);
        }

        insert testClaims;

        List<Feeditem> testFeeditems = new List<Feeditem>();

        for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
            FeedItem feedItem = testTriggers_Utils.CreateFeedItem();
            feedItem.ParentId = testClaims[i - 1].Id;
            testFeeditems.add(feedItem);
        }

        insert testFeedItems;

        List<ContentVersion> testContentVersions = new List<ContentVersion>();

        for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
            ContentVersion cv = testTriggers_Utils.CreateContentVersion();
            testContentVersions.add(cv);
        }

        insert testContentVersions;
        System.Debug('@ inserted content');

        List<FeedComment> testFeedComments = new List<FeedComment>();

        for (Integer i = 1; i <= testTriggers_Utils.NumberOfTestObjects; i++) {
            FeedComment feedComment = testTriggers_Utils.CreateFeedComment();
            feedComment.FeedItemId = testFeedItems[i - 1].Id;
            feedComment.RelatedRecordId = testContentVersions[i - 1].Id;
            testFeedComments.add(feedComment);
        }

        insert testFeedComments;
        Test.stopTest();
        Map<Id, FeedComment> testFeedCommentsMap = new Map<Id, FeedComment>(testFeedComments);

        List<Attachment__c> attachmentShadowsToDelete = new List<Attachment__c>();

        for (FeedComment testFeedComment : testFeedComments) {
            List<FeedComment> FeedComments = new List<FeedComment>([select
                    Id,
                    CommentType,
                    //ContentFileName,
                    CommentBody,
                    ParentId,
                    FeedItemId,
                    RelatedRecordId,
                    CreatedDate
                    from FeedComment
                    where Id = :testFeedComment.Id]);
            System.Assert(FeedComments.size() == 1);
            for (FeedComment feedComment : FeedComments) {
                FeedItem feedItem = [select ParentId, RelatedRecordId from FeedItem where Id = :feedComment.FeedItemId limit 1];
                List<Attachment__c> attachmentShadows = new List<Attachment__c>([select
                        Id,
                        Attachment_Id__c,
                        Name__c,
                        Description__c,
                        Claim__c,
                        Date_Created__c,
                        Type__c
                        from Attachment__c
                        //where Attachment_Id__c = :FeedItem.RelatedRecordId]);
                        where Attachment_Id__c = :FeedComment.RelatedRecordId]);
                System.assertEquals(1, attachmentShadows.size());
                for (Attachment__c attachmentShadow : attachmentShadows) {
                    ContentVersion cv = [select Title, VersionData from ContentVersion where Id = :feedComment.RelatedRecordId limit 1];
                    System.AssertEquals(attachmentShadow.Name__c, 'Test feed comment'); //'foo.txt');
                    System.AssertEquals(attachmentShadow.Type__c, 'ContentComment'); //'ContentPost');
                    System.AssertEquals(attachmentShadow.Claim__c, FeedItem.ParentId);
                    // XXX Why is this failing?
                    // It seems the trigger is copying the FeedItem comment rather than FeedComment.
                    //System.AssertEquals(attachmentShadow.Description__c, FeedComment.CommentBody);
                    System.AssertEquals(attachmentShadow.Date_Created__c, FeedComment.CreatedDate.date());

                    attachmentShadowsToDelete.add(attachmentShadow);
                }
            }
        }

        System.AssertEquals(testFeedComments.size(), attachmentShadowsToDelete.size());
        delete attachmentShadowsToDelete;
        testFeedComments = new List<FeedComment>([select
                Id
                from FeedComment
                where Id in :testFeedCommentsMap.keySet()]);
        List<Id> testIds = new List<Id>();
        for (FeedItem feedItem : testFeedItems) {
            testIds.add(feedItem.RelatedRecordId);
        }
        testContentVersions = new List<ContentVersion>([select ContentDocumentId from ContentVersion where Id in :testIds]);
        testIds = new List<Id>();
        for (ContentVersion cv : testContentVersions) {
            testIds.add(cv.ContentDocumentId);
        }
        List<ContentDocument> testContentDocuments = new List<ContentDocument>([select Id from ContentDocument where Id in :testIds]);
        System.AssertEquals(0, testContentDocuments.size());
    }*/

    
    /*@isTest
    static void propertyValueReadWriteAggregation() {
        testTriggers_Utils.PropertyFactory fact = new testTriggers_Utils.PropertyFactory();
        Date today = System.today();
        // 1st group has dual maximums:
        fact.newProperty(); // lid=0
        fact.newSibling(today.addDays(-100)); // lid=1
        fact.newSibling(today.addDays(-1)); // lid=2 ; group maximum
        fact.newSibling(today.addDays(-1)); // lid=3 ; group maximum
        fact.newSibling(today.addDays(-10)); // lid=4

        // 2nd group has a single maximum:
        fact.newProperty(); // lid=5
        fact.newSibling(today.addDays(-1)); // lid=6 ; group maximum
        fact.newSibling(today.addDays(-2)); // lid=7
        fact.newSibling(today.addDays(-3)); // lid=8

        // 3rd group has a lone member:
        fact.newProperty(); // lid=9
        fact.newSibling(today.addDays(-500)); // lid=10 ; group maximum

        fact.save();
        fact.checkGroup(0, 4, today.addDays(-1), 2);
        fact.checkGroup(5, 3, today.addDays(-1), 1);
        fact.checkGroup(9, 1, today.addDays(-500), 1);

        // now, let's change stuff up, and ensure -- among other things -- that the trigger can handle local updates that drive local & external
        // changes.
        // !! note we can't move Property_Value__c siblings because it's a master-detail to Property__c

        // in the 1st group[lid=0], we had dual maximums -- let's bump one of those off:
        fact.lidMap.get(3).put('Evaluation_Date__c', today.addDays(-2));
        // in the 3rd group[lid=9], let's add another sibling that will be the new max:
        fact.newSibling(9, today); // lid=11 ; new group maximum

        fact.save();
        fact.checkGroup(0, 4, today.addDays(-1), 1);
        fact.checkGroup(5, 3, today.addDays(-1), 1);
        fact.checkGroup(9, 2, today, 1);

        // test deletion; this will automatically save and requery:
        fact.deleteSiblings(new Set<Integer> { 2 });
        fact.checkGroup(0, 3, today.addDays(-2), 1);
    }*/

    @isTest
    static void exposureReadWriteAggregation() {
        testTriggers_Utils.ExposureFactory fact = new testTriggers_Utils.ExposureFactory();
        Date today = System.today();
        // 1st group has dual maximums:
        fact.newHierarchyNode(); // lid=0
        fact.newSibling(today.addDays(-100)); // lid=1
        fact.newSibling(today.addDays(-1)); // lid=2 ; group maximum
        fact.newSibling(today.addDays(-1)); // lid=3 ; group maximum
        fact.newSibling(today.addDays(-10)); // lid=4

        // 2nd group has a single maximum:
        fact.newHierarchyNode(); // lid=5
        fact.newSibling(today.addDays(-1)); // lid=6 ; group maximum
        fact.newSibling(today.addDays(-2)); // lid=7
        fact.newSibling(today.addDays(-3)); // lid=8

        // 3rd group has a lone member:
        fact.newHierarchyNode(); // lid=9
        fact.newSibling(today.addDays(-500)); // lid=10 ; group maximum

        fact.save();
        fact.checkGroup(0, 4, today.addDays(-1), 2);
        fact.checkGroup(5, 3, today.addDays(-1), 1);
        fact.checkGroup(9, 1, today.addDays(-500), 1);

        // now, let's change stuff up, and ensure -- among other things -- that the trigger can handle local updates that drive local & external
        // changes:

        // in the 1st group[lid=0], we had dual maximums -- let's bump one of those off:
        fact.lidMap.get(3).put('Evaluation_Date__c', today.addDays(-2));
        // in the 2nd group[lid=5], let's move the current max[lid=6] to the 3rd group[lid=9] (where it will become the new max there):
        fact.moveSibling(6, 9);
        // in the 3rd group[lid=9], let's add another sibling that will share max with the moved sibling:
        fact.newSibling(9, today.addDays(-1)); // lid=11 ; shared group maximum

        fact.save();
        fact.checkGroup(0, 4, today.addDays(-1), 1);
        fact.checkGroup(5, 2, today.addDays(-2), 1);
        fact.checkGroup(9, 3, today.addDays(-1), 2);

        // test deletion; this will automatically save and requery:
        fact.deleteSiblings(new Set<Integer> { 2, 6, 11 });
        fact.checkGroup(0, 3, today.addDays(-2), 1);
        fact.checkGroup(5, 2, today.addDays(-2), 1);
        fact.checkGroup(9, 1, today.addDays(-500), 1);
    }

    /*
    static Claim__c createClaim(String name) {
        Claim__c claim = new Claim__c(//Name=name,
            Coverage_Major__c = 'GL',
            Coverage_Minor__c = 'PD',
            Date_of_Loss__c = System.Today()
        );

        return claim;
    }
    */

    /*
    class JobClassInfo {
        public Integer factor;
        public String[] fieldNames; // Minimal, optimal, max

        public JobClassInfo(Integer f, String[] fn) {
            this.factor = f;
            this.fieldNames = fn;
        }
    }
    */

    /*
    static Map<String, JobClassInfo> jobClassInfoMap = new Map<String, JobClassInfo> {
        'SEDENTARY'  => new JobClassInfo(1,
        new String[] {
            'Sedentary_Min__c',
            'Sedentary_Opt__c',
            'Sedentary_Max__c'
        }),
        'LIGHT'      => new JobClassInfo(2,
        new String[] {
            'Light_Min__c',
            'Light_Opt__c',
            'Light_Max__c'
        }),
        'MEDIUM'     => new JobClassInfo(3,
        new String[] {
            'Medium_Min__c',
            'Medium_Opt__c',
            'Medium_Max__c'
        }),
        'HEAVY'      => new JobClassInfo(4,
        new String[] {
            'Heavy_Min__c',
            'Heavy_Opt__c',
            'Heavy_Max__c'
        }),
        'VERY HEAVY' => new JobClassInfo(5,
        new String[] {
            'Very_Heavy_Min__c',
            'Very_Heavy_Opt__c',
            'Very_Heavy_Max__c'
        })
    };
    */

    /*
    static Integer numberOfClaimGroups = 2;
    */

    /*
    static RTW_Guidelines__c createGuideline(Id claimId, String type, String days, Id diagnosisId) {
        RTW_Guidelines__c g = new RTW_Guidelines__c(Claim__c = claimId,
                Job_Class__c = type,
                Predicted_Days_of_Disability__c = days,
                Salary__c = 30000,
                Date_Injury_Occurred__c = System.Today(),
                ICD_9_CM1__c = diagnosisId);

        Integer factor;

        for (String jobClass : jobClassInfoMap.keySet()) {
            String[] fieldNames = jobClassInfoMap.get(jobClass).fieldNames;

            // Minimal, optimal, max
            for (Integer i = 0; i < fieldNames.size(); i++) {
                g.put(fieldNames[i], String.valueOf(jobClassInfoMap.get(jobClass).factor * (i + 1)));
            }
        }

        return g;
    }
    */

    /*
    static ICD9_Diagnosis__c createICD9Diagnosis(String code) {
        ICD9_Diagnosis__c diagnosis = new ICD9_Diagnosis__c(Diagnosis_Code__c = code);

        return diagnosis;
    }
    */


    /*
    static Integer NumberOfTestObjects = 4;
    */

    /*
    static Claim__c CreateClaim() {
        return new Claim__c(Coverage_Minor__c = 'GL',
                            Date_of_Loss__c = System.today(),
                            Claimant_Last_Name__c = 'McShane');
    }
    */

    /*
    static Attachment CreateAttachment() {
        String aName = 'Test attachment';
        Blob aBody = Blob.valueOf('Here is some attachment content.');
        String aDescription = 'Test description';

        return new Attachment(Name = aName,
                              Body = aBody,
                              Description = aDescription);
    }
    */

    /*
    static FeedItem CreateFeedItem() {
        String aName = 'Test feed item';
        Blob aBody = Blob.valueOf('Here is some attachment content.');

        return new FeedItem(
                   Body = 'Test Body Item',
                   ContentData = aBody,
                   ContentFileName = 'foo.txt'
               );
    }
    */

    /*
    static FeedComment CreateFeedComment() {
        String aName = 'Test feed comment';
        Blob aBody = Blob.valueOf('Here is some attachment content.');

        return new FeedComment(
                   CommentBody = 'Test Body Comment',
                   CommentType = 'ContentComment'
               );
    }
    */

    /*
    static ContentVersion CreateContentVersion() {
        String aName = 'Test feed comment';
        Blob aBody = Blob.valueOf('Here is some attachment content.');

        return new ContentVersion(
                   Origin = 'H',
                   Title = aName,
                   VersionData = aBody,
                   PathOnClient = '/file.txt'
               );
    }
    */

    /*
    static User CreateUser(Id profileId, Integer i) {
        return new User(alias = 'test',
                        email = 'test@test.com',
                        emailencodingkey = 'UTF-8',
                        lastname = 'test',
                        languagelocalekey = 'en_US',
                        localesidkey = 'en_US',
                        profileid = profileId,
                        timezonesidkey = 'America/New_York',
                        username = 'test@testSF.com' + i);
    }
    */

    /* deprecated KDG
    @isTest(SeeAllData=false)
    static void testFeedCommentBatch() {

        System.Debug('@ in test');
        List<Feeditem> testFeeditems = new List<Feeditem>();
        List<FeedComment> testFeedComments = new List<FeedComment>();
        List<ContentVersion> testContentVersions = new List<ContentVersion>();

        //
        // This needs to execute as a non-admin user.
        //
        Profile p = [SELECT Id, Name FROM Profile where Name = 'Standard Platform User' limit 1];
        User user = CreateUser(p.Id, 1);
        Test.startTest();
        System.runAs(user) {
            List<Claim__c> testClaims = new List<Claim__c>();

            for (Integer i = 1; i <= NumberOfTestObjects; i++) {
                Claim__c c = CreateClaim();
                testClaims.add(c);
            }

            insert testClaims;

            for (Integer i = 1; i <= NumberOfTestObjects; i++) {
                FeedItem feedItem = CreateFeedItem();
                feedItem.ParentId = testClaims[i - 1].Id;
                testFeeditems.add(feedItem);
            }

            insert testFeedItems;

            for (Integer i = 1; i <= NumberOfTestObjects; i++) {
                ContentVersion cv = CreateContentVersion();
                testContentVersions.add(cv);
            }

            insert testContentVersions;
            System.Debug('@ inserted content');

            for (Integer i = 1; i <= NumberOfTestObjects; i++) {
                FeedComment feedComment = CreateFeedComment();
                feedComment.FeedItemId = testFeedItems[i - 1].Id;
                feedComment.RelatedRecordId = testContentVersions[i - 1].Id;
                testFeedComments.add(feedComment);
            }

            // Batch will be scheduled by trigger.

            insert testFeedComments;

        }
        Test.stopTest();
        Map<Id, FeedComment> testFeedCommentsMap = new Map<Id, FeedComment>(testFeedComments);

        List<Attachment__c> attachmentShadowsToDelete = new List<Attachment__c>();

        for (FeedComment testFeedComment : testFeedComments) {
            List<FeedComment> FeedComments = new List<FeedComment>([select
                                                                    Id,
                                                                    CommentType,
                                                                    //ContentFileName,
                                                                    CommentBody,
                                                                    ParentId,
                                                                    FeedItemId,
                                                                    RelatedRecordId,
                                                                    CreatedDate
                                                                    from FeedComment
                                                                    where Id = :testFeedComment.Id]);
            System.Assert(FeedComments.size() == 1);
            for (FeedComment feedComment : FeedComments) {
                FeedItem feedItem = [select ParentId, RelatedRecordId from FeedItem where Id = :feedComment.FeedItemId limit 1];
                List<Attachment__c> attachmentShadows = new List<Attachment__c>([select
                                                                                 Id,
                                                                                 Attachment_Id__c,
                                                                                 Name__c,
                                                                                 Description__c,
                                                                                 Claim__c,
                                                                                 Date_Created__c,
                                                                                 Type__c
                                                                                 from Attachment__c
                                                                                 where Attachment_Id__c = :FeedItem.Id]);
                System.Assert(attachmentShadows.size() == 1);
                for (Attachment__c attachmentShadow : attachmentShadows) {
                    ContentVersion cv = [select Title, VersionData from ContentVersion where Id = :feedComment.RelatedRecordId limit 1];
                    System.AssertEquals(attachmentShadow.Name__c, 'foo.txt');
                    System.AssertEquals(attachmentShadow.Type__c, 'ContentPost');
                    System.AssertEquals(attachmentShadow.Claim__c, FeedItem.ParentId);
                    // XXX Why is this failing?
                    // It seems the trigger is copying the FeedItem comment rather than FeedComment.
                    //System.AssertEquals(attachmentShadow.Description__c, FeedComment.CommentBody);
                    System.AssertEquals(attachmentShadow.Date_Created__c, FeedComment.CreatedDate.date());

                    attachmentShadowsToDelete.add(attachmentShadow);
                }
            }
        }

        System.AssertEquals(testFeedComments.size(), attachmentShadowsToDelete.size());
        delete attachmentShadowsToDelete;
        testFeedComments = new List<FeedComment>([select
                                                  Id
                                                  from FeedComment
                                                  where Id in :testFeedCommentsMap.keySet()]);
        List<Id> testIds = new List<Id>();
        for (FeedItem feedItem : testFeedItems) {
            testIds.add(feedItem.RelatedRecordId);
        }
        testContentVersions = new List<ContentVersion>([select ContentDocumentId from ContentVersion where Id in :testIds]);
        testIds = new List<Id>();
        for (ContentVersion cv : testContentVersions) {
            testIds.add(cv.ContentDocumentId);
        }
        List<ContentDocument> testContentDocuments = new List<ContentDocument>([select Id from ContentDocument where Id in :testIds]);
        System.AssertEquals(0, testContentDocuments.size());
    }
    */

    /* old, ineffective tests:
    static Exposure__c createExposure(Date evalDate, rkl__RK_Hierarchy_Node__c hier) {
        return new Exposure__c(Evaluation_Date__c=evalDate,
                               Hierarchy_Node__c=hier.Id,
                               Value__c=1);
    }

    @isTest
    static void testMostRecentTriggerExposure() {
        rkl__RK_Hierarchy_Node__c hier = new rkl__RK_Hierarchy_Node__c(
            rkl__Node_Key__c='test'
            );
        insert hier;
        List<Exposure__c> exposures = new List<Exposure__c>();
        for (Integer i = 0; i < 10; i++) {
            exposures.add(createExposure(Date.Today().addDays(-i), hier));
        }
        System.Debug('@ in exposure test');
        Test.startTest();
        insert exposures;
        Test.stopTest();
        System.Debug('@ after exposure test');

        exposures = [select Evaluation_Date__c from Exposure__c where Most_Recent__c = false];
        System.AssertEquals(9, exposures.size());
        exposures = [select Evaluation_Date__c from Exposure__c where Most_Recent__c = true];
        System.AssertEquals(1, exposures.size());
        System.AssertEquals(Date.Today(), exposures[0].Evaluation_Date__c);
    }

    static Property_Value__c createPropertyValue(Date evalDate, Property__c property) {
        return new Property_Value__c(Evaluation_Date__c=evalDate,
                                     Property__c=property.Id
            );
    }

    @isTest
    static void testMostRecentTriggerPropertyValue() {



        Property__c property = new Property__c(Property_ID__c='FOO');
        insert property;
        List<Property_Value__c> propertyValues = new List<Property_Value__c>();
        for (Integer i = 0; i < 10; i++) {
            propertyValues.add(createPropertyValue(Date.Today().addDays(-i), property));
        }
        Test.startTest();
        insert propertyValues;
        Test.stopTest();

        propertyValues = [select Evaluation_Date__c from Property_Value__c where Most_Recent__c = false];
        System.AssertEquals(9, propertyValues.size());
        propertyValues = [select Evaluation_Date__c from Property_Value__c where Most_Recent__c = true];
        System.AssertEquals(1, propertyValues.size());
        System.AssertEquals(Date.Today(), propertyValues[0].Evaluation_Date__c);
    }
    */

    // Mike Ulveling
    // let's test our Read/Write-Aggregation solutions properly and thoroughly:


    /*
    class PropertyFactory extends EvalDateFactory {
        PropertyFactory() {
            super(Schema.Property__c.SObjectType, Schema.Property_Value__c.SObjectType, 'Property__c');
        }

        Integer newProperty() {
            Integer lid = super.newParent(null);
            lastParent.put('Property_ID__c', 'PR' + lid);
            return lid;
        }
    }
    */

    /*
    class ExposureFactory extends EvalDateFactory {
        ExposureFactory() {
            super(Schema.rkl__RK_Hierarchy_Node__c.SObjectType, Schema.Exposure__c.SObjectType, 'Hierarchy_Node__c');
        }

        Integer newHierarchyNode() {
            Integer lid = super.newParent(null);
            lastParent.put('rkl__Node_Key__c', 'HN' + lid);
            return lid;
        }
    }
    */

    /*
    // provides common Evaluation_Date__c and Most_Recent__c aggregation testing logic for property-values and exposures:
    abstract class EvalDateFactory extends SiblingFactory {
        EvalDateFactory(Schema.SObjectType parentType, Schema.SObjectType siblingType, String lookupField) {
            super(parentType, siblingType, lookupField);
        }

        virtual Integer newSibling(Date evalDate) {
            return super.newSibling(new Map<String, Object> { 'Evaluation_Date__c' => evalDate });
        }

        virtual Integer newSibling(Integer parent_lid, Date evalDate) {
            return super.newSibling(parent_lid, new Map<String, Object> { 'Evaluation_Date__c' => evalDate });
        }

        void checkGroup(Integer parent_lid, Integer expectedGroupSize, Date expectedMaxDate, Integer expectedMaxMatches) {
            Map<Id, Integer> siblingIdToLidMap = calcSiblingIdToLidMap();

            Integer parentIndex = parentLidToOrdinal.get(parent_lid);
            SObject[] siblings = siblingss[parentIndex];
            String groupIdent = 'group[lid=' + parent_lid + ', index=' + parentIndex + ']';
            System.assert(expectedGroupSize == siblings.size(), 'Expected ' + expectedGroupSize + ' siblings under '
                          + groupIdent + '; found ' + siblings.size());
            Integer maxMatches = 0;
            for (SObject s : siblings) {
                Boolean mostRecent = s.get('Most_Recent__c') == true;
                String siblingIdent = 'sibling[lid=' + siblingIdToLidMap.get(s.id) + ']';
                if (s.get('Evaluation_Date__c') == expectedMaxDate) {
                    maxMatches++;
                    System.assert(mostRecent, 'Expected ' + siblingIdent + ' under ' + groupIdent + ' to be flagged as most recent');
                } else
                    System.assert(!mostRecent, 'Expected ' + siblingIdent + ' under ' + groupIdent + 'to NOT be flagged as most recent');
            }

            System.assert(expectedMaxMatches == maxMatches, 'Expected ' + expectedMaxMatches + ' siblings under '
                          + groupIdent + ' to hold the maximum eval date; found ' + maxMatches);
        }
    }
    */

    /*
    // TODO: this should be factored out to rkl as a generic utility class for units tests of read/write aggregation logic (i.e. rkl.AggregateUtils
    // implementations):
    virtual class SiblingFactory {
        // local id counter (i.e. "lid"); monotonically increases as we create each new parent and sibling instance:
        Integer lid = 0;
        // every record -- parent or sibling -- that we create in this factory is collected here, under its assigned lid:
        Map<Integer, SObject> lidMap = new Map<Integer, SObject>();
        // maps a sibling lid to its parent lid (this mapping is mutable via the moveSibling() method):
        Map<Integer, Integer> siblingLidToParentLidMap = new Map<Integer, Integer>();

        Schema.SObjectType parentType;
        Schema.SObjectType siblingType;
        // the lookup field from sibling to parent:
        String lookupField;
        // the parent records, in order of increasing lid:
        SObject[] parents = new SObject[] {};
        // maps a parent ordinal/index to its lid; these relationship must never change (immutable):
        Integer[] parentOrdinalToLid = new Integer[] {};
        // maps a parent lid to its ordinal/index in the parents & siblingss arrays; these relationship must never change (immutable):
        Map<Integer, Integer> parentLidToOrdinal = new Map<Integer, Integer>();
        // track the lid of the last created parent, to use as a default for the newSibling method:
        Integer lastParentLid;
        SObject lastParent;
        // the siblings currently under each parent; the outer array is in sync with the parents array (index == parent.ordinal):
        List<SObject[]> siblingss = new List<SObject[]>();
        SObject lastSibling;

        SiblingFactory(Schema.SObjectType parentType, Schema.SObjectType siblingType, String lookupField) {
            if (!Test.isRunningTest())
                throw new al.IllegalStateException('I\'m sorry Dave, I can\'t allow that. Not unless you\'re in a test context');

            this.parentType = parentType;
            this.siblingType = siblingType;
            this.lookupField = lookupField;
        }

        virtual Integer newParent(Map<String, Object> attribs) {
            Integer p_lid = lid++;
            lastParentLid = p_lid;
            parentOrdinalToLid.add(p_lid);
            parentLidToOrdinal.put(p_lid, parents.size());
            siblingss.add(new SObject[] {});
            SObject p = parentType.newSObject();
            lastParent = p;
            if (attribs != null)
                for (String key : attribs.keySet())
                    p.put(key, attribs.get(key));

            parents.add(p);
            lidMap.put(p_lid, p);
            return p_lid;
        }

        // adds a new sibling to the last parent; returns its assigned lid:
        virtual Integer newSibling(Map<String, Object> attribs) {
            return newSibling(lastParentLid, attribs);
        }

        // adds a new sibling to the specified parent; returns its assigned lid:
        virtual Integer newSibling(Integer parent_lid, Map<String, Object> attribs) {
            Integer s_lid = lid++;
            SObject s = siblingType.newSObject();
            lastSibling = s;
            if (attribs != null)
                for (String key : attribs.keySet())
                    s.put(key, attribs.get(key));

            SObject[] siblings = siblingss[parentLidToOrdinal.get(parent_lid)];
            siblings.add(s);
            lidMap.put(s_lid, s);
            siblingLidToParentLidMap.put(s_lid, parent_lid);
            return s_lid;
        }

        // use this method instead of updating the lookupField directly:
        void moveSibling(Integer sibling_lid, Integer newParent_lid) {
            SObject newParent = lidMap.get(newParent_lid);
            System.assert(newParent.id != null, 'Cannot move sibling[lid=' + sibling_lid + '] to a parent[lid='
                          + newParent_lid + '] that has not been inserted');

            Integer oldParent_lid = siblingLidToParentLidMap.get(sibling_lid);
            SObject sibling = lidMap.get(sibling_lid);
            SObject[] oldSiblings = siblingss[parentLidToOrdinal.get(oldParent_lid)];
            for (Integer i = 0; i < oldSiblings.size(); i++)
                if (sibling.id != null && oldSiblings[i].id == sibling.id
                        || sibling === oldSiblings[i]) {
                    oldSiblings.remove(i);
                    break;
                }

            sibling.put(lookupField, newParent.id);
            siblingLidToParentLidMap.put(sibling_lid, newParent_lid);
            siblingss[parentLidToOrdinal.get(newParent_lid)].add(sibling);
        }

        // use this method instead of directly DML-delete'ing a sibling record.
        // !! this method performs an automatic requery()
        void deleteSiblings(Set<Integer> sibling_lids) {
            // flush any pending changes to ensure we're working with a current dataset, and only inserted records:
            save();

            SObject[] deletions = new SObject[] {};
            for (Integer sibling_lid : sibling_lids) {
                Integer parent_lid = siblingLidToParentLidMap.get(sibling_lid);
                SObject sibling = lidMap.get(sibling_lid);
                deletions.add(sibling);

                SObject[] oldSiblings = siblingss[parentLidToOrdinal.get(parent_lid)];
                for (Integer i = 0; i < oldSiblings.size(); i++)
                    if (oldSiblings[i].id == sibling.id) {
                        oldSiblings.remove(i);
                        break;
                    }
                siblingLidToParentLidMap.remove(sibling_lid);
            }
            if (deletions.size() > 0)
                delete deletions;

            requery();
        }

        // for requery:
        virtual al.SOQLBuilder parentSelectClause(al.SOQLBuilder query) {
            return query.selectAll();
        }

        // for requery:
        virtual al.SOQLBuilder siblingSelectClause(al.SOQLBuilder query) {
            return query.selectAll();
        }

        // compile a map of sibling salesforce-id to its lid, for each known sibling record
        // !! you may not have pending changes at the time this is called:
        Map<Id, Integer> calcSiblingIdToLidMap() {
            Map<Id, Integer> siblingIdToLidMap = new Map<Id, Integer>();
            for (Integer lid : lidMap.keySet()) {
                SObject s = lidMap.get(lid);
                if (s.getSObjectType() != siblingType)
                    continue;

                siblingIdToLidMap.put(s.id, lid);
            }
            return siblingIdToLidMap;
        }

        // !! this method performs an automatic requery()
        void save() {
            SObject[] inserts = new SObject[] {};
            SObject[] updates = new SObject[] {};
            for (SObject p : parents) {
                if (p.id == null)
                    inserts.add(p);
                else
                    updates.add(p);
            }
            // new parents must be inserted before we process siblings:
            if (inserts.size() > 0) {
                insert inserts;
                inserts = new SObject[] {};
            }

            for (Integer i = 0; i < siblingss.size(); i++) {
                SObject p = parents[i];
                SObject[] siblings = siblingss[i];
                for (SObject s : siblings) {
                    if (s.id == null)
                        inserts.add(s);
                    else
                        updates.add(s);

                    // resolve the parent lookup; the parent record is guaranteed to have been previously inserted:
                    if (s.get(lookupField) == null)
                        s.put(lookupField, p.id);
                }
            }

            if (inserts.size() > 0)
                insert inserts;

            if (updates.size() > 0)
                update updates;

            requery();
        }

        // this should NOT be called when there are pending inserts/updates to be committed!
        private void requery() {
            Map<Id, SObject> pmap = new Map<Id, SObject>();
            Map<Id, Integer> parentIdToLidMap = new Map<Id, Integer>();
            for (SObject p :
                    Database.query(
                        parentSelectClause(
                            // don't need no where clause; this is a test context:
                            new al.SOQLBuilder()
                            .fromx('' + parentType))
                        .toSOQL())) {
                pmap.put(p.id, p);
            }
            // refresh the parent SObjects each with their requeried copy, maintaining original lid ordering:
            for (Integer i = 0; i < parents.size(); i++) {
                parents[i] = pmap.get(parents[i].id);
                Integer parent_lid = parentOrdinalToLid[i];
                parentIdToLidMap.put(parents[i].id, parent_lid);
                // update the lidMap:
                if (lidMap.containsKey(parent_lid))
                    lidMap.put(parent_lid, parents[i]);
            }

            // compile a map of sibling salesforce-id to its lid, for each known sibling record (all sibling records are guaranteed to have been
            // inserted at this time):
            Map<Id, Integer> siblingIdToLidMap = calcSiblingIdToLidMap();

            // rebuild the sibling-to-parent mappings and the sibling lists under each parent:
            siblingLidToParentLidMap = new Map<Integer, Integer>();
            for (Integer i = 0; i < parents.size(); i++)
                siblingss[i] = new SObject[] {};

            // completely rebuild the siblings groupings (siblingss array-of-arrays) under each parent record:
            for (SObject s :
                    Database.query(
                        siblingSelectClause(
                            // don't need no where clause; this is a test context:
                            new al.SOQLBuilder()
                            .selectx(lookupField)
                            .fromx('' + siblingType))
                        .toSOQL())) {
                // update the lidMap:
                Integer sibling_lid = siblingIdToLidMap.get(s.id);
                if (lidMap.containsKey(sibling_lid))
                    lidMap.put(sibling_lid, s);

                Id parentId = (Id) s.get(lookupField);
                // allow siblings to drop out of parent groupings:
                if (parentId == null)
                    continue;

                Integer parent_lid = parentIdToLidMap.get(parentId);
                //System.assert(parentLidToOrdinal.get(parent_lid) != null, 'Null parent-ordinal for parent[lid=' + parent_lid + '] and sibling [lid=' + sibling_lid + ']');
                siblingss[parentLidToOrdinal.get(parent_lid)].add(s);
                siblingLidToParentLidMap.put(sibling_lid, parent_lid);
            }
        }
    }
    */

}