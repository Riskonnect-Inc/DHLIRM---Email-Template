/*===========================================================================
     Added to RK base RMIS product as  06/01/2015
    ===========================================================================*/
public with sharing class CreateNewPropertyController extends rkl.RKPortalController_2 {
    public string userEmail{get; private set;}

    public CreateNewPropertyController(){
        this(null);
    }
    
    public CreateNewPropertyController(rkl.JS_Search ignore) {
      userEmail = System.currentPagereference().getParameters().get('userEmail');
    }
    
    //No authorization is required since we are bypassing the login page by sending the direct link to the user email
   
    public rkl.RKPortalBuilder.Section section(String name, String label, List<String> fieldSetNames) {
        rkl.RKPortalBuilder.Section sec = new rkl.RKPortalBuilder.Section(name, label);
        for(String fs: fieldSetNames) {
            sec.add(new rkl.RKPortalBuilder.FieldSet(fs));
        }
        return sec;
    }
    public override String getUIBuilderJS() {
        rkl.RKPortalBuilder.Portal currentPortal = (new rkl.RKPortalBuilder.Portal('CreateNewPropertyController', 'Property__c', '"#newPropertyRoot"')
                    .add(section('New_Property_Information', 'Property Information', new List<String>{'New_Property_Information'}))
                    .add(section('PVC_COPE', 'COPE', new List<String>{'PVC_COPE'}))
                    .add(new rkl.RKPortalBuilder.Section('Submit', 'Submit')
                    .add(new rkl.RKPortalBuilder.PlainLabel('Submit_Instructions_1', 'Please review all preceding sections before clicking the \\"Submit\\" button below.'))
                    .add(new rkl.RKPortalBuilder.PlainLabel('Submit_Instructions_2', 'You will be unable to change your provided answers once \\"Submit\\" is clicked.'))
                    .add(new rkl.RKPortalBuilder.Attachments('Attachments', 'Attachments'))
                ));
        return currentPortal.toJS();
    }
}