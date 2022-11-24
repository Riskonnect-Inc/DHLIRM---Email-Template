/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
 ===========================================================================*/
    
global class PropertyPortalLandingController {
    public String userEmail{get;private set;}

    public PropertyPortalLandingController() {
        this.userEmail = ApexPages.currentPage().getParameters().get('userEmail');
        System.assert(userEmail != null, 'There is no userEmail to bypass authentication.');
        }
    
    //Since authorization is bypassed, we no longer need auth cookie related methods
    @RemoteAction
    global static PropertyRecordPage getRecords(Integer offset, Integer pageSize, string userEmail) {
        PropertyRecordPage page = new PropertyRecordPage();
        set<Id> propIds = new Set<Id>();
        for(Property__c p: [select id, Current_Property_Value__r.Property_Value_Control__r.status__c, Current_Property_Value__r.Values_Collection_Email__c from Property__c where values_collection_Email__c =: userEmail AND Values_Collection_Flag__c = true]){
            if(p.Current_Property_Value__r.Property_Value_Control__r.status__c == 'In Progress')
                propIds.add(p.Id);
            if(p.Current_Property_Value__r.Values_Collection_Email__c != null)
                propIds.add(p.Id);
        }
        page.offset = offset;
        page.total = [select count() from Property__c where values_collection_Email__c =: userEmail AND Values_Collection_Flag__c = true];
        page.records = new List<PropertyRecord>();
        for(Property__c r: [select id, name, Address_Line1__c, Address_Line2__c, city__c, state__c, Zip_Code__c, country__c,values_collection_Email__c, PVC_Status__c from Property__c where values_collection_Email__c =: userEmail AND Values_Collection_Flag__c = true AND Id IN: propIds order by createdDate desc limit :pageSize offset :offset]) {
            PropertyRecord nr = new PropertyRecord();
            nr.id = r.id;
            nr.propertyName = r.name;
            nr.addressLine1 = r.Address_Line1__c;
            nr.addressLine2 = r.Address_Line2__c;
            nr.city = r.city__c;
            nr.state = r.State__c;
            nr.postalCode = r.Zip_Code__c;
            nr.country = r.Country__c;
            nr.valuesCollectionEmail = r.Values_Collection_Email__c;
            nr.PVCStatus = r.PVC_Status__c;
            page.records.add(nr);
        }
        return page;
    }
    global class PropertyRecordPage {
        public Integer offset {get; set;}
        public Integer total {get; set;}
        public List<PropertyRecord> records {get; set;}
    }
    global class PropertyRecord {
        public String id {get; set;}
        public String propertyName {get; set;}
        public String addressLine1 {get; set;}
        public String addressLine2 {get; set;}
        public String city {get; set;}
        public String state {get; set;}
        public String postalCode {get; set;}
        public String country {get; set;}
        public String valuesCollectionEmail {get; set;}
        public String PVCStatus {get; set;}
    }
}