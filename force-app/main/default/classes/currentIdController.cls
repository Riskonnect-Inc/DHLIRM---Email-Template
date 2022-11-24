/* 
Ron Forkey
PST-00001608
Visual Force page controller that returns the Notes section from the current claim to the printable Claim Abstract.
*/ 

/*===========================================================================
     Added to RK base RMIS product as  05/29/2013
    ===========================================================================*/
    
public class currentIdController{

    public String PrintNotes { get; set; }

    public String getPrintNotes() {
        return null;
    }


    public String getmycurrentId(){
        String ID = ApexPages.currentPage().getParameters().get('id');
        return ID;  
    
    }
    
    public PageReference getPageNext(){
        PageReference p = new PageReference('/apex/Print_Claim_Only?scontrolCaching=1&id=' + getmycurrentId());
        p.setRedirect(true);
        return P;
    }
}