/*===========================================================================
     Added to RK base RMIS product as 05/29/2013
     Author: Ron Forkey
     Task Number : PST-00001608
    ===========================================================================*/
 public class PrintTrans{

public PrintTrans(currentIdController controller){

}
    public String getmycurrentId(){
        String ID = ApexPages.currentPage().getParameters().get('id');
        return ID;  
    
    }
    
public PageReference getPrintTrans(){
    PageReference page = new PageReference('/apex/Print_Claim_w_Transactions?scontrolCaching=1&id=' + getmycurrentId());
    page.setRedirect(true);
    return page;
}

}