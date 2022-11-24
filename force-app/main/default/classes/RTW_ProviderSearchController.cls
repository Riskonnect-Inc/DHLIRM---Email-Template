/*===========================================================================
     Added to RK base RMIS product as 4/15/2016
    ===========================================================================*/
    
public class RTW_ProviderSearchController {
    
    public Claim__c thisClaim {get;set;}
    public Id thisClaimID {get;set;}
    private RTW_Assessment__c thisAssessment;
    public Boolean loadPicklistFromData = ApexPages.currentPage().getParameters().get('PicklistFromData')=='n'||ApexPages.currentPage().getParameters().get('PicklistFromData')=='N'?false:true;

    
    public double geoLat {get;set;}
    public double geoLon {get;set;}
    
    public string providerType {get;set;}
    public string providerSpecialization {get;set;}
    public double distanceRange {get;set;}
    
    public boolean renderAsPDF {get; private set;}
    public string renderAs {get; private set;}
    
    private string query;
    
    public RTW_ProviderSearchController(ApexPages.StandardController sc){
        thisAssessment = (RTW_Assessment__c)sc.getRecord();
        thisClaimID = [select Claim__c from RTW_Assessment__c where Id = :thisAssessment.Id].Claim__c;
        
        distanceRange = ApexPages.currentPage().getParameters().get('dist')==Null?5:double.valueof(ApexPages.currentPage().getParameters().get('dist'));
        providerType = ApexPages.currentPage().getParameters().get('pType');
        providerSpecialization = ApexPages.currentPage().getParameters().get('pSpecialization');
        
        renderAsPDF = ApexPages.currentPage().getParameters().get('printable')=='1';
        renderAs = renderAsPDF?'pdf':'';
    }
    
    public void init(){
        thisClaim = [select id,claimant_address_line1__c,Claimant_City__c,Claimant_State__c,Claimant_Postal_Code__c, /*gLocation__c,*/ 
                                  glocation__latitude__s,glocation__longitude__s from claim__c where id = :thisClaimID  limit 1]; 
        
        geoLat = thisClaim.gLocation__Latitude__s;
        geoLon = thisClaim.gLocation__Longitude__s;
        
        query =     'SELECT Id, Name, Primary_Location__c, MailingAddress, ';
        query +=     'MailingStreet, MailingCity, MailingState, MailingPostalCode, ';
        query +=     'Email, Phone, Healthcare_Provider_Type__c, Specialization__c, ';
        query +=     'distance(Primary_Location__c, geolocation(:geoLat,:geoLon),\'mi\') dist ';
        query +=    'from Contact ';
        query +=    'where RecordType.DeveloperName = \'Physician\' ';
        query +=     'AND distance(Primary_Location__c, geolocation(:geoLat,:geoLon),\'mi\') < ' + string.valueOf(distanceRange);
        
        if (providerType != null) {
            query += 'AND Healthcare_Provider_Type__c = \'' + providerType + '\' ';
        }
        
        if (providerSpecialization != null) {
            query += 'AND Specialization__c = \'' + providerSpecialization + '\' '; 
        }
        
        query +=    'ORDER BY distance(Primary_Location__c, geolocation(:geoLat,:geoLon),\'mi\') ASC';
    }
    
    public SelectOption[] getTypeOptions() {       
        Schema.DescribeFieldResult F = Contact.Healthcare_Provider_type__c.getDescribe();
        List<Schema.PicklistEntry> pickListItems = F.getPicklistValues();  
        SelectOption[] options = new SelectOption[] {};
        options.add(new SelectOption('','--All--' ));
        if(loadPicklistFromData){  
            List<AggregateResult> pList = [Select Healthcare_Provider_type__c ptype ,count(id) freq from Contact group by Healthcare_Provider_type__c ];        
            if (pList != null) {
                for (AggregateResult ar : pList) {
                    string pvar = string.valueOf(ar.get('ptype'));
                    if(pvar!=null){options.add(new SelectOption(pvar, pvar));}
                }                
            }
        } else {
            for (Schema.PicklistEntry pk : pickListItems ) {         
                options.add(new SelectOption(pk.getvalue(), pk.getvalue()));
            }  
        }
        return options;     
    }//end SelectOption
    
    public SelectOption[] getSpecializationOptions() {       
        Schema.DescribeFieldResult F = Contact.Healthcare_Provider_type__c.getDescribe();
        List<Schema.PicklistEntry> pickListItems = F.getPicklistValues();  
        SelectOption[] options = new SelectOption[] {};
        options.add(new SelectOption('','--All--' ));
        if(loadPicklistFromData){  
            List<AggregateResult> pList = [Select Specialization__c ptype ,count(id) freq from Contact group by Specialization__c ];        
            if (pList != null) {
                for (AggregateResult ar : pList) {
                  string pvar = string.valueOf(ar.get('ptype'));
                    if(pvar!=null){options.add(new SelectOption(pvar, pvar));}
                }                
            }
        }
            else {
                for (Schema.PicklistEntry pk : pickListItems ) {         
                    options.add(new SelectOption(pk.getvalue(), pk.getvalue()));
                }  
            }
        return options;     
    }
    
    public class PotentialProvider {
        public Contact providerContact {get;set;}
        public decimal distanceFromClaimant {get;set;}
        
        public PotentialProvider(Contact c){
            providerContact = c;
        }
        
        public PotentialProvider(Contact c, double d){
            providerContact = c;
            distanceFromClaimant = d;
        }
    }
    
    @RemoteAction
    public List<PotentialProvider> searchResults {
        get {
            List<Contact> providerContactList = new List<Contact>();
            List<PotentialProvider> resultList = new List<PotentialProvider>();
            /*
            providerContactList = [ select   Id, Name, Primary_Location__c, MailingAddress, 
                                             MailingStreet, MailingCity, MailingState, MailingPostalCode, 
                                             Email, Phone, Healthcare_Provider_Type__c, Specialization__c, 
                                             distance(Primary_Location__c, geolocation(:geoLat,:geoLon),'mi') dist 
                                    from     Contact 
                                    where    RecordType.DeveloperName = 'Healthcare_Provider' 
                                    ORDER BY distance(Primary_Location__c, geolocation(:geoLat,:geoLon),'mi') ASC];
            */
            providerContactList = database.query(query);
            for (Contact c : providerContactList){
                resultList.add(new PotentialProvider(c, (double)c.get('dist')));
            }
            return resultList;
        }
    }
    
    public PageReference doSearch() {
        PageReference resultPage = Page.RTW_ProviderSearchPage;
        resultPage.getParameters().put('id',thisAssessment.id);
        resultPage.getParameters().put('pType',providerType);
        resultPage.getParameters().put('pSpecialization',providerSpecialization);
        resultPage.getParameters().put('dist',string.valueof(distanceRange));
        
        resultPage.setRedirect(true);
        
        return resultPage;
    }
    
    public PageReference resetSearch() {
        PageReference resultPage = Page.RTW_ProviderSearchPage;
        resultPage.getParameters().put('id',thisAssessment.id);
        
        resultPage.setRedirect(true);
        
        return resultPage;
    }
    
    @RemoteAction
    public static string sendEmailResults(string sendTo, Id assessmentID,string providerType, string providerSpecialization, string distanceRange ) {
        try {
            PageReference resultPage = Page.RTW_ProviderSearchPage;
            resultPage.getParameters().put('id',assessmentID);
            resultPage.getParameters().put('pType',providerType);
            resultPage.getParameters().put('pSpecialization',providerSpecialization);
            resultPage.getParameters().put('dist',distanceRange);
            resultPage.getParameters().put('printable','1');
            
            blob convertedPDF = resultPage.getContent();
            
            Messaging.SingleEmailMessage mail = New Messaging.SingleEmailMessage();
            
            mail.setToAddresses(New List<String> {sendTo});
            mail.setSubject('Nearby Healthcare Providers');
            mail.setPlainTextBody('Attached is a list of nearby healthcare providers');
            mail.saveAsActivity = true;
            
            Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
            
            fileAttachment.setBody(convertedPDF);
            fileAttachment.setFileName('SearchResults.pdf');
            fileAttachment.setContentType('application/pdf');
            
            mail.setFileAttachments(new List<Messaging.EmailFileAttachment> {fileAttachment});
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {mail});
            
            return 'Sent';
        } catch(Exception e) {
            return 'Error';
        }
        
    }
    
    @RemoteAction
    public static void selectProvider(Id assessmentID, Id selectedID){
        RTW_Assessment__c assessmentToUpdate = new RTW_Assessment__c(Id = assessmentID, Physician__c = selectedID);
        
        update assessmentToUpdate;
    }
}