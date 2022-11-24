/*===========================================================================
     Added to RK base RMIS product as 04/19/2016
    ===========================================================================*/
    
@isTest
public class OSHALogEmailHandlerTest {
    
    
    @isTest
    static void testOSHALogEmailHandler(){
        List<Report_Request__c> testRequests = new List<Report_Request__c>();
        
        testRequests.add(new Report_Request__c(Request_Status__c = 'Pending'));
        
        insert testRequests;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.Subject = '';
        email.plainTextBody = null;
        
        
        Messaging.InboundEmail.BinaryAttachment attach = new Messaging.InboundEmail.BinaryAttachment();
        
        attach.body = blob.valueOf(generateCSV(testRequests));
        attach.fileName = 'TEST.CSV';
        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] { attach };
        
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        OSHALogEmailHandler handler = new OSHALogEmailHandler();
        
        
        Messaging.InboundEmailResult results = handler.handleInboundEmail(email,envelope);
        
        // system.assertEquals(results.success,true);
    }
    
    public static String generateCSV(List<Report_Request__c> requests) {
        /*
        String s = line(new String[] {
                format('Report Request ID')
                }); */
        String s = '';
        for (Report_Request__c r : requests) {
            s += line(new String[] {
                    format(r.Id)
                    });
        }
        return s;
    }
    private static String line(String[] cells) {
        return String.join(cells, ',') + '\n';
    }
    private static String format(Date d)    {
        return d != null ? '"' + d.format().escapeCsv() + '"' : '""';
    }
    private static String format(String s) {
        return s != null ? '"' + s.escapeCsv() + '"' : '""';
    }
    private static String format(Decimal d, Integer scale) {
        return d != null ? String.valueOf(d.setScale(scale)) : '';
    }
    private static String format(Decimal d) {
        return format(d, 2);
    }
    
}