/*===========================================================================
     Added to RK base RMIS product as 11/13/2014
    ===========================================================================*/
    
public class ReserveTransactionFlowController {

public Flow.Interview.ReserveTransactionFlow myflow {get;set;}
public string ReserveIdVar {get;set;}

public ReserveTransactionFlowController(){
    ReserveIdVar = ApexPages.CurrentPage().getParameters().get('id');
}


public String getClaimTransactionIdVar(){
    if(myflow == null)
    {
        return '';
    }
    else
    {
       return myflow.ClaimTransactionIdVar;
    }
}

public pageReference getFinishLocation(){
    PageReference pageRef = new Pagereference('/'+getClaimTransactionIdVar());    
        return pageRef;      
}


}