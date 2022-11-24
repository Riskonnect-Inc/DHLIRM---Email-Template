/*===========================================================================
     Added to RK base RMIS product as  05/27/2014
     
    ===========================================================================*/
  
public class SSCPaginationController {
    
    public ApexPages.StandardSetController setControl {get; set;}
    
    public Integer maxRecordSize {get; set;}
        
    public void doNext(){ 
        if(this.setControl.getHasNext())
            this.setControl.next(); 
    }
   
    public void doPrevious(){ 
        if(this.setControl.getHasPrevious())
            this.setControl.previous(); 
    }
    
    public void doFirst(){
        this.setControl.first();
    }
    
    public void doLast(){
        this.setControl.last();
    }
            
    public Boolean getHasPrevious(){ 
        return this.setControl.getHasPrevious(); 
    }
 
    
    public Boolean getHasNext(){ 
        return this.setControl.getHasNext(); 
    }
    
    public Integer PageSize {
        get {
            return this.setControl.getPageSize();
        }
        set {
             this.setControl.setPageSize(value);
        }    
    }
    
    public Integer PageNumber{
        get {
            return this.setControl.getPageNumber(); 
        }        
    }
    
    public Integer RecordCount {
        get {
            return this.setControl.getResultSize();
        }       
    }
    
    public String MoreRecs {
        get {
            if (maxRecordSize > 0 && RecordCount >= maxRecordSize) {
                    return '+';
            }
            return '';
        }   
    }
    
    public integer Offset {
        get {
            return (PageSize * (PageNumber - 1));
        }         
    }
    
    public integer LowRecShowing {
        get { return RecordCount == 0 ? 0 : (Offset + 1); }
    }

    public integer UpperRecShowing {
        get { 
            integer upperNum = ((LowRecShowing + PageSize) - 1);
            return (upperNum > RecordCount) ? RecordCount : upperNum; 
        }
    }

     
    Public Integer getTotalPages(){
        Decimal totalSize = this.setControl.getResultSize();
        Decimal pageSize = this.setControl.getPageSize();
 
        Decimal pages = totalSize/pageSize;
 
        return (Integer)pages.round(System.RoundingMode.CEILING);
    }

}