/*===========================================================================
    Created Date :   12/11/2014
    ===========================================================================*/
@isTest
public class ClaimMergeFlowControllertest {

public static testmethod void ClaimMergeFlowControllertest() {
    
    //Insert Claim
    Claim__c c = new Claim__c (Name='TestClaim', Date_of_Loss__c=date.today());
    insert c;
    
    //Retrieve the new Contract
    c = [Select Id, Name, Date_of_Loss__c, Claimant_Name__c, Coverage_Major__c, Location_Lookup__c, CreatedDate FROM Claim__c WHERE Id =:c.Id];
    
    String cId = c.Id;
    String cName = c.Name;
    Date cDateOfLoss = c.Date_of_Loss__c;
    String cClaimantName = c.Claimant_Name__c;
    String cCoverage = c.Coverage_Major__c;
    String cLocation = c.Location_Lookup__c;
    Datetime cCreatedDate = c.CreatedDate;
    System.debug(cId);

    ApexPages.StandardController sc = new ApexPages.StandardController(c);
    ClaimMergeFlowController ec = new ClaimMergeFlowController(sc);
    
    PageReference ClaimMergeFlowPagePageRef = Page.ClaimMergeFlowPage;
    Test.setCurrentPage(ClaimMergeFlowPagePageRef);

    String ClaimId = cId;
    String varClaimIdOriginal = cId;
    String varMatchCriteria = 'Loss Date, Major Coverage, Location';
    Boolean varRender = TRUE;
    Boolean varRender2 = TRUE;
    ec.getClaims();
    ec.getRender();
    ec.getClaims2();
    ec.getRender2();
    ec.getClaimId();
    ec.getFinishPage();

    
    System.test.startTest();
    //System.debug('ContractId - Add ContractId'); 
    //System.debug('ContractId - Save');
    System.test.stopTest();
   
    
}
}