/*===========================================================================
     Added to RK base RMIS product as 02/07/2014
    ===========================================================================*/
    
@isTest
private class ClientOrgStatusWebservice_Test {
    
    public static testmethod void testSOAP() {
        ClientOrgStatusWebserviceSOAP testSOAP = new ClientOrgStatusWebserviceSOAP();
        ClientOrgStatusWebserviceSOAP.LogInfo testLogInfo = new ClientOrgStatusWebserviceSOAP.LogInfo();
        ClientOrgStatusWebserviceSOAP.AllowFieldTruncationHeader_element testTruncationHeaderElement = new ClientOrgStatusWebserviceSOAP.AllowFieldTruncationHeader_element();
        ClientOrgStatusWebserviceSOAP.DebuggingHeader_element testDebuggingHeaderElement = new ClientOrgStatusWebserviceSOAP.DebuggingHeader_element();
        ClientOrgStatusWebserviceSOAP.CallOptions_element testCallOptionsElement = new ClientOrgStatusWebserviceSOAP.CallOptions_element();
        ClientOrgStatusWebserviceSOAP.clientDataHandler_element testClientDataHandlerElement = new ClientOrgStatusWebserviceSOAP.clientDataHandler_element();
        ClientOrgStatusWebserviceSOAP.SessionHeader_element testSessionHeaderElement = new ClientOrgStatusWebserviceSOAP.SessionHeader_element();
        ClientOrgStatusWebserviceSOAP.DebuggingInfo_element testDebuggingInfoElement = new ClientOrgStatusWebserviceSOAP.DebuggingInfo_element();
        ClientOrgStatusWebserviceSOAP.clientDataHandlerResponse_element testClientDataHandlerResponseElement = new ClientOrgStatusWebserviceSOAP.clientDataHandlerResponse_element();

        ClientOrgStatusWebserviceSOAP.ClientOrgStatusWebservice testWebservice = new ClientOrgStatusWebserviceSOAP.ClientOrgStatusWebservice();
        testWebservice.clientDataHandler('{"TEST": "VALUE"}', 'TEST IDENTIFICATION STRING');
    }
    
    public static testmethod void testWebservice() {
        ClientOrgStatusWebservice testWebservice = new ClientOrgStatusWebservice();
        ClientOrgStatusWebservice.getPageContent('https://login.salesforce.com', 'test', '');
    }

    public static testmethod void testSchedulable() {
        SchedulableContext sc;
        ClientOrgStatusWebservice_Schedulable testSchedulable = new ClientOrgStatusWebservice_Schedulable();
        testSchedulable.execute(sc);
    }
}