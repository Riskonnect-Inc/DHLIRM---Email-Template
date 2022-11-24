/*===========================================================================
     Added to RK base RMIS product as  2/04/2014
   ===========================================================================*/
    
public class testTriggers_Utils {
    /*
    public static Claim__c createClaim(String name) {
        Claim__c claim = new Claim__c(//Name=name,
            Coverage_Major__c = 'GL',
            Coverage_Minor__c = 'PD',
            Date_of_Loss__c = System.Today()
        );

        return claim;
    }
*/

    public class JobClassInfo {
        public Integer factor;
        public String[] fieldNames; // Minimal, optimal, max

        public JobClassInfo(Integer f, String[] fn) {
            this.factor = f;
            this.fieldNames = fn;
        }
    }

    public static Map<String, JobClassInfo> jobClassInfoMap = new Map<String, JobClassInfo> {
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

    public static Integer numberOfClaimGroups = 2;

    public static RTW_Guidelines__c createGuideline(Id claimId, String type, String days, Id diagnosisId) {
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

    public static ICD9_Diagnosis__c createICD9Diagnosis(String code) {
        ICD9_Diagnosis__c diagnosis = new ICD9_Diagnosis__c(Diagnosis_Code__c = code);

        return diagnosis;
    }

    public static Integer NumberOfTestObjects = 4;

    public static Claim__c CreateClaim() {
        return new Claim__c(Coverage_Minor__c = 'GL',
                            Date_of_Loss__c = System.today(),
                            Claimant_Last_Name__c = 'McShane');
    }

    public static Attachment CreateAttachment() {
        String aName = 'Test attachment';
        Blob aBody = Blob.valueOf('Here is some attachment content.');
        String aDescription = 'Test description';

        return new Attachment(Name = aName,
                              Body = aBody,
                              Description = aDescription);
    }

    public static FeedItem CreateFeedItem() {
        String aName = 'Test feed item';
        Blob aBody = Blob.valueOf('Here is some attachment content.');

        return new FeedItem(
                   Body = 'Test Body Item',
                   ContentData = aBody,
                   ContentFileName = 'foo.txt'
               );
    }

    public static FeedComment CreateFeedComment() {
        String aName = 'Test feed comment';
        Blob aBody = Blob.valueOf('Here is some attachment content.');

        return new FeedComment(
                   CommentBody = 'Test Body Comment',
                   CommentType = 'ContentComment'
               );
    }

    public static ContentVersion CreateContentVersion() {
        String aName = 'Test feed comment';
        Blob aBody = Blob.valueOf('Here is some attachment content.');

        return new ContentVersion(
                   Origin = 'H',
                   Title = aName,
                   VersionData = aBody,
                   PathOnClient = '/file.txt'
               );
    }
/*
    public static User CreateUser(Id profileId, Integer i) {
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


    public class PropertyFactory extends EvalDateFactory {
        public PropertyFactory() {
            super(Schema.Property__c.SObjectType, Schema.Property_Value__c.SObjectType, 'Property__c');
        }

        public Integer newProperty() {
            Integer lid = super.newParent(null);
            lastParent.put('Property_ID__c', 'PR' + lid);
            return lid;
        }
    }

    public class ExposureFactory extends EvalDateFactory {
        public ExposureFactory() {
            super(Schema.rkl__RK_Hierarchy_Node__c.SObjectType, Schema.Exposure__c.SObjectType, 'Hierarchy_Node__c');
        }

        public Integer newHierarchyNode() {
            Integer lid = super.newParent(null);
            lastParent.put('rkl__Node_Key__c', 'HN' + lid);
            return lid;
        }
    }

    public abstract class EvalDateFactory extends SiblingFactory {
        public EvalDateFactory(Schema.SObjectType parentType, Schema.SObjectType siblingType, String lookupField) {
            super(parentType, siblingType, lookupField);
        }

        public virtual Integer newSibling(Date evalDate) {
            return super.newSibling(new Map<String, Object> { 'Evaluation_Date__c' => evalDate });
        }

        public virtual Integer newSibling(Integer parent_lid, Date evalDate) {
            return super.newSibling(parent_lid, new Map<String, Object> { 'Evaluation_Date__c' => evalDate });
        }

        public void checkGroup(Integer parent_lid, Integer expectedGroupSize, Date expectedMaxDate, Integer expectedMaxMatches) {
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


    // TODO: this should be factored out to rkl as a generic utility class for units tests of read/write aggregation logic (i.e. rkl.AggregateUtils
    // implementations):
    public virtual class SiblingFactory {
        // local id counter (i.e. "lid"); monotonically increases as we create each new parent and sibling instance:
        public Integer lid = 0;
        // every record -- parent or sibling -- that we create in this factory is collected here, under its assigned lid:
        public Map<Integer, SObject> lidMap = new Map<Integer, SObject>();
        // maps a sibling lid to its parent lid (this mapping is mutable via the moveSibling() method):
        public Map<Integer, Integer> siblingLidToParentLidMap = new Map<Integer, Integer>();

        public Schema.SObjectType parentType;
        public Schema.SObjectType siblingType;
        // the lookup field from sibling to parent:
        public String lookupField;
        // the parent records, in order of increasing lid:
        public SObject[] parents = new SObject[] {};
        // maps a parent ordinal/index to its lid; these relationship must never change (immutable):
        public Integer[] parentOrdinalToLid = new Integer[] {};
        // maps a parent lid to its ordinal/index in the parents & siblingss arrays; these relationship must never change (immutable):
        public Map<Integer, Integer> parentLidToOrdinal = new Map<Integer, Integer>();
        // track the lid of the last created parent, to use as a default for the newSibling method:
        public Integer lastParentLid;
        public SObject lastParent;
        // the siblings currently under each parent; the outer array is in sync with the parents array (index == parent.ordinal):
        public List<SObject[]> siblingss = new List<SObject[]>();
        public SObject lastSibling;

        public SiblingFactory(Schema.SObjectType parentType, Schema.SObjectType siblingType, String lookupField) {
            if (!Test.isRunningTest())
                throw new al.IllegalStateException('I\'m sorry Dave, I can\'t allow that. Not unless you\'re in a test context');

            this.parentType = parentType;
            this.siblingType = siblingType;
            this.lookupField = lookupField;
        }

        public virtual Integer newParent(Map<String, Object> attribs) {
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
        public virtual Integer newSibling(Map<String, Object> attribs) {
            return newSibling(lastParentLid, attribs);
        }

        // adds a new sibling to the specified parent; returns its assigned lid:
        public virtual Integer newSibling(Integer parent_lid, Map<String, Object> attribs) {
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
        public void moveSibling(Integer sibling_lid, Integer newParent_lid) {
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
        public void deleteSiblings(Set<Integer> sibling_lids) {
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
        public virtual al.SOQLBuilder parentSelectClause(al.SOQLBuilder query) {
            return query.selectAll();
        }

        // for requery:
        public virtual al.SOQLBuilder siblingSelectClause(al.SOQLBuilder query) {
            return query.selectAll();
        }

        // compile a map of sibling salesforce-id to its lid, for each known sibling record
        // !! you may not have pending changes at the time this is called:
        public Map<Id, Integer> calcSiblingIdToLidMap() {
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
        public void save() {
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
}