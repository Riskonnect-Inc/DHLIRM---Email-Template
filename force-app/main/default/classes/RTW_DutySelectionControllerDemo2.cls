/*===========================================================================
     Added to RK base RMIS product as 4/15/2016
    ===========================================================================*/
    
global class RTW_DutySelectionControllerDemo2{
    
    public Id assessmentId{get;set;}
    public RTW_Assessment__c thisAssessment {get;set;}
    public RTW_Duty__c custDuty {get; set;}
    public String custDutyId {get;set;}
    public static List<String> idValues {get;set;}
    
    @RemoteAction
    public static Boolean save(Id assessment,RTW_Duty__c cust){
        try {  
            insert cust;            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error creating new Record.'));
            return false;
        }
        RTW_Assessment__c rtw =[SELECT Custom_Duty_ID__c FROM RTW_Assessment__c WHERE id= :assessment];
        if(rtw.Custom_Duty_ID__c != null){
            rtw.Custom_Duty_ID__c = rtw.Custom_Duty_ID__c +','+ cust.Id ;
            update rtw;
        }
        else{
            rtw.Custom_Duty_ID__c = cust.Id;
            update rtw;
        }
        return true;
    }
    
    
    public void save() {
        try {  
            insert custDuty;
            if(custDutyId != null){
                custDutyId=custDutyId +','+custDuty.Id;
            }
            else
                custDutyId = custDuty.Id;
            system.debug('SRS cust id = '+custDutyId);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error creating new Record.'));
            // return null;
        }
        custDuty= new RTW_Duty__c();
        // PageReference savePage= new PageReference('/apex/RTW_DutySelection_New?id='+thisAssessment.Id);
        // savePage.setRedirect(false);
        //return savePage;
        // return null;
    }
    
    public PageReference cancelGoBack(){
        PageReference pg = new PageReference('/'+thisAssessment.Id);
        pg.setRedirect(True);
        return pg;
    }
    
    public PageReference saveAssessment(){
        update thisAssessment;
        return null;
    }
    
    public RTW_DutySelectionControllerDemo2(ApexPages.StandardController sc){
        custDuty= new RTW_Duty__c(); 
        assessmentId = ((RTW_Assessment__c)sc.getRecord()).Id;
        if(assessmentId != null){
            RTW_Assessment__c rtw =[SELECT Standing__c,Date_Assignment_Ends__c ,Date_Assignment_Begins__c ,Sitting__c,Kneeling_Squatting__c,Pushing_Pulling__c,Twisting__c, 
                                    Walking__c,Stair_Ladder_Climbing__c,Grasping_Squeezing__c,Reaching__c,Keyboarding__c,Bending_Stooping__c,Wrist_Flexion_Extension__c FROM RTW_Assessment__c
                                    WHERE id= :assessmentId limit 1];
            thisAssessment = rtw;
        }  
        
    }
    
    @RemoteAction
    public static List<Map<string, Object>> getFieldsInFieldSetForPicklist(String fieldSetName, String ObjectName)
    {
        
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(ObjectName);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        List<String> labelList = new List<String>();
        
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        
        List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList)
        {
            if(fieldSetMemberObj.getType() == schema.displaytype.picklist){
                labelList.add(fieldSetMemberObj.getfieldPath());
            }    
        }
        List<Map<string, Object>> itemMeta = new List<Map<String, Object>>();
        for(String item : labelList){
            itemMeta.add(new Map<String, Object>{'Path' => item,'Label' => fieldMap.get(item).getDescribe().getLabel(), 'Picklist' => getPicklistValues(ObjectName,item)});
        }
        system.debug(itemMeta);
        return itemMeta;
    }
    
    public static List<String> getPicklistValues(String ObjectApi_name,String Field_name){ 
        
        List<String> lstPickvals=new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues();
        
        for (Schema.PicklistEntry a : pick_list_values) {
            lstPickvals.add(a.getLabel());
        }
        return lstPickvals;
    }
    
    @RemoteAction
    public static string getRTWDuty(Id assessmentId){
        /* grabbing describe info for labels */
        List<String> dutyIds = new List<String>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get('RTW_Duty__c');
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        /* grabbing records that need to be returned */
        RTW_Assessment__c assess = [SELECT Id, Name,Custom_Duty_ID__c,
                                    Sitting__c, Standing__c, Kneeling_Squatting__c, Pushing_Pulling__c, Twisting__c,
                                    Walking__c, Stair_Ladder_Climbing__c, Grasping_Squeezing__c, Reaching__c, Overhead_Reaching__c, Keyboarding__c, Wrist_Flexion_Extension__c
                                    FROM RTW_Assessment__c 
                                    WHERE id =: assessmentId];
        
        
        List<RTW_Duty__c> dutyList =  [SELECT Id, Name, RTW_Duty_Description__c,
                                       Sitting__c, Standing__c, Kneeling_Squatting__c, Pushing_Pulling__c, Twisting__c,
                                       Walking__c, Stair_Ladder_Climbing__c, Grasping_Squeezing__c, Reaching__c, Overhead_Reaching__c, Keyboarding__c, Wrist_Flexion_Extension__c
                                       FROM RTW_Duty__c
                                       WHERE Approved__c='Approved' ];
        if(assess.Custom_Duty_ID__c != null && assess.Custom_Duty_ID__c != ''){
            dutyIds = assess.Custom_Duty_ID__c.split(',');
            if(dutyIds.size() >0){
                for(RTW_Duty__c d :[SELECT Id, Name, RTW_Duty_Description__c,
                                    Sitting__c, Standing__c, Kneeling_Squatting__c, Pushing_Pulling__c, Twisting__c,
                                    Walking__c, Stair_Ladder_Climbing__c, Grasping_Squeezing__c, Reaching__c, Overhead_Reaching__c, Keyboarding__c, Wrist_Flexion_Extension__c
                                    FROM RTW_Duty__c
                                    WHERE id = :dutyIds])
                {
                    dutyList.add(d);
                }
            }
        }                 
        /* variables for generating data to be returned */
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<String> labelList = new List<String>{'Standing__c', 'Sitting__c', 'Kneeling_Squatting__c', 'Pushing_Pulling__c', 'Twisting__c', 'Walking__c', 'Stair_Ladder_Climbing__c', 'Grasping_Squeezing__c', 'Reaching__c', 'Keyboarding__c', 'Overhead_Reaching__c', 'Wrist_Flexion_Extension__c'};
            
            for(RTW_Duty__c duty : dutyList){
                List<Map<string, Object>> itemMeta = new List<Map<String, Object>>();
                for(String item : labelList){
                    itemMeta.add(new Map<String, Object>{'Label' => fieldMap.get(item).getDescribe().getLabel(), 'Category' => isTrue(item, (String)duty.get(item), (String)assess.get(item)), 'Hours' => (duty.get(item) == null ? 0:duty.get(item))});
                }
                Integer catCount = 0 ;
                for(Map<String,object> mapobject : itemMeta){            
                    for(String str : mapobject.keyset()){
                        if(str.contains('Category')){                    
                            if(String.valueof(mapobject.get(Str)).contains('slds-theme--success')) catCount ++ ;                        
                        }                  
                    }             
                }        
                String dutyId =duty.id;
                Boolean val = false;
                for(Integer i=0;i<dutyIds.size();i++){
                    if(assess.Custom_Duty_ID__c != '' && assess.Custom_Duty_ID__c != null && dutyId.contains(dutyIds[i])) val = true;
                }
                result.add(new Map<String, Object>{'Id' => duty.id, 'Name' => duty.name, 'Description' => duty.RTW_Duty_Description__c, 'Selected' => val, 'Attributes' => itemMeta, 'Count'=> catCount });     
            }  
        System.debug(result);                         
        return JSON.serialize(result);
    }
    
    @RemoteAction
    public static String getFieldsInFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, String> result = new Map<String, String>();
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        
        List<Schema.FieldSetMember> fieldSetMemberList =  fieldSetObj.getFields();
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList)
        {
            result.put(fieldSetMemberObj.getFieldPath(), fieldSetMemberObj.getLabel());       
        }
        system.debug('json serialize-->' + JSON.serializePretty(result));
        return JSON.serializePretty(result);
    }  
    
    
    @RemoteAction
    public static String getPostureFieldsAndValues(String assessmentId){
        RTW_Assessment__c rtw =[SELECT Standing__c,Sitting__c,Kneeling_Squatting__c,Pushing_Pulling__c,Twisting__c, Bending_Stooping__c FROM RTW_Assessment__c
                           WHERE id= :assessmentId limit 1];
       
        Map<String, Object> result = new Map<String, Object>();
        result.put('Standing', rtw.standing__c);
        result.put('Sitting', rtw.sitting__c);
        result.put('Kneeling', rtw.kneeling_squatting__c);
        result.put('Pushing', rtw.pushing_pulling__c);
        result.put('Twisting', rtw.twisting__c);
        result.put('Bending',rtw.Bending_Stooping__c);

        return JSON.serialize(result);
    }
    
    @RemoteAction
     public static String getMotionFieldsAndValues(String assessmentId){
       RTW_Assessment__c rtw =[SELECT Walking__c,Stair_Ladder_Climbing__c,Grasping_Squeezing__c,Reaching__c,Keyboarding__c,Overhead_Reaching__c,Wrist_Flexion_Extension__c FROM RTW_Assessment__c
                           WHERE id= :assessmentId limit 1];
       
       Map<String, Object> result = new Map<String, Object>();
       result.put('Walking', rtw.walking__c);
       result.put('Climbing', rtw.stair_ladder_climbing__c);
       result.put('Grasping', rtw.grasping_squeezing__c);
       result.put('Reaching', rtw.reaching__c);
       result.put('Keyboarding', rtw.keyboarding__c);
       // result.put('Overhead Reaching', rtw.overhead_reaching__c);
       result.put('Wrist Flexion', rtw.wrist_flexion_extension__c);
       
       return JSON.serialize(result);
     }
     
    @RemoteAction
    public static string getRTWDuty(Id assessmentId, String newDutyId){
        /* grabbing describe info for labels */
        List<String> dutyIds = newDutyId.split(',');
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get('RTW_Duty__c');
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

        /* grabbing records that need to be returned */
        RTW_Assessment__c assess = [SELECT Id, Name,
                                  Sitting__c, Standing__c, Kneeling_Squatting__c, Pushing_Pulling__c, Twisting__c, Bending_Stooping__c,
                                  Walking__c, Stair_Ladder_Climbing__c, Grasping_Squeezing__c, Reaching__c, Overhead_Reaching__c, Keyboarding__c, Wrist_Flexion_Extension__c
                                  FROM RTW_Assessment__c 
                                  WHERE id =: assessmentId];
                                    
        List<RTW_Duty__c> dutyList =  [SELECT Id, Name, RTW_Duty_Description__c,
                                    Sitting__c, Standing__c, Kneeling_Squatting__c, Pushing_Pulling__c, Twisting__c, Bending_Stooping__c,
                                    Walking__c, Stair_Ladder_Climbing__c, Grasping_Squeezing__c, Reaching__c, Overhead_Reaching__c, Keyboarding__c, Wrist_Flexion_Extension__c
                                    FROM RTW_Duty__c
                                    WHERE Approved__c='Approved' ];
        if(newDutyId != null && newDutyId != ''){
        if(dutyIds.size() >0){
        for(RTW_Duty__c d :[SELECT Id, Name, RTW_Duty_Description__c,
                                        Sitting__c, Standing__c, Kneeling_Squatting__c, Pushing_Pulling__c, Twisting__c, Bending_Stooping__c,
                                        Walking__c, Stair_Ladder_Climbing__c, Grasping_Squeezing__c, Reaching__c, Overhead_Reaching__c, Keyboarding__c, Wrist_Flexion_Extension__c
                                        FROM RTW_Duty__c
                                        WHERE id = :dutyIds])
                                        {
            dutyList.add(d);
            }
        }
       }                       
        /* variables for generating data to be returned */
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        List<String> labelList = new List<String>{'Standing__c', 'Sitting__c', 'Kneeling_Squatting__c', 'Pushing_Pulling__c', 'Twisting__c', 'Bending_Stooping__c', 'Walking__c', 'Stair_Ladder_Climbing__c', 'Grasping_Squeezing__c', 'Reaching__c', 'Keyboarding__c', 'Wrist_Flexion_Extension__c'};
        
        for(RTW_Duty__c duty : dutyList){
            List<Map<string, Object>> itemMeta = new List<Map<String, Object>>();
            for(String item : labelList){
                  itemMeta.add(new Map<String, Object>{'Label' => fieldMap.get(item).getDescribe().getLabel(), 'Category' => isTrue(item, (String)duty.get(item), (String)assess.get(item)), 'Hours' => (duty.get(item) == null ? 0:duty.get(item))});
            }
            Integer catCount = 0 ;
            for(Map<String,object> mapobject : itemMeta){            
                for(String str : mapobject.keyset()){
                    if(str.contains('Category')){                    
                        if(String.valueof(mapobject.get(Str)).contains('slds-theme--success')) catCount ++ ;                        
                    }                  
                }             
            }        
          String dutyId =duty.id;
          Boolean val = false;
          for(Integer i=0;i<dutyIds.size();i++){
          if(newDutyId != '' && newDutyId != null && dutyId.contains(dutyIds[i])) val = true;
        }
          result.add(new Map<String, Object>{'Id' => duty.id, 'Name' => duty.name, 'Description' => duty.RTW_Duty_Description__c, 'Selected' => val, 'Attributes' => itemMeta, 'Count'=> catCount });     
        }  
        System.debug(result);                         
        return JSON.serialize(result);
    }
      
  @RemoteAction
  public static string isTrue(string property, String hour, String AssessHour){
    if(AssessHour != null && (AssessHour == 'Not Restricted' || AssessHour == 'NA' || AssessHour >= hour)) {
        return 'slds-theme--success';
    }
        return 'slds-theme--error';
  }

    @RemoteAction
    public static void saveSelectedDuties(string thisAssessment,List<String> jsonString) {
        List<RTW_Assignment__c> assignmentsToCreate = new List<RTW_Assignment__c>();
        for(String str : jsonString){
            assignmentsToCreate.add(new RTW_Assignment__c(RTW_Assessment__c = thisAssessment, RTW_Duty__c = str, Hours_per_Shift__c = null));
        }
        System.debug(' Json Array--'+jsonString);
        System.debug('Assessment --'+thisAssessment);
        system.debug('assignmentsToCreate = '+assignmentsToCreate.size()+'  '+assignmentsToCreate);
  
            insert assignmentsToCreate;
       
       // update thisAssessment;
       // update thisAssessment;
        
        /*PageReference pg = new PageReference('/'+thisAssessment.Id);
        pg.setRedirect(true);
        return pg;*/
       // return null;
  
    }
  
}