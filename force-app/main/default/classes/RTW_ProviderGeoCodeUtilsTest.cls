/*===========================================================================
     Added to RK base RMIS product as  05/01/2016
    ===========================================================================*/
    
@isTest
public class RTW_ProviderGeoCodeUtilsTest {
    
    static TestMethod void testContactGeocoding(){
        
        RecordType contactPhysicianRT = [SELECT id,name FROM RecordType WHERE developerName='Physician' limit 1];
        Contact con = new Contact(RecordTypeId = contactPhysicianRT.Id,
                                  FirstName =  'Test',
                                  LastName = 'Testerson',
                                  //gLocation__Latitude__s = 41.8905152,
                                  //gLocation__Longitude__s = -87.6342815,
                                  MailingStreet = '1701 Barrett Lakes Blvd',
                                  MailingCity = 'Kennesaw',
                                  MailingState = 'GA',
                                  MailingPostalCode = '30144');
        insert con;
        
        string query = 'Select Id, Name, MailingStreet, MailingCity, MailingState, MailingPostalCode from Contact';
        
        Id batchId = Database.executeBatch(new RTW_ProviderGeoCodeUtils(query),1);
        
    }
   
}