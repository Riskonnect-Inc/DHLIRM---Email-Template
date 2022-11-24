/*===========================================================================
     Added to RK base RMIS product as 11/11/2014
    ===========================================================================*/
    
public class ClaimMergeFlowController{

    public ClaimMergeFlowController(ApexPages.StandardController controller){}
    private final Claim__c claim {get;set;}
    public Flow.Interview.ClaimMergeFlow2 myflow {get;set;}


    String Id;
    public ClaimMergeFlowController(){
        Id=Apexpages.currentPage().getParameters().get('id');
    }



   public class claimsList {
        public String claimName {get; set;}
        public String dateOfLoss {get; set;}
        public String claimantName {get; set;}
        public String coverage {get; set;}
        public String location {get; set;}
        public String createdDate {get; set;}

        public claimsList() {
            
        }
        
    }
    
    // External variables
    public SObject myObject {get; set;}
    public string dateoflossvar {get; set;}
    
    public claimsList[] getClaims () {
    
        List<Claim__c> cList;
        if (myflow != null) {
        dateoflossvar = string.valueOf((object)myflow.varDateofLoss1);
        //system.debug(dateoflossvar);
            if (myflow.varMatchCriteria != null) {
            if (myflow.varMatchCriteria == 'Loss Date, Major Coverage, Location') {
                cList = [SELECT Id, Name, Date_of_Loss__c, Claimant_Name__c, Coverage_Major__c, Location_Lookup__c, Location_Lookup__r.Id, Location_Lookup__r.Name, CreatedDate, TPA_Carrier__c, Claim_Key__c  
                FROM Claim__c 
                WHERE Date_of_Loss__c =: date.valueOf(myflow.varDateofLoss1) 
                AND Coverage_Major__c =: myflow.varCoverageMajor1 
                AND Location_Name__c =: myflow.varLocationName1 
                AND TPA_Carrier__c =: myflow.varTPACarrier1 
                AND Data_Load_Flag__c =: '' 
                AND Id !=: myflow.varClaimIdOriginal
                ORDER BY Name ASC
                Limit 200 ];
            }
            if (myflow.varMatchCriteria == 'Loss Date and Major Coverage') {
                cList = [SELECT Id, Name, Date_of_Loss__c, Claimant_Name__c, Coverage_Major__c, Location_Lookup__c, Location_Lookup__r.Id, Location_Lookup__r.Name, CreatedDate, TPA_Carrier__c, Claim_Key__c 
                FROM Claim__c 
                WHERE Date_of_Loss__c =: date.valueOf(myflow.varDateofLoss1) 
                AND Coverage_Major__c =: myflow.varCoverageMajor1                 
                AND TPA_Carrier__c =: myflow.varTPACarrier1 
                AND Data_Load_Flag__c =: '' 
                AND Id !=: myflow.varClaimIdOriginal
                ORDER BY Name ASC
                Limit 200 ];
            }
            if (myflow.varMatchCriteria == 'Loss Date') {
                cList = [SELECT Id, Name, Date_of_Loss__c, Claimant_Name__c, Coverage_Major__c, Location_Lookup__c, Location_Lookup__r.Id, Location_Lookup__r.Name, CreatedDate, TPA_Carrier__c, Claim_Key__c 
                FROM Claim__c 
                WHERE Date_of_Loss__c =: date.valueOf(myflow.varDateofLoss1) 
                AND TPA_Carrier__c =: myflow.varTPACarrier1 
                AND Data_Load_Flag__c =: '' 
                AND Id !=: myflow.varClaimIdOriginal
                ORDER BY Name ASC
                Limit 200 ];
            }            
            if (myflow.varMatchCriteria == 'Claimant Name, Major Coverage') {
                cList = [SELECT Id, Name, Date_of_Loss__c, Claimant_Name__c, Coverage_Major__c, Location_Lookup__c, Location_Lookup__r.Id, Location_Lookup__r.Name, CreatedDate, TPA_Carrier__c, Claim_Key__c 
                FROM Claim__c 
                WHERE Claimant_Name__c =: myflow.varClaimantName1
                AND Coverage_Major__c =: myflow.varCoverageMajor1                 
                AND TPA_Carrier__c =: myflow.varTPACarrier1 
                AND Data_Load_Flag__c =: '' 
                AND Id !=: myflow.varClaimIdOriginal
                ORDER BY Name ASC 
                Limit 200 ];
            }
            if (myflow.varMatchCriteria == 'Date of Loss, Claimant Name, Coverage Major') {
                cList = [SELECT Id, Name, Date_of_Loss__c, Claimant_Name__c, Coverage_Major__c, Location_Lookup__c, Location_Lookup__r.Id, Location_Lookup__r.Name, CreatedDate, TPA_Carrier__c, Claim_Key__c 
                FROM Claim__c 
                WHERE Claimant_Name__c =: myflow.varClaimantName1
                AND Coverage_Major__c =: myflow.varCoverageMajor1                 
                AND TPA_Carrier__c =: myflow.varTPACarrier1 
                AND Data_Load_Flag__c =: '' 
                AND Id !=: myflow.varClaimIdOriginal
                AND Date_of_Loss__c =: date.valueOf(myflow.varDateofLoss1) 
                ORDER BY Name ASC 
                Limit 200 ];
            }            
            
            
            }
        } else {
            cList = new List<Claim__c>();
        }
       
        
        List<claimsList> cL = new List<claimsList>();   
        
        if (cList.size() > 0) { 
            for (Claim__c c: cList) {
                claimsList c1 = new claimsList();
                c1.claimName = c.Name;
                if (c.Date_of_Loss__c == null) {
                    c1.dateOfLoss = 'No Loss Date';
                }
                else {
                    c1.dateOfLoss = ((DateTime)c.Date_of_Loss__c).formatGMT('MM/dd/YYYY');
                }
                c1.claimantName = c.Claimant_Name__c;
                c1.coverage = c.Coverage_Major__c;
                c1.location = c.Location_Lookup__r.Name;
                c1.createdDate = ((DateTime)c.CreatedDate).formatGMT('MM/dd/YYYY');
                cL.add(c1);
            }
        }
        else {
            claimsList c1 = new claimsList();
            c1.claimName = 'No Matching Claims';
            //c1.dateOfLoss = 0;
            cL.add(c1);
        }

        return cL;   
    }

    public String getRender(){ 
        if (myflow == null)
    {
        return 'false' ;
    }
    else
    { 
        return  myflow.varRender;
    }
    }










public class claimsList2 {
    public String claimName2 {get; set;}
    public String dateOfLoss2 {get; set;}
    public String claimantName2 {get; set;}
    public String coverage2 {get; set;}
    public String location2 {get; set;}
    public String createdDate2 {get; set;}
    public String coverageMinor2 {get; set;}
    public String tpaCarrier2 {get; set;}
    public String dataLoadFlag2 {get; set;}


    public claimsList2() {
        
    }
    
}


public claimsList2[] getClaims2 () {

    List<Claim__c> cList2;
    if (myflow != null) {
    //dateoflossvar2 = string.valueOf((object)myflow.varDateofLoss1);
    //system.debug(dateoflossvar);
            cList2 = [SELECT Id, Name, Date_of_Loss__c, Claimant_Name__c, Coverage_Major__c, Location_Lookup__c, Location_Lookup__r.Id, Location_Lookup__r.Name, CreatedDate, TPA_Carrier__c, Claim_Key__c, Coverage_Minor__c, Data_Load_Flag__c 
            FROM Claim__c 
            WHERE Data_Load_Flag__c =: 'Insert' 
            ORDER BY Name ASC 
            Limit 200 ];
    } else {
        cList2 = new List<Claim__c>();
    }
   
    
    List<claimsList2> cL2 = new List<claimsList2>();   
    
    if (cList2.size() > 0) { 
        for (Claim__c c: cList2) {
            claimsList2 c1 = new claimsList2();
            c1.claimName2 = c.Name;
            if (c.Date_of_Loss__c == null) {
                c1.dateOfLoss2 = 'No Loss Date';
            }
            else {
                c1.dateOfLoss2 = ((DateTime)c.Date_of_Loss__c).formatGMT('MM/dd/YYYY');
            }
            c1.claimantName2 = c.Claimant_Name__c;
            c1.coverage2 = c.Coverage_Major__c;
            c1.location2 = c.Location_Lookup__r.Name;
            c1.createdDate2 = ((DateTime)c.CreatedDate).formatGMT('MM/dd/YYYY');
            c1.tpaCarrier2 = c.TPA_Carrier__c;
            c1.coverageMinor2 = c.Coverage_Minor__c;
            c1.dataLoadFlag2 = c.Data_Load_Flag__c;
            cL2.add(c1);
        }
    }
    else {
        claimsList2 c1 = new claimsList2();
        c1.claimName2 = 'No Matching Claims';
        //c1.dateOfLoss = 0;
        cL2.add(c1);
    }

    return cL2;   
}

public String getRender2(){ 
    if (myflow == null)
{
    return 'false' ;
}
else
{ 
    return  myflow.varRender2;
}
}





public String getClaimId() {
    if (myflow==null) return '';
    else return myflow.varClaimIdOriginal;
}
//Used for Flow finish location
public PageReference getFinishPage(){
    PageReference p = new PageReference('/' + getClaimId());
    p.setRedirect(true);
    return p;
}






    
}