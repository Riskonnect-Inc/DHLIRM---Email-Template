/*
Ron Forkey
PST-00001608
*/

public class PageBlockTableSortingCon {

    private List<Adjuster_Notes__c> notes;
    private String sortDirection = 'ASC';
    private String sortExp = 'name';

    public String sortExpression {
        get {
            return sortExp;
        }
        set {
            // if the column is clicked on then switch between Ascending and Descending modes
            if (value == sortExp) {
                sortDirection = (sortDirection == 'ASC')? 'DESC' : 'ASC';
            } else {
                sortDirection = 'ASC';
                sortExp = value;
            }
        }
    }

    public String getSortDirection() {
        // if not column is selected 
        if (sortExpression == null || sortExpression == '') {
            return 'ASC';    
        } else {
            return sortDirection;    
        }
    }

    public void setSortDirection(String value) {  
        sortDirection = value;
    }

    public List<Adjuster_Notes__c> getNotes() {
       return notes;
    }

    public PageReference ViewData() {
       //build the full sort expression
       string sortFullExp = sortExpression  + ' ' + sortDirection;
      
       //query the database based on the sort expression

       // BK
       // 'Body, IsPrivate, Title' are not valid fields on Adjuster_Notes__c
       // Body      => Note_Text__c
       // IsPrivate => removed
       // Title     => Name
       notes = Database.query('SELECT Note_Text_Rich__c, CreatedBy.Name, CreatedDate, Name FROM Adjuster_Notes__c order by ' + sortFullExp + ' limit 1000');
       return null;
    }

}