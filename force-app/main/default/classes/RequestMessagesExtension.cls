/*===========================================================================
     Added to RK base RMIS product as 04/08/2014
    ===========================================================================*/
    
public class RequestMessagesExtension{
/*
    private ApexPages.StandardController standardController;

    public RequestMessagesExte(ApexPages.StandardController standardController) {
        this.standardController = standardController;
        this.standardController.addFields(new List<String> { 'Governance__r' });
    
    }
*/
    public List<Request_Messages__c> getRequestMessages() {
        return [SELECT Id, Message_Header__c, Section_1__c, Section_2__c, Section_3__c, Section_4__c 
                FROM Request_Messages__c 
                ORDER BY CREATEDDATE DESC
                LIMIT 1
                ];
                
                }


    public String messageHeader
    {
        get {return [SELECT Message_Header__c FROM Request_Messages__c ORDER BY CREATEDDATE DESC LIMIT 1].Message_Header__c; }
        set;
    }
    
        public String section1
    {
        get {return [SELECT Section_1__c FROM Request_Messages__c ORDER BY CREATEDDATE DESC LIMIT 1].Section_1__c; }
        set;
    }
    
        public String section2
    {
        get {return [SELECT Section_2__c FROM Request_Messages__c ORDER BY CREATEDDATE DESC LIMIT 1].Section_2__c; }
        set;
    }
    
        public String section3
    {
        get {return [SELECT Section_3__c FROM Request_Messages__c ORDER BY CREATEDDATE DESC LIMIT 1].Section_3__c; }
        set;
    }
    
        public String section4
    {
        get {return [SELECT Section_4__c FROM Request_Messages__c ORDER BY CREATEDDATE DESC LIMIT 1].Section_4__c; }
        set;
    }

}