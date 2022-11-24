global class ChangeStatus_Controller {
    
    @AuraEnabled
    global static  Map<String,String> getApiInfo(Id recId) {        
        final Schema.sObjectType sobjType = recId.getSObjectType();
        String pickField;
        if (sobjType == Schema.Patient_Satisfaction__c.sObjectType) {
            pickField = 'Status_of_Complaint__c';
        } else if (sobjType == Schema.Patient_Event__c.sObjectType) {
            pickField = 'Patient_Event_Status__c';
        // Peer_Review__c, Root_Cause_Analysis__c, <default>:
        } else {
            pickField = 'Status__c';
        }
        return new Map<String,String> {
            'picklistField' => pickField,
            'objectName' => '' + sobjType
        };
    }
    
    @AuraEnabled
    global static Map<String, string> getPicklistValues(String ObjectApi, String fieldName) { 
        final Map<String, string> pickVals = new Map<String, string>();
        final Schema.sObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi);
        final Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        for (Schema.PicklistEntry pe : fieldMap.get(fieldName).getDescribe().getPickListValues()) {
            pickVals.put(pe.getLabel(),pe.getValue());
        }
        return pickVals;
    }

    static final Map<Schema.sObjectType, String> CloseFieldByType = new Map<Schema.sObjectType, String>{
        Schema.Peer_Review__c.sObjectType => 'Date_Closed__c',
        Schema.Patient_Event__c.sObjectType => 'Date_Event_Closed__c',
        Schema.Root_Cause_Analysis__c.sObjectType => 'Date_Completed__c',
        Schema.Patient_Satisfaction__c.sObjectType => 'Date_Closed__c'
    };

    /* MDU May 3, 2018 - Minor rewites for code cleanup
     *
     * recId - Id of the record requesting a status update
     * objName - Redundant parameter; the recId also determines the target sObjectType
     * fldName - The status field to be updated
     * stautsVal - The new status value to be written into the status field
     */
    @AuraEnabled
    global static void updateObject(String recId, String objName, String fldName, String statusVal) {
        final Id targetId = (Id) recId;
        final Schema.sObjectType targetType = targetId.getSObjectType();
        final String closeDateField = CloseFieldByType.get(targetType);
        final Set<String> sels = new Set<String>{ fldName.toLowerCase() };
        if (closeDateField != null) {
            sels.add(closeDateField.toLowerCase());
        }
        final Boolean isPatientSat = targetType == Schema.Patient_Satisfaction__c.sObjectType;
        if (isPatientSat) {
            sels.add('date_resolved__c');
        }
        sObject updateSobj = Database.query(
                'SELECT ' + String.join(new List<String>(sels), ',') + 
                ' FROM ' + targetType + 
                ' WHERE Id = :targetId' + 
                ' FOR UPDATE');
        Object currStatus = updateSobj.get(fldName);
        // nothing to do if the current status is already set to the requested status:
        if (currStatus == statusVal) {
            return;
        }
        updateSobj.put(fldName, statusVal);
        if (isPatientSat && statusVal != null && statusVal.startsWithIgnoreCase('Closed')) {
            updateSobj.put('Date_Closed__c', Date.today());
            if (statusVal == 'Closed - Resolved') {
                updateSobj.put('Feedback_Resolved__c', true);
                if (updateSobj.get('Date_Resolved__c') == null) {
                    updateSobj.put('Date_Resolved__c', Date.today());
                }
            }
        } else if ((statusVal == 'Closed' || statusVal == 'Complete') && closeDateField != null) {
            updateSobj.put(closeDateField, Date.today());
        }
        update updateSobj;
    }
    
    @AuraEnabled
    global static String getCurrentUserProfile() {
        return [ SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId() ].Name;
    }
    
    @AuraEnabled
    global static Boolean getSelfAdmin(Id claimId) { 
        return [ SELECT Self_Administered__c FROM Claim__c WHERE Id = :claimId ].Self_Administered__c == true;
    }
    
    @AuraEnabled
    global static List<String> getAccessiblePicklistValues() {
        List<String> accessiblePicklistVal = new List<String>();
        RMISPersonalSettings__c cs = RMISPersonalSettings__c.getInstance(UserInfo.getProfileId());
        if (cs != null) {
            if (cs.Allow_Convert_to_Claim__c == true) { 
                accessiblePicklistVal.add('Open');
            }
            if (cs.Allow_Close__c == true) {
                accessiblePicklistVal.add('Closed');
            }
            if (cs.Allow_Reopen__c == true) {
                accessiblePicklistVal.add('Reopen');
            }
            if (cs.Allow_Void__c == true) {
                accessiblePicklistVal.add('Void');
            }
        }
        return accessiblePicklistVal;
    }

    @AuraEnabled
    global static RMIS_Custom_Settings__c preventStatusChange() {    
        return RMIS_Custom_Settings__c.getInstance(UserInfo.getProfileId());
    }
    
    @AuraEnabled
    global static RMISPersonalSettings__c getPersonalSettings() { 
        return RMISPersonalSettings__c.getInstance(UserInfo.getProfileId());
    }

    @AuraEnabled
    global static Claim__c getClaim(Id claimId) {
        return [ 
            SELECT Self_Administered__c, Status__c, Expense_Outstanding__c, Indemnity_PD_Outstanding__c, Medical_BI_Outstanding__c, 
                (SELECT Transaction_Date__c FROM Claim_Transaction__r ORDER BY Transaction_Date__c DESC LIMIT 1) 
            FROM Claim__c 
            WHERE Id = :claimId ];
    }

    @AuraEnabled
    global static Map<String,String> getClaimHardCode() { 
        ChangeStatusHardCode__c[] hardCodes = [ 
            SELECT Name, Close_Claim_Field__c, Open_Claim_Field__c, Reopen_Claim_Field__c, Void_Claim_Field__c
            FROM ChangeStatusHardCode__c 
            WHERE Name = 'ChangeClaimStatus' LIMIT 1 ];
        if (hardCodes.isEmpty()) {
            return new Map<String, String>();
        } else {
            ChangeStatusHardCode__c hc = hardCodes[0];
            return new Map<String, String> {
                'Open' => hc.Open_Claim_Field__c,
                'Closed' => hc.Close_Claim_Field__c,
                'Reopen' => hc.Reopen_Claim_Field__c,
                'Void' => hc.Void_Claim_Field__c
            };
        }
    }
    
    @AuraEnabled
    global static void updateClaim(String status, String transDate, Claim__c claim, Boolean isClose,Id claimId){
        List<String> claimFieldList = new List<string>();
        
        Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('claim__c').getDescribe().fields.getMap();
        List<String> lstfieldname = new List<String>();
        for(String field : fieldMap.keySet()){          
            lstfieldname.add(field);
        }
        Map<String,String> fldSetMap = new Map<String,String> {'Open' => 'Open_Claim_Field_Set', 'Reopen' => 'Reopen_Claim_Field_Set','Closed' => 'Closed_Claim_Field_Set','Void' => 'Void_Claim_Field_Set'};
            Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType sObjectTypeObj = globalDescribeMap.get('Claim__c');
        Schema.DescribeSObjectResult describeSObjectResultObj = sObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = describeSObjectResultObj.FieldSets.getMap().get(fldSetMap.get(status));
        List<Schema.FieldSetMember> fieldSetMemberList = fieldSetObj.getFields();
        String claimQuery = 'Select ';
        if(fieldSetMemberList != null){
            for(Schema.FieldSetMember fld : fieldSetMemberList){
                claimQuery +=  fld.getFieldPath() + ',';
                claimFieldList.add(fld.getFieldPath());
            }
        }
        claimQuery += 'Id,Status__c,Expense_Outstanding__c,Indemnity_PD_Outstanding__c,Medical_BI_Outstanding__c,(SELECT ID, Transaction_Date__c FROM Claim_Transaction__r ORDER BY Transaction_Date__c DESC LIMIT 1) FROM Claim__c WHERE Id=:claimId LIMIT 1 FOR UPDATE';
        Claim__c clm = Database.query(claimQuery);
        clm.status__c = status;
        if(claimFieldList != null){
            for(String fld : claimFieldList){
                clm.put(fld,claim.get(fld));
            }
        }
        Map<String,String> mapHardCodes = getClaimHardCode();
        Date enteredDate = (mapHardCodes.get(status) != null && lstfieldname.contains(mapHardCodes.get(status).toLowerCase()) && claim.get(mapHardCodes.get(status)) != null)?Date.valueOf(claim.get(mapHardCodes.get(status))): null;
        if(mapHardCodes.get(status) != null && claim != null && enteredDate != null && clm.Claim_Transaction__r != null && clm.Claim_Transaction__r[0].Transaction_Date__c != null && (enteredDate < clm.Claim_Transaction__r[0].Transaction_Date__c)){
            string transactionDate = (clm.Claim_Transaction__r[0].Transaction_Date__c != null)?string.valueOf(clm.Claim_Transaction__r[0].Transaction_Date__c).substring(0,10): null;
            String errorMsg = status +' date must be >= '+ transactionDate;
            throw new AuraHandledException(errorMsg);
        }
        UPDATE clm;
        Map<String, String> claimTransRecordTypeMap = new Map<String, String>();
        claimTransRecordTypeMap = new Map<String, String>();
        List<RecordType> recordTypes = [SELECT ID, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = 'Claim_Transaction__c'];
        
        for (RecordType recordType : recordTypes) {
            claimTransRecordTypeMap.put(recordType.DeveloperName, recordType.Id);
        }
        if(status != 'void'){
            claim_transaction__c trans = new claim_transaction__c();
            
            trans.put('Transaction_Date__c',Date.valueOf(transDate));
            trans.put('Claim__c',claimId);
            trans.Approval_Status__c = 'Approved';
            trans.Type__c = 'Reserve';
            trans.Category__c = 'Status Change';
            if(status == 'Open'){
                trans.Name = 'Incident to Claim Transaction';
                trans.Transaction_Status__c = 'Open';
                trans.Amount__c = 0.00;
                trans.RecordTypeId = claimTransRecordTypeMap.get('Reserve');
            }
            else if(status == 'Closed'){
                trans.Name = 'Claim Closed Set Incurred Equal to Paid';
                trans.Transaction_Status__c = 'Closed';
                // MDU June 12, 2018 - the Claim's Outstanding rollup totals need to be zeroed by inserting a closing transaction with Incurred amounts set to each of the 
                // current Outstanding total's negations; prior code was not performing negation, thereby erroneously increasing the new Outstanding totals:
                trans.Expense_Reserve_Delta__c = clm.Expense_Outstanding__c != null ? -clm.Expense_Outstanding__c : null;
                trans.Indemnity_PD_Reserve_Delta__c = clm.Indemnity_PD_Outstanding__c != null ? -clm.Indemnity_PD_Outstanding__c : null;
                trans.Medical_BI_Reserve_Delta__c = clm.Medical_BI_Outstanding__c != null ? -clm.Medical_BI_Outstanding__c : null;
                trans.RecordTypeId = claimTransRecordTypeMap.get('Transaction_Entry');
            }
            if(status == 'Reopen'){
                trans.Name = 'Claim Reopen Transaction';
                trans.Transaction_Status__c = 'Reopen';
                trans.Amount__c = 0.00;
                trans.RecordTypeId = claimTransRecordTypeMap.get('Reserve');
            }
            insert trans;
        }
        
        if(isClose){
            String uid = UserInfo.getUserId();
            Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            List<User> admin = [SELECT id, Email FROM User WHERE ProfileId = :adminProfile.Id];
            List<Task> updatetasks = new List<Task>();
            List<Task> openTasks = [SELECT ID,OwnerId FROM Task WHERE WhatId =:claimId AND Status != 'Completed'];
            
            if (openTasks.size() > 0) {
                for (Task task : openTasks) {
                    if((uid != admin[0].id) && (task.OwnerId == uid)){
                        task.Status = 'Completed';
                        updatetasks.add(task);
                    }//admin
                    else if( (uid == admin[0].id)) {
                        task.Status = 'Completed';
                        updatetasks.add(task);
                    }
                }
                update updatetasks;
            }
        }
    }
    
    @AuraEnabled
    global static Map<String, List<Map<String,String>>> getLayoutFields() {
        Map<String,String> fieldDes;
        List<Map<String,String>> fieldDesList;
        Map<String, List<Map<String,String>>> response = new Map<String, List<Map<String,String>>>();
        Map<String, Schema.FieldSet> fieldSets = Schema.getGlobalDescribe().get('Claim__c').getDescribe().FieldSets.getMap();
        List<String> layoutNames = new List<String> {'Open_Claim_Field_Set', 'Reopen_Claim_Field_Set', 'Closed_Claim_Field_Set', 'Void_Claim_Field_Set'};
            
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Claim__c');
        Sobject objectName = targetType.newSObject();
        Schema.sObjectType sobjectType = objectName.getSObjectType(); 
        Schema.DescribeSObjectResult sobjectDescribe = sobjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = sobjectDescribe.fields.getMap();
        
        for (String layoutName : layoutNames) {
            List<String> layoutFieldNames = new List<String>();
            Schema.FieldSet layoutFieldSet = fieldSets.get(layoutName);
            if (layoutFieldSet != null) {
                List<Schema.FieldSetMember> layoutFields = layoutFieldSet.getFields();
                fieldDesList = new List<Map<String,String>>();
                for (Schema.FieldSetMember field : layoutFields) {
                    fieldDes = new Map<String,String>();
                    fieldDes.put('name',field.getFieldPath());
                    fieldDes.put('label',field.getLabel());
                    fieldDes.put('type',string.valueOf(field.getType()));
                    fieldDes.put('value','');
                    if(string.valueOf(field.getType()) == 'PICKLIST' || string.valueOf(field.getType()) == 'MULTIPICKLIST'){
                        List<String> pickListValuesList= new List<String>();
                        
                        List<Schema.PicklistEntry> pickVals = fieldMap.get(field.getFieldPath()).getDescribe().getPickListValues();
                        
                        for( Schema.PicklistEntry pickListVal : pickVals){
                            pickListValuesList.add(pickListVal.getLabel());
                        }     
                        fieldDes.put('picklistValues',string.valueOf(pickListValuesList));
                        
                    }
                    fieldDesList.add(fieldDes);
                }
                response.put(layoutName.toLowerCase(), fieldDesList);    
                
            }
        }
        return response;
    }
}