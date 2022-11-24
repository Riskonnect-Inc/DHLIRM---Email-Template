public class CreateReviewRecord {

    public static String hc_cs_flag_api {get; set;}

    public static String src_readyFlag_api {get; set;}
    public static String src_readyFlag_val {get; set;}
    public static String src_beenMadeFlag_api {get; set;}
    public static String src_hierarchy1_api {get; set;}
    public static String src_hierarchy2_api {get; set;}

    public static String hier_contact_api {get; set;}
    public static String hier_contact2_api {get; set;}
    public static String hier_contact3_api {get; set;}
    public static String hier_contact4_api {get; set;}
    public static String hier_contact5_api {get; set;}
    public static String hier_contact6_api {get; set;}

    public static String dst_object_api {get; set;}
    public static String dst_2_src_api {get; set;}
    public static String dst_2_hierContact_api {get; set;}

    public static void makeEventReview(){
        hc_cs_flag_api = 'pe_auto_create_review_records__c';
          src_readyFlag_api = 'im_status__c';
        src_readyFlag_val = 'Submitted';
        src_beenMadeFlag_api = 'review_record_s_auto_created__c';
        src_hierarchy1_api = 'primary_location__c';
        src_hierarchy2_api = 'secondary_location__c';
        hier_contact_api = 'department_manager__c';
        hier_contact2_api = 'Risk_Manager__c';
        hier_contact3_api = 'Patient_Safety_and_Quality__c';
        hier_contact4_api = 'Pharmacy__c';
        hier_contact5_api = 'Lab__c';
        hier_contact6_api = 'Director__c';
        dst_object_api = 'review__c';
        dst_2_src_api = 'patient_event__c';
        dst_2_hierContact_api = 'assigned_reviewer__c';

        make();

    }

    public static void makeFeedbackReview(){
        hc_cs_flag_api = 'pf_auto_create_review_records__c';
          src_readyFlag_api = 'im_status__c';
        src_readyFlag_val = 'Submitted';
        src_beenMadeFlag_api = 'review_record_s_auto_created__c';
        src_hierarchy1_api = 'primary_location__c';
        src_hierarchy2_api = 'secondary_location__c';
        hier_contact_api = 'department_manager__c';
        hier_contact2_api = 'Risk_Manager__c';
        hier_contact3_api = 'Patient_Safety_and_Quality__c';
        hier_contact4_api = 'Pharmacy__c';
        hier_contact5_api = 'Lab__c';
        hier_contact6_api = 'Director__c';
        dst_object_api = 'patient_feedback_review__c';
        dst_2_src_api = 'patient_feedback__c';
        dst_2_hierContact_api = 'assigned_reviewer__c';

        make();
    }

    public static void make(){
        HC_Custom_Settings__c  hcCS = HC_Custom_Settings__c.getInstance();
        if(hcCS!=null && hcCS.get(hc_cs_flag_api)!=null && (Boolean)hcCS.get(hc_cs_flag_api) && Trigger.isExecuting && Trigger.isBefore){
            sObject[] recs = Trigger.new;
            Set<String> location_Ids = new Set<String>();
            sObject[] reviews = new sObject[]{};
            for(sObject rec : recs){
                if((String)rec.get(src_readyFlag_api) == src_readyFlag_val && !((Boolean)rec.get(src_beenMadeFlag_api))){
                    if (rec.get(src_hierarchy1_api) != null){
                        location_Ids.add((String)rec.get(src_hierarchy1_api));
                    }
                    if (rec.get(src_hierarchy2_api) != null){
                        location_Ids.add((String)rec.get(src_hierarchy2_api));
                    }
                }
            }
            String[] fields = new String[]{hier_contact_api, hier_contact2_api, hier_contact3_api, hier_contact4_api, hier_contact5_api, hier_contact6_api};
            rkl__RK_Hierarchy_Node__c[] hNodeList = Database.query('SELECT id, '+String.join(fields,', ')+' FROM rkl__RK_Hierarchy_Node__c WHERE ID IN: location_Ids');
            Map<String,rkl__RK_Hierarchy_Node__c> hNodes = new Map<String,rkl__RK_Hierarchy_Node__c>(hNodeList);
            Schema.sObjectType reviewType = Schema.describeSObjects(new String[]{dst_object_api})[0].getSobjectType();
            for(sObject rec : recs){
                if((String)rec.get(src_readyFlag_api) == src_readyFlag_val && !((Boolean)rec.get(src_beenMadeFlag_api))){
                  for(String f : fields){
                    if (rec.get(src_hierarchy1_api) != null){
                        sObject review = reviewType.newSObject();
                        review.put(dst_2_src_api, rec.get('id'));
                        review.put(dst_2_hierContact_api, hNodes.get((String)rec.get(src_hierarchy1_api)).get(f));
                        if(hNodes.get((String)rec.get(src_hierarchy1_api)).get(f) != null){
                          reviews.add(review);
                          rec.put(src_beenMadeFlag_api, true);
                        }
                    }
                    if (rec.get('secondary_location__c') != null){
                        sObject review = reviewType.newSObject();
                        review.put(dst_2_src_api, rec.get('id'));
                        review.put(dst_2_hierContact_api, hNodes.get((String)rec.get(src_hierarchy2_api)).get(f));
                        if(hNodes.get((String)rec.get(src_hierarchy2_api)).get(f) != null){
                          reviews.add(review);
                          rec.put(src_beenMadeFlag_api, true);
                        }
                    }
                  }
                }
            }
            insert reviews;
        }
    }
}