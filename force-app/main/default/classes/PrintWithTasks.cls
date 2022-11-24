/*===========================================================================
     Added to RK base RMIS product as 10/31/2013
    ===========================================================================*/
    
public with sharing class PrintWithTasks {
    
    public PrintWithTasks(currentIdController controller){

}
    public String getmycurrentId(){
        String ID = ApexPages.currentPage().getParameters().get('id');
        return ID;  
    
    }
    
public PageReference getPrintWithTasks(){
    PageReference page = new PageReference('/apex/PrintWithTask?scontrolCaching=1&id=' + getmycurrentId());
    page.setRedirect(true);
    return page;
}
    
    

}