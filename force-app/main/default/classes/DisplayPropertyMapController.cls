/*===========================================================================
     Added to RK base RMIS product as 10/01/2013
    ===========================================================================*/
    
public class DisplayPropertyMapController {

    public String mapsURL {get; set;}
    public Property__c relatedProperty {get; set;}

    public DisplayPropertyMapController(ApexPages.StandardController stdCont) {
        ID propertyID = stdCont.getRecord().ID;
        relatedProperty = [SELECT Latitude__c, Longitude__c, Name, ID, Address_Line1__c, City__c, State__c, Zip_Code__c, Country__c FROM Property__c WHERE ID =: propertyID LIMIT 1];
        String clientID = 'gme-riskonnectinc';
        String cryptoKey = 'bmnmsYmEwWS8sS4gGzGdTDCghl0=';
        String urlBase = 'https://maps.googleapis.com/maps/api/js?v=3&sensor=false&client=' + clientID;
        Blob decodedKey = EncodingUtil.base64Decode(EncodingUtil.urlDecode(cryptoKey, 'UTF-8'));

        Blob signature = Crypto.generateMac('hmacSHA1', Blob.valueOf('/maps/api/js?sensor=false&client=' + clientID), decodedKey);

        String encodedSignature = base64URLEncode(signature);

        mapsURL = urlBase + '&signature=' + encodedSignature;
    }

    public String base64URLEncode(Blob input) {
        String output = EncodingUtil.base64Encode(input);
        output = output.replace('+', '-');
        output = output.replace('/', '_');
        return output;
    }
}