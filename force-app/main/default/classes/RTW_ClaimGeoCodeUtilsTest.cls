/*===========================================================================
     Added to RK base RMIS product as  05/01/2016
    ===========================================================================*/
    
@isTest
public class RTW_ClaimGeoCodeUtilsTest {
    
    static TestMethod void testClaimGeocoding(){
        
        RecordType claimRT = [SELECT id,name FROM RecordType WHERE developerName='WC' limit 1];
        Claim__c claim = new Claim__c(RecordTypeId = claimRT.Id,
                                      Name = 'Test',
                                      Coverage_Major__c = 'WC',
                                      Date_of_Loss__c = System.today(),
                                      Claimant_Last_Name__c = 'Test Last Name', 
                                      //gLocation__Latitude__s = 41.8905152,
                                      //gLocation__Longitude__s = -87.6342815,
                                      Claimant_Address_Line1__c = '1701 Barrett Lakes Blvd',
                                      Claimant_City__c = 'Kennesaw',
                                      Claimant_State__c = 'GA',
                                      Claimant_Postal_Code__c = '30144');
        insert claim;
        
        string query = 'Select Id, Name, Claimant_Address_Line1__c, Claimant_City__c, Claimant_State__c, Claimant_Postal_Code__c from Claim__c';
        
        Id batchId = Database.executeBatch(new RTW_ClaimGeoCodeUtils(query),1);
        
    }
    
}