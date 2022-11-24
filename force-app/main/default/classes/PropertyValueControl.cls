public class PropertyValueControl
    { 
        public Id recId {get;set;}
        public integer numberOfProperties {get;set;}  
        public date evalDate{get;set;} 
        public Boolean okToRunValuesJob {get;set;}  
        public Boolean isOkToRunValuesJob(){return this.okToRunValuesJob == true; }
        public Boolean processAlreadyRunning {get;set;}
        public string description{get;set;}     
        public List<Id> selectedPropertyIds {get;set;}    
        public transient List<Property_Value__c> propertiesWithEvalDateError;  
        public List<Property_Value__c> getpropertiesWithEvalDateError()    {return propertiesWithEvalDateError; }
        public transient List<Property__c> propertiesWithEmailFieldError;   
        public List<Property__c> getpropertiesWithEmailFieldError()    {return propertiesWithEmailFieldError; }
        public Boolean hasPropertyListEmail {get{
                return (this.propertiesWithEmailFieldError != null && this.propertiesWithEmailFieldError.size() > 0);}}
        public String propertyListEmailHtml {get{
                if (this.propertiesWithEmailFieldError == null) {
                    return '';
                }
                String html = '<ul>';
                for (Property__c p : propertiesWithEmailFieldError) {
                    // Be careful to escape variable text embedded in markup!
                    html += '<li><a target="_blank" href="/' + p.Id + '"/>' + p.Name.escapeHtml4() + '</a></li>';
                }
                html += '</ul>';
                return html; }}
        
        public Boolean hasPropertyListEvalDate {get{
            return (this.propertiesWithEvalDateError != null && this.propertiesWithEvalDateError.size() > 0);}}
        
        public String propertyListEvalDateHtml {get{
            if (this.propertiesWithEvalDateError == null) {
                return '';
            }
            String html = '<ul>';
            for (Property_Value__c p : propertiesWithEvalDateError) {
                html += '<li><a target="_blank" href="/' + p.Property__r.Id + '"/>' + p.Property__r.Name.escapeHtml4() + '</a> - Max Evaluation Date : ' + p.property__r.Date_of_Most_Current_Property_Values__c.format() + '</li>';
            }
            html += '</ul>';
            return html;}}
        
        public PropertyValueControl(ApexPages.StandardController ctrl)  {
            selectedPropertyIds = new List<Id>(); 
            recId = ApexPages.currentPage().getParameters().get('controlId');
            okToRunValuesJob = False;
        }
        public PageReference cancel(){
            PageReference gotoControlPage = new PageReference('/'+recId); 
                   gotoControlPage.setRedirect(true);
                   return gotoControlPage;
        }
        public Pagereference startPropertyValues()  {
           String QueryString = 'SELECT count() FROM Property__c where Values_Collection_Flag__c = true';
           Integer numberOfProperties = Database.countQuery(QueryString); 
           if(numberOfProperties > 100 ){
               PropertyValuesInsert batch = new PropertyValuesInsert (recId);
               Id batchId = Database.executeBatch(batch,200); 
           }else{
               Property_Value_Control__c pctrl = [select id, Evaluation_Date__c,email_option__c , adjustment_rate__c from Property_Value_Control__c where id =: recId];
               PropertyValuesUtil.unbatchedUtil(pctrl);        
           }
        
           PageReference gotoFinishPage = new PageReference('/'+recId); 
           gotoFinishPage.setRedirect(true);
           return gotoFinishPage;
        }    
        public Pagereference checkPropertyValues()  { 
            propertiesWithEmailFieldError = new List<Property__c>();
            propertiesWithEvalDateError = new List<Property_Value__c>();
            
            if(okToRunValuesJob) 
                startPropertyValues();
            string siteURL = '';     
            List<Property__c> selectedProperties = new List<Property__c>();
            selectedProperties = [SELECT Id,values_collection_email__c, Name from Property__c where Values_Collection_Flag__c = true];
            
            Property_Value_Control__c propValControl = [select id, Email_Option__c, Evaluation_Date__c, Status__c from Property_Value_Control__c where id =: recId];
            if(propValControl.Status__c == 'In progress' || propValControl.Status__c == 'Complete'){
                processAlreadyRunning = true;
                return null;
            }
            if(propValControl != null){
                evalDate = propValControl.Evaluation_Date__c;
            }
            
            if(selectedProperties != null){
                for(Property__c prop : selectedProperties){
                    selectedPropertyIds.add(prop.Id);
                    if(propValControl.Email_Option__c != 'No emails' && prop.values_collection_email__c == null){
                        propertiesWithEmailFieldError.add(prop);
                    }
                }
                numberOfProperties = selectedProperties.size();
            }
             
            RMIS_Custom_Settings__c s = RMIS_Custom_Settings__c.getOrgDefaults();
            siteURL = s.Property_Values_Site__c  ;
            if (siteURL == Null || siteURL == '' ) {ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,
                     'Property Values is missing the Site URL in the Custom Settings area> RMIS Custom Settings object');
                      ApexPages.addMessage(errormsg);
                      okToRunValuesJob = False;
                      return null;} 
                      
            LIST<Property_Value__c> propVals = new LIST<Property_Value__c> (); 
            propVals = [SELECT evaluation_date__c,property__r.Name,property__r.id,property__r.Date_of_Most_Current_Property_Values__c from Property_value__c where property__r.id IN :selectedPropertyIds AND Most_Recent__c = True];// where Property__r.Property_status__c = :propertyType ]; 
            for(Property_Value__c pVal : propVals)
                  {
                    if(pval.evaluation_date__c >= evalDate){
                        propertiesWithEvalDateError.add(pVal);
                    }
                  }       
              if(propertiesWithEmailFieldError.size() ==0 && propertiesWithEvalDateError.size() == 0){
                    okToRunValuesJob = true;
              }
                     return null;
        }   
}