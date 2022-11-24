@isTest
private class CreateReviewRecord_Test {

    static testMethod void eventTest() {
        insert new HC_Custom_Settings__c(
            PE_Auto_Create_Review_Records__c = true,
            PF_Auto_Create_Review_Records__c  = true
        );
        rkl__RK_Hierarchy_Node__c hNode = new rkl__RK_Hierarchy_Node__c(
            department_manager__c = UserInfo.getUserId(),
            rkl__Node_Level__c = 3
        );
        insert hNode;
        rkl__RK_Hierarchy_Node__c hNode2 = new rkl__RK_Hierarchy_Node__c(
            department_manager__c = UserInfo.getUserId(),
            rkl__Parent_Node__c = hNode.id,
            rkl__Node_Level__c = 4
        );
        insert hNode2;
        rkl__Form_Template__c ft = new rkl__Form_Template__c(Name = 'Initial Reported Patient Event');
        insert ft;
        Patient_Event__c test = new Patient_Event__c(
            primary_location__c = hNode.id,
            secondary_facility__c = hNode.id,
            secondary_location__c = hNode2.id,
            IM_Status__c = 'In Progress',
            Initial_PDF_Created__c = false
        );
        insert test;
        System.assertEquals(0,Database.countQuery('SELECT Count() FROM review__c'));
        test.IM_Status__c = 'Submitted';
        //test.Initial_PDF_Created__c = true;
        update test;
        System.assertEquals(2,Database.countQuery('SELECT Count() FROM review__c'));
    }
    
    static testMethod void feedbackTest() { 
        insert new HC_Custom_Settings__c(
            PE_Auto_Create_Review_Records__c = false,
            PF_Auto_Create_Review_Records__c  = false
        );
        rkl__RK_Hierarchy_Node__c hNode = new rkl__RK_Hierarchy_Node__c(
            department_manager__c = UserInfo.getUserId(),
            rkl__Node_Level__c = 3
        );
        insert hNode;
        rkl__RK_Hierarchy_Node__c hNode2 = new rkl__RK_Hierarchy_Node__c(
            department_manager__c = UserInfo.getUserId(),
            rkl__Parent_Node__c = hNode.id,
            rkl__Node_Level__c = 4
        );
        insert hNode2;
        Patient_Satisfaction__c test = new Patient_Satisfaction__c(
            primary_location__c = hNode.id,
            secondary_facility__c = hNode.id,
            secondary_location__c = hNode2.id,
            IM_Status__c = 'In Progress'
        );
        insert test;
        System.assertEquals(0,Database.countQuery('SELECT Count() FROM patient_feedback_review__c'));
        test.IM_Status__c = 'Submitted';
        update test;
        System.assertEquals(0,Database.countQuery('SELECT Count() FROM patient_feedback_review__c'));//because of false above.
    }
    
    static testMethod void duplicateTest() { 
        insert new HC_Custom_Settings__c(
            PE_Auto_Create_Review_Records__c = false,
            PF_Auto_Create_Review_Records__c  = false
        );
        Patient_Satisfaction__c test = new Patient_Satisfaction__c(
            Status_of_Complaint__c = 'Duplicate',
            IM_Status__c = 'In Progress'
        );
        insert test;
        test.status_of_complaint__c = 'Void';
        update test;
    }
    
}