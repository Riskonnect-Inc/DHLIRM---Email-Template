/*===========================================================================
     Added to RK base RMIS product as 02/07/2014
     AUTHOR: Jason Bradley
    ===========================================================================*/

global class ClientOrgStatusWebservice_Schedulable implements Schedulable {

    
    global String hostURL {get; set;}
    global String sessionID {get; set;}
    global String orgID {get; set;}

    global ClientOrgStatusWebservice_Schedulable() {
    hostURL = URL.getSalesforceBaseUrl().toExternalForm();
    sessionID = UserInfo.getSessionId();
    orgID = UserInfo.getOrganizationId();
    }
    global void execute(SchedulableContext sc) {
        ClientOrgStatusWebservice.notifyRKCRMFuture(hostURL, sessionID, orgID);
    }
}