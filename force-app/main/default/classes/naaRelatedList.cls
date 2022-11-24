/*===========================================================================
     Added to RK base RMIS product as 05/29/2013
    ===========================================================================*/
    
/*
Justin Gates 2/20/13 using Ron's code below as a template
Ron Forkey
PST-00001608
*/

// BK - PST-00014450
// Moved DML operation out of constructor and cleaned up code a bit

public class naaRelatedList {
    private Id privClaimId;
    private List<Adjuster_Notes__c> privNotes;

    public Id claimId {
        get {
            return privClaimId;
        }
    }

    public List<Adjuster_Notes__c> notes {
        get {
            return privNotes;
        }
    }

    public naaRelatedList() {
        privClaimId = System.currentPageReference().getParameters().get('id');
    }

    public naaRelatedList(ApexPages.StandardController controller) {
        privClaimId = System.currentPageReference().getParameters().get('id');
    }

    public List<Adjuster_Notes__c> getClaimNotes() {
        privNotes = [Select (Select  Id,
                                Name,
                                createdDate,
                                createdby.firstname,
                                createdby.lastname,
                                Note_Author_Name__c,
                                Note_Create_Date_Time__c,
                                Note_Text_Rich__c,
                                Note_Category__c,
                                Claim__c
                                From Adjuster_Notes__r Order By createdDate desc)
                From Claim__c
                Where Id=:claimId].Adjuster_Notes__r;
        return notes;
    }
}