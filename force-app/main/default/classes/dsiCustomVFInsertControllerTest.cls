@isTest
public class dsiCustomVFInsertControllerTest {
 static testMethod void dsiCustomVFInsertControllerMethod() {
     
     Data_Source__c dsc = new Data_Source__c();
     dsc.Data_Source_Code__c ='a';
      insert dsc;
     
      
     Data_Source_Information__c ds = new Data_Source_Information__c();
     ds.Evaluation_Date__c = System.today();
     ds.Data_Source__c = dsc.Id;
     insert ds;
     
     ApexPages.StandardController sc = new ApexPages.StandardController(dsc);
     dsiCustomVFInsertController dsiC = new dsiCustomVFInsertController(sc);
     dsiC.pageLoad();
     dsiC.gridData();
     dsiC.picklistData();
     
 }
}