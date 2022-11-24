/*===========================================================================
     Added to RK base RMIS product as 3/25/2013
===========================================================================*/
public with sharing class ClaimLetterExt {
//DBR: New Implementation 4/7/2014
        ApexPages.StandardController controller;
        public Claim__c cl {get;set;}
        public String templateAPIName {get; set;}
        public String templateName {get; set;}
        public String letterType {get; set;}       


        public ClaimLetterExt(ApexPages.StandardController c) {
                controller = c;
                cl = (Claim__c) c.getRecord();
        }
        
        //intercept save if needed
        public PageReference save() {
                PageReference p = controller.save();
                id toId = controller.getId(); //Claim Id
                return p;
        }
        
        /*
        // MDU:
        static PageReference apexPageRef(String pageName) {
            String extURL = URL.getCurrentRequestUrl().toExternalForm();
            if (Test.isRunningTest()) {
                return new PageReference('/apex/' + pageName);
            }
            System.assert(Pattern.compile('(?i)/apex/.+$').matcher(extURL).find(), 'Expected /apex currentURL; got: ' + extURL);
            //System.assert(false, extURL.replaceFirst('(?i)/apex/.+$', '/apex/' + pageName));
            return new PageReference(extURL.replaceFirst('(?i)/apex/.+$', '/apex/' + pageName.toLowerCase()));
        }
        */
    
        public PageReference attachLetter() {
                //Get reference to VisualForce Template
                try{
                    //PageReference richTextMergePage = apexPageRef(templateAPIName);
                    //PageReference richTextMergePage = Page.mmReleaseGeneral;
                    
                    // MDU: April 23, 2014 -- See https://success.salesforce.com/issues_view?id=a1p30000000T3HFAA0 for the prescribed solution
                    // to this Spring '14 "bug" (wouldn't be surprised to see them come out later and rebrand this as a "security feature").
                    // Unfortunately, static page reefernces suck (despite salesforce's assertion that they rock), and won't facilitate the
                    // functionality we're trying to achieve here. Initially, a dynamically constructed absolute-URL for the desired page was
                    // working (see apexPageRef method above). Unfortunately that seems to have broken recently; internally the getContent()
                    // callout gets redirected to the login page. Now, it seems that dynamic relative URLs work again IF the Apex page name
                    // is lower-case'd -- note that this mirrors the external/toString form of a static PageReference, which is how I decided
                    // to try this approach:
                    PageReference richTextMergePage = new PageReference('/apex/' + templateAPIName.toLowerCase());
                    //Pass in parent object Id so merge fields can be accessed
                    richTextMergePage.getParameters().put('id',cl.id);
                                        
                    //Get merged HTML from Visual Force Page
                    Blob content = richTextMergePage.getContent();
                    //Convert HTML to string
                    String htmlContent = content.toString();
                    
                    //Create new letter object and attach to parent obj
                    Letter__c l = new Letter__c(Claim_Reference__c = cl.id, name= templateName, Letter_Text_Body__c = htmlContent, Letter_Type__c = letterType, Letter_Template__c = templateAPIName);
                    insert l;
                    //Redirect to the letter edit page so content can be edited
                    return new PageReference('/'+l.id+'/e?retURL=%2F'+l.id);
                }catch(System.Exception e){
                    System.debug(e.getMessage());
                     return new PageReference('/apex/mmChooseLetterDDErrorHandler');
                }
        }

}