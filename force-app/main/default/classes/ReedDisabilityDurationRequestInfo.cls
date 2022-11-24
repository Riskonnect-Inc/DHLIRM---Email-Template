/*===========================================================================
     Added to RK base RMIS product as 05/29/2013
    ===========================================================================*/
    
/*
    AD 2/5/2013 - Test Reed connectivity via Restful 
    
    Below sample call for DisabilityDurationRequest
    
    <DisabilityDurationRequest xmlns="http://MDGuidelines.WebService">
        <LicenseKey>INSERT_YOUR_LICENSE_KEY</LicenseKey> 
      <PublicKey>2011.08.16.15.30</PublicKey>
      <HMAC>3F903F32CD0F0D4391A6F8DDB81BF3527B575144D8AEA594EE5FCDF00F47F6BB25BD8D9EFFE7A6DC22A098870937FEC62B869E67F132425A9B9D279B55218288</HMAC>
      <ICD9Code>354</ICD9Code>  
      <Factor nil="true" />
      <JobClass>SEDENTARY</JobClass>
    </DisabilityDurationRequest> 
*/
public class ReedDisabilityDurationRequestInfo {

    String LicenseKey;
    String PublicKey; 
    String HMAC;
    String ICD9Code;
    String Factor;
    String JobClass;

    public ReedDisabilityDurationRequestInfo(String s1, String s2){
        LicenseKey = '070f527a-fb0d-4517-9ae9-467f7474c51a';
        PublicKey = '2011.08.16.15.30';
        HMAC = '3F903F32CD0F0D4391A6F8DDB81BF3527B575144D8AEA594EE5FCDF00F47F6BB25BD8D9EFFE7A6DC22A098870937FEC62B869E67F132425A9B9D279B55218288';
        ICD9Code = s1;
        JobClass = s2;
    }
}