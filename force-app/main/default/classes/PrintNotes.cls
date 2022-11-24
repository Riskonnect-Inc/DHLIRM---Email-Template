/*
Ron Forkey
PST-00001608
*/
/*===========================================================================
     Added to RK base RMIS product as 05/29/2013
    ===========================================================================*/
    
public class PrintNotes{

public PrintNotes(currentIdController controller){

}
    public String getmycurrentId(){
        String ID = ApexPages.currentPage().getParameters().get('id');
        return ID;  
    
    }
    
public PageReference getPrintNotes(){
    PageReference page = new PageReference('/apex/Print_Claim_w_Notes?scontrolCaching=1&id=' + getmycurrentId());
    page.setRedirect(true);
    return page;
}

}