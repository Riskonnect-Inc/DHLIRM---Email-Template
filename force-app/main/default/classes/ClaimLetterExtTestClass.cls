/*===========================================================================
    Added to RK base RMIS product as 3/25/2013
===========================================================================*/
@isTest(SeeAllData=true)
private class ClaimLetterExtTestClass {
    static testMethod void validateClaimLetterExt() {
      Claim__c c;
      try{
          c = [SELECT Id,Name FROM Claim__c limit 1];
      }catch (System.QueryException e) {
          System.debug('Didnt find Claim!');
          c=null;
      }
      if (c != null){
           System.debug('Got Test Claim: ' + c.Name);
           ApexPages.StandardController sc = new ApexPages.StandardController(c);
           ClaimLetterExt ce = new ClaimLetterExt(sc);
        
          //Created controller, Now test ClaimLetterExt Methods...
          
          //test setters
          String templateAPIName = 'mmGenBlank';
          String templateName = 'Test Letter Created '+date.today();
          String letterType ='General';
          ce.templateAPIName = templateAPIName;
          ce.templateName = templateName;
          ce.letterType = letterType;
          //test getters
          System.assertEquals(ce.templateAPIName, templateAPIName);
          System.assertEquals(ce.templateName, templateName);
          System.assertEquals(ce.letterType, letterType);
          //Test Attaching Letter
          PageReference pr = ce.attachLetter();
          System.assert(pr != null);
          //Test error catch for letter
          ce.templateAPIName = 'NonExistant';
          PageReference pr2 = ce.attachLetter();
          System.assert(pr2 != null);
          //Test Save method
          PageReference pr3 = ce.save();
          System.assert(pr3 != null);
        }else{
           System.debug('query returned null');   
        }
    }
}