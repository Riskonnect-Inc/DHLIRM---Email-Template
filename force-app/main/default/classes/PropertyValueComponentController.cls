/*===========================================================================
     Added to RK base RMIS product as 08/01/2013
    ===========================================================================*/
    
public class PropertyValueComponentController {
 
    public class objectHistoryLine {
        public Date valuationDate {get; set;}
        public Decimal totalInsuredValue {get; set;}
        public Decimal buildingValue {get; set;}
        public Decimal businessInterruption {get; set;} 
        public Decimal content {get; set;}     
        public Decimal totalBusinessInterruption {get; set;}
        public Decimal totalBuildingValue {get; set;}       
    }
        
    // External variables
    public static SObject myObject {get; set;}
    public Integer listSize {get; set;}
    
    public objectHistoryLine[] getCustomHistory () {
      Id propertyId = String.valueOf(myObject.get('Id'));
        List<Property_Value__c> pvList = [Select Total_Insured_Value__c, 
                                                 Evaluation_Date__c,
                                                 Property__c,
                                                 Total_Business_Interruption__c,
                                                 Total_Building_Value__c
                                        From     Property_Value__c
                                        Where    Property__c =: propertyId  
                                        And      Evaluation_Date__c >= LAST_N_YEARS:5
                                        Order By Evaluation_Date__c];
                                        
        System.debug('PROPERTYVALUELIST: ' + pvList);
        System.debug('PROPERTYVALUELISTSIZE: ' + pvList.size());
        
        List<objectHistoryLine> ohl = new List<objectHistoryLine>();   
        listSize = pvList.size();
        
        if (pvList.size() > 0) { 
            for (Property_Value__c h: pvList) {
                objectHistoryLine h1 = new objectHistoryLine();
                h1.valuationDate = h.Evaluation_Date__c;
                
                if (h.Total_Insured_Value__c != null) {
                    h1.totalInsuredValue = h.Total_Insured_Value__c;}
                else h1.totalInsuredValue = 0;

                if (h.Total_Business_Interruption__c != null) {   
                    h1.totalBusinessInterruption = h.Total_Business_Interruption__c;}
                else h1.totalBusinessInterruption = 0;
                
                if (h.Total_Building_Value__c != null) {   
                    h1.totalBuildingValue = h.Total_Building_Value__c;}
                else h1.totalBuildingValue = 0;
                
                ohl.add(h1);
            }
        }
        else {
            objectHistoryLine h1 = new objectHistoryLine();
            h1.totalInsuredValue = 0;
            h1.buildingValue = 0;
            h1.businessInterruption = 0;
            h1.content = 0;
            h1.totalBuildingValue = 0;
            h1.totalBusinessInterruption = 0;
            h1.valuationDate = Date.Today();
            ohl.add(h1);
        }

        return ohl;   
    }
}