/*===========================================================================
     Added to RK base RMIS product as  05/29/2013
     Author : Ron Forkey
     Task Number: PST-00001608
   ===========================================================================*/


public class TransBlockTableSortingCon {
 
   private List<Claim_Transaction__c> trans;
   private String sortDirection = 'ASC';
   private String sortExp = 'Transaction_Date__c';

   public String sortExpression
   {
     get
     {
        return sortExp;
     }
     set
     {
       //if the column is clicked on then switch between Ascending and Descending modes
       if (value == sortExp)
         sortDirection = (sortDirection == 'ASC')? 'DESC' : 'ASC';
       else
         sortDirection = 'ASC';
       sortExp = value;
     }
   }

 public String getSortDirection()
 {
    //if not column is selected 
    if (sortExpression == null || sortExpression == '')
      return 'ASC';
    else
     return sortDirection;
 }

 public void setSortDirection(String value)
 {  
   sortDirection = value;
 }
  
   public List<Claim_Transaction__c> getNotes() {
       return trans;
   }


   public PageReference ViewData() {
       //build the full sort expression
       string sortFullExp = sortExpression  + ' ' + sortDirection;
      
       //query the database based on the sort expression
       trans = Database.query('SELECT Name, Transaction_Date__c, Transaction_Status__c, Category__c, Payee__c, Claim__c from Claim_Transaction__c order by ' + sortFullExp + ' limit 1000');
       return null;
   }

}