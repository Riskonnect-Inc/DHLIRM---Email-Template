/*===========================================================================
     Added to RK base RMIS product as 10/31/2013
   ===========================================================================*/
    
public with sharing class PrintWithAttachment {
  
  public PrintWithAttachment(currentIdController controller){

}
    public String getmycurrentId(){
        String ID = ApexPages.currentPage().getParameters().get('id');
        return ID;  
    
    }
    
public PageReference getPrintWithAttachment(){
    PageReference page = new PageReference('/apex/PrintWithAttachment?scontrolCaching=1&id=' + getmycurrentId());
    page.setRedirect(true);
    return page;
}
  
  

}