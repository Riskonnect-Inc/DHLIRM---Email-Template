/*===========================================================================
     Added to RK base RMIS product as 02/07/2014
     AUTHOR: Jason Bradley
    ===========================================================================*/
public class ClientOrgStatusWebservice {
    public ClientOrgStatusWebservice() {
        
    }

    @future(callout=true)
    public static void notifyRKCRMFuture(String hostURL, String sessionID, String orgID) {
        String clientOrgStatusJSON = JSON.serialize(ClientOrgStatusWebservice.getClientInfo(hostURL, sessionID, orgID));

        final String expectedIdentificationString = 'gD87EIqfLOwvjXbNto1dPexbkXuDHQpEwlxX7dxI5kZOJ3EI9Th0WlwXH4gxS0GhrOsbo6RYqqUPlUc8sBkFyHfHKczTpBtkJROUHXJLdivQhAseEuxqc5sCcijKIC3aAPHd5gdcn6OObUlmhVX03TQroyvgDmxcVPFi2VI31bbVaaF7M35qhQPuZMj6MmJGIZij9yD8J8HUGgZaaXOmFPSVN1Bm0SjiBLbgvdy3vUhsvWdgLPAaGcHPFbYFt1Tj3mJSyhmpENTSQ4boA1YWsXSZWxFCVMpnRgu52eGiEYc1OYoj95s8TVB7NXAIJ4YW5csRdmVSWCKLNCpcnPD0cNUdl9aclgOwaluuoCkXdJoG3LzjbJ7UbkbDfDsEIe7Uj8TDM2Dhz4rmIDHb';
        
        ClientOrgStatusWebserviceSOAP.ClientOrgStatusWebservice clientOrgStatusWebserviceSOAP = new ClientOrgStatusWebserviceSOAP.ClientOrgStatusWebservice();
        clientOrgStatusWebserviceSOAP.endpoint_x = 'https://riskonnect.secure.force.com/clientOrgStatusNotifier/services/Soap/class/ClientOrgStatusWebservice';
        clientOrgStatusWebserviceSOAP.timeout_x = 10000;

        clientOrgStatusWebserviceSOAP.clientDataHandler(clientOrgStatusJSON, expectedIdentificationString);
    }

    public static ClientOrgStatusWebservice.ClientInfo getClientInfo(String hostURL, String sessionID, String orgID) {
        Map<String, Integer[]> clientLicenseData = ClientOrgStatusWebservice.grabClientLicenseData(hostURL, sessionID, orgID);
        System.debug(JSON.serialize(clientLicenseData));
        Map<String, String[]> clientStorageData = ClientOrgStatusWebservice.grabStorageUsageData(hostURL, sessionID, orgID);
        System.debug(JSON.serialize(clientStorageData));

        ClientOrgStatusWebservice.ClientInfo clientInfo = new ClientOrgStatusWebservice.ClientInfo(orgID, clientLicenseData, clientStorageData);
        return clientInfo;
    }

    public static Map<String, Integer[]> grabClientLicenseData(String hostURL, String sessionID, String orgID) {
        String pageContent;
        if (!Test.isRunningTest()) {
            pageContent = ClientOrgStatusWebservice.getPageContent(hostURL, sessionID, '/' + orgID);
        } else {
            pageContent = ClientOrgStatusWebservice.getTestLicensePage();
        }
        String[] userLicenseTypes = new String[]{'Salesforce', 'Salesforce Platform', 'Partner', 'Customer Portal Manager', 'Authenticated Website', 'High Volume Customer Portal', 'Service Cloud', 'Force.com - Free', 'Chatter Free', 'Chatter External', 'Customer Portal Manager Standard', 'Customer Portal Manager Custom', 'Gold Partner', 'Silver Partner', 'Customer Community Login', 'Customer Community', 'Partner Community', 'Partner Community Login'};

        Map<String, Integer[]> userLicenseData = new Map<String, Integer[]>();
        for (String licenseType : userLicenseTypes) {
            userLicenseData.put(licenseType, ClientOrgStatusWebservice.getDataForLicenseType(licenseType, pageContent));
        }

        return userLicenseData;
    }

    public static Integer[] getDataForLicenseType(String licenseType, String pageData) {
        System.debug('LicenseType: ');
        System.debug(licenseType);
        System.debug('Page Data: ');
        System.debug(pageData);
        Matcher salesforceLicenseMatcher = Pattern.compile('<tr[\\sA-Za-z="().{;}]*><th[\\sA-Za-z="]*>' + licenseType + '</th><td[\\sA-Za-z="]*>Active</td><td[\\sA-Za-z="]*>([0-9,]*)</td><td[\\sA-Za-z="]*>([0-9,]*)</td><td[\\sA-Za-z="]*>([0-9,]*)</td><td[\\sA-Za-z="]*>').matcher(pageData);
        Integer[] returnData = new Integer[3];
        if (salesforceLicenseMatcher.find()) {
            returnData[0] = Integer.valueOf(salesforceLicenseMatcher.group(1).replaceAll(',', ''));
            returnData[1] = Integer.valueOf(salesforceLicenseMatcher.group(2).replaceAll(',', ''));
            returnData[2] = Integer.valueOf(salesforceLicenseMatcher.group(3).replaceAll(',', ''));
        }
        return returnData;
    }

    public static Map<String, String[]> grabStorageUsageData(String hostURL, String sessionID, String orgID) {
        String pageContent;
        if (!Test.isRunningTest()) {
            pageContent = ClientOrgStatusWebservice.getPageContent(hostURL, sessionID, '/setup/org/orgstorageusage.jsp?id=' + orgID).replaceAll('&nbsp;', ' ');
        } else {
            pageContent = ClientOrgStatusWebservice.getTestStorageUsagePage();
        }
        String[] storageTypes = new String[]{'Data Storage', 'File Storage'};

        Map<String, String[]> clientStorageData = new Map<String, String[]>();
        for (String storageType : storageTypes) {
            clientStorageData.put(storageType, ClientOrgStatusWebservice.getDataForStorageType(storageType, pageContent));
        }

        return clientStorageData;
    }

    public static String[] getDataForStorageType(String storageType, String pageData) {
        System.debug('StorageType: ');
        System.debug(storageType);
        System.debug('Page Data: ');
        System.debug(pageData);
        Matcher storageTypeMatcher = Pattern.compile('<tr[\\sA-Za-z="(.){;}]*><th[\\sA-Za-z="]*>' + storageType + '</th><td[\\sA-Za-z="]*>([0-9\\sA-Za-z.]*)</td><td[\\sA-Za-z="]*>([\\s0-9.A-Za-z]*)</td><td[\\sA-Za-z="]*>([0-9%]*)</td></tr>').matcher(pageData);
        String[] returnData = new String[3];
        if (storageTypeMatcher.find()) {
            returnData[0] = storageTypeMatcher.group(1);
            returnData[1] = storageTypeMatcher.group(2);
            returnData[2] = storageTypeMatcher.group(3);
        }
        return returnData;
    }

    public static String getPageContent(String hostURL, String sessionID, String url) {
        String requestURL = hostURL + url;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(requestURL);
        req.setMethod('GET');
        req.setHeader('Cookie', 'sid=' + sessionID);
        String resultBody;
        try {
            resultBody = new Http().send(req).getBody();
        } catch (Exception e) {
            System.debug('Exception occurred while attempting to load: ' + requestURL + ' | ' + e.getMessage() + ' | At Line: ' + e.getLineNumber());
        }
        return resultBody;
    }

    public class ClientInfo {
        public String orgID;
        public Map<String, Integer[]> licenseData;
        public Map<String, String[]> storageData;

        public ClientInfo(String orgID, Map<String, Integer[]> licenseData, Map<String, String[]> storageData) {
            this.orgID = orgID;
            this.licenseData = licenseData;
            this.storageData = storageData;
        }
    }

    public static String getTestLicensePage() {
        return '<tr class=" dataRow even first" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Marketing User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">2</td><td class=" dataCell  numericalColumn">1</td><td class=" dataCell  numericalColumn">1</td></tr><!-- ListRow --><tr class=" dataRow odd" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Apex Mobile User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">2</td><td class=" dataCell  numericalColumn">1</td><td class=" dataCell  numericalColumn">1</td></tr><!-- ListRow --><tr class=" dataRow even" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Offline User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">2</td><td class=" dataCell  numericalColumn">1</td><td class=" dataCell  numericalColumn">1</td></tr><!-- ListRow --><tr class=" dataRow odd" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Knowledge User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">2</td><td class=" dataCell  numericalColumn">0</td><td class=" dataCell  numericalColumn">2</td></tr><!-- ListRow --><tr class=" dataRow even" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Force.com Flow User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">3</td><td class=" dataCell  numericalColumn">0</td><td class=" dataCell  numericalColumn">3</td></tr><!-- ListRow --><tr class=" dataRow odd" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Service Cloud User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">2</td><td class=" dataCell  numericalColumn">1</td><td class=" dataCell  numericalColumn">1</td></tr><!-- ListRow --><tr class=" dataRow even" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Live Agent User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">2</td><td class=" dataCell  numericalColumn">0</td><td class=" dataCell  numericalColumn">2</td></tr><!-- ListRow --><tr class=" dataRow odd" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Site.com Contributor User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">1</td><td class=" dataCell  numericalColumn">0</td><td class=" dataCell  numericalColumn">1</td></tr><!-- ListRow --><tr class=" dataRow even" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Site.com Publisher User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">2</td><td class=" dataCell  numericalColumn">0</td><td class=" dataCell  numericalColumn">2</td></tr><!-- ListRow --><tr class=" dataRow odd" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Chatter Answers User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">25</td><td class=" dataCell  numericalColumn">0</td><td class=" dataCell  numericalColumn">25</td></tr><!-- ListRow --><tr class=" dataRow even last" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Salesforce CRM Content User</th><td class=" dataCell  ">Active</td><td class=" dataCell  numericalColumn">2</td><td class=" dataCell  numericalColumn">0</td><td class=" dataCell  numericalColumn">2</td></tr>';
    }

    public static String getTestStorageUsagePage() {
        return '<tr class=" dataRow even first" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">Data Storage</th><td class=" dataCell  numericalColumn">250.0&nbsp;MB</td><td class=" dataCell  numericalColumn">1.3&nbsp;MB</td><td class=" dataCell  numericalColumn">1%</td></tr><!-- ListRow --><tr class=" dataRow odd last" onblur="if (window.hiOff){hiOff(this);}" onfocus="if (window.hiOn){hiOn(this);}" onmouseout="if (window.hiOff){hiOff(this);}" onmouseover="if (window.hiOn){hiOn(this);}"><th scope="row" class=" dataCell  ">File Storage</th><td class=" dataCell  numericalColumn">250.0&nbsp;MB</td><td class=" dataCell  numericalColumn">110&nbsp;KB</td><td class=" dataCell  numericalColumn">0%</td></tr>';
    }
}