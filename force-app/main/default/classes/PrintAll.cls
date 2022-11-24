/*
Ron Forkey
PST-00001608
*/
/*===========================================================================
     Added to RK base RMIS product as 05/29/2013
    ===========================================================================*/
    
public class PrintAll{

public PrintAll(currentIdController controller){

}
    public String getmycurrentId(){
        String ID = ApexPages.currentPage().getParameters().get('id');
        return ID;  
    
    }
    
public PageReference getPrintAll(){
    PageReference page = new PageReference('/apex/Print_All?scontrolCaching=1&id=' + getmycurrentId());
    page.setRedirect(true);
    return page;
}

}