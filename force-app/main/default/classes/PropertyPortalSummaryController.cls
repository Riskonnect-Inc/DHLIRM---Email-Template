/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
    ===========================================================================*/
    
public with sharing class PropertyPortalSummaryController {

     public string propId {get; private set;}
     public Property__c prop{get;private set;}
     public string userEmail{get;private set;}
      
     public PropertyPortalSummaryController(){
        propId = System.currentPagereference().getParameters().get('propertyId');
        userEmail = System.currentPagereference().getParameters().get('userEmail');
        List<Property__c> props = [ SELECT Name FROM Property__c WHERE Id =:propId LIMIT 1 ];
        if(props.size() > 0){
          prop = props[0];
        }
      }
}