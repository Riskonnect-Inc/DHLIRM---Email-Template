/********************************************************************************************************************************************************
CLASS NAME : ApproveRejectProperty_Controller
CREATED BY : Priyanka Crasto
CREATED DATE : 04/06/2018
DESCRIPTION : This class is used for the ApproveRejectPropertyComponent lightning component to aprove or reject a particular property
---------------------------------------------------------------------------------------------------------------------------------------
MOD LOG
DATE :          DESCRIPTION :
**********************************************************************************************************************************************************/
public class ApproveRejectProperty_Controller {
    private class PVCResponseItem {
        PVCResponseItem(String value, String label) {
            this.value = value;
            this.label = label;
        }

        String value {get; set;}
        String label {get; set;}
    }

    private static PVCResponseItem[] getPVCListItems() {
        List<PVCResponseItem> pvcListItems = new List<PVCResponseItem>();
        for (Property_Value_Control__c pCtrl : [SELECT Id, Collection_Name__c, Evaluation_Date__c FROM Property_value_Control__c WHERE Status__c = 'In Progress'] ) {
            pvcListItems.add(new PVCResponseItem(pCtrl.Id, pCtrl.Collection_Name__c + ', ' + pCtrl.Evaluation_Date__c.format()));
        }
        return pvcListItems;
    }

    @auraEnabled
    public static String getPVCList() {
        return JSON.serialize(getPVCListItems());
    }

    @auraEnabled
    public static void processProperty(String propId, String pvcId, String approveComments, String approvalStatus) {
        if (String.isNotBlank(approvalStatus)) {
            Property_Value_Control__c propValCtr;
            Property__c prop = [SELECT Id, Values_Collection_Email__c, Approval_Status__c, Approval_Comments__c FROM Property__c WHERE Id = :propId FOR UPDATE];
            if (pvcId != null && pvcId != '') {
                propValCtr = [SELECT Id, Evaluation_Date__c, Total_Property_Values_Assigned__c FROM Property_Value_Control__c WHERE id = :pvcId LIMIT 1];
            } else if (getPVCListItems().size() == 1) {
                propValCtr = [SELECT Id, Evaluation_Date__c, Total_Property_Values_Assigned__c FROM Property_Value_Control__c WHERE Status__c = 'In Progress' LIMIT 1];
            }

            Property_Value__c pv = new Property_Value__c();
            pv.Property__c = prop.Id;
            pv.Values_Collection_Email__c = prop.Values_Collection_Email__c;
            if (propValCtr != null) {
                pv.Evaluation_Date__c = propValCtr.Evaluation_Date__c;
                pv.Property_Value_Control__c = propValCtr.Id;
                propValCtr.Total_Property_Values_Assigned__c += 1;
            }
            try {
                insert pv;
                prop.Approval_Status__c = approvalStatus;
                prop.Approval_Comments__c = approveComments;
                prop.Current_Property_Value__c = pv.Id;
                update prop;
                if (propValCtr != null) {
                    update propValCtr;
                }
            } catch (exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
}