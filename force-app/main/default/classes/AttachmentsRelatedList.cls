/*===========================================================================
     Added to RK base RMIS product as 10/31/2013 
 ===========================================================================*/
/*
Justin Gates 2/20/13 using Ron's code below as a template
Ron Forkey
PST-00001608
*/

// BK - PST-00014450
// Moved DML operation out of constructor and cleaned up code a bit

public class AttachmentsRelatedList {
    private Id privClaimId;
    private List<Attachment__c> privAttachment;

    public Id claimId {
        get {
            return privClaimId;
        }
    }

    public List<Attachment__c> attachments {
        get {
            return privAttachment;
        }
    }

    public AttachmentsRelatedList() {
        privClaimId = System.currentPageReference().getParameters().get('id');
    }

    public AttachmentsRelatedList(ApexPages.StandardController controller) {
        privClaimId = System.currentPageReference().getParameters().get('id');
    }

    public List<Attachment__c> getClaimAttachment() {
        privAttachment = [Select (Select  Id,
                                Name,
                                createdDate,
                                createdby.firstname,
                                createdby.lastname,
                                Type__c,
                                Description__c,
                                Claim__c
                                From Attachments__r Order By createdDate desc)
                From Claim__c
                Where Id=:claimId].Attachments__r;
        return attachments;
    }
}