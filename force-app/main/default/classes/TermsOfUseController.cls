/*===========================================================================
     Added to RK base RMIS product as  05/15/2014
    ===========================================================================*/
  
global class TermsOfUseController {

    // AD 9/24/2012 PST-00003842
    
    @RemoteAction
    global static Integer isTOUAgreedJSR() {
        Integer z= 0;
        User u = [SELECT Terms_of_Use__c FROM User WHERE Id =: UserInfo.getUserId()];
        
        if (!u.Terms_of_Use__c) {
            z = 1;
        }
        return z;
    }
    
    webService static Integer isTOUAgreed () {
       Integer z = 0;
       User u = [Select  Terms_of_Use__c 
                  From   User 
                  Where  Id =: UserInfo.getUserId()];         

       if(u.Terms_of_Use__c == false) z = 1;
       return z;
    }
    
    
    public PageReference checkTOU () {
        String HomePageUrl = '/home/home.jsp?noredirect=1';
        String TOUPageURL = '/apex/TermsOfUse';       
        
        PageReference page = new PageReference(HomePageUrl); 
        
        User u = [Select Profile.Name, Terms_of_Use__c 
                  From   User 
                  Where  Id =: UserInfo.getUserId()]; 
        
        //if (u.Profile.Name != 'System Administrator') {         
            if (u.Terms_of_Use__c == false) page = new PageReference(TOUPageURL);
        //}  
        
        page.setRedirect(true);  
        return page;     
    }
    
    public PageReference save() {
        User u = [Select Terms_of_Use__c 
                  From   User 
                  Where  Id =: UserInfo.getUserId()];                 
        u.Terms_of_Use__c = true;
        u.Terms_of_Use_Acceptance_Date__c = System.now();
        update u;
        
        PageReference page = new PageReference('/home/home.jsp');
        return Page;
    }
    
    public PageReference cancel() {
        PageReference page = new PageReference('/secur/logout.jsp');
        return Page;
    }   
    
 /*
    @isTest (seealldata=true) 
    public static void testTermsOfUseController (){ 
        TermsOfUseController tuo = new TermsOfUseController();
        tuo.checkTOU();
        tuo.save();
        tuo.cancel();
        Integer isTOUAgreedTo = TermsOfUseController.isTOUAgreed();
    } 
    */
}