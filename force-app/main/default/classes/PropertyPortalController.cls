/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
    ===========================================================================*/
    
public class PropertyPortalController extends rkl.RKPortalController_2 {

    public String propId {get; private set;}
    public string userEmail{get; private set;}
    public PropertyPortalController() { 
          propId = System.currentPagereference().getParameters().get('propertyId');
          userEmail = System.currentPagereference().getParameters().get('userEmail');
          if(propId != null && propId.trim() == '') {
            propId = null;
          }
    }

    public PropertyPortalController(rkl.JS_Search ignore) {
        this();
    }
    
    //Since we are bypassing the authentication, no cookie auth methods are required
    
    public rkl.RKPortalBuilder.Section section(String name, String label, List<String> fieldSetNames) {
        rkl.RKPortalBuilder.Section sec = new rkl.RKPortalBuilder.Section(name, label);
        for(String fs: fieldSetNames) {
            sec.add(new rkl.RKPortalBuilder.FieldSet(fs));
        }
        return sec;
    }
    
    public override String getUIBuilderJS() {
        System.debug('PROPID-->'+propId);
        rkl.RKPortalBuilder.Portal currentPortal = (new rkl.RKPortalBuilder.Portal('PropertyPortalController', 'Property__c', propId, '"#propertyPortalRoot"')
               
                .add(section('PVC_Property_Information', 'Property Information', new List<String>{'PVC_Property_Information'}))
                .add(section('PVC_COPE', 'COPE', new List<String>{'PVC_COPE'}))
                .add(new rkl.RKPortalBuilder.ValuesSection(
                    'PVC_Values',
                    'Property Values',
                    'property_value__c',
                    new List<rkl.RKPortalBuilder.VSColumnType> {
                        new rkl.RKPortalBuilder.VSColumnType('prior_property_value__c', 'Prior', true),
                        new rkl.RKPortalBuilder.VSColumnType('current_property_value__c', 'Current', false)
                    },
                    'window.rkl.portal.ui.CmtCommentFieldFinder',
                    '{}',
                    'window.rkl.portal.ui.ControlRecordValidator',
                    '{controlRecordName: "property_value_control__c", controlFieldName: "property_value_control__c", minimumThresholdFieldName: "change_threshold__c"}'
                    ).add(new rkl.RKPortalBuilder.FieldSet('PVC_Values')
                ))
                .add(new rkl.RKPortalBuilder.Section('Submit', 'Submit')
                    .add(new rkl.RKPortalBuilder.PlainLabel('Submit_Instructions_1', 'Please review all preceding sections before clicking the \\"Submit\\" button below.'))
                    .add(new rkl.RKPortalBuilder.PlainLabel('Submit_Instructions_2', 'You will be unable to change your provided answers once \\"Submit\\" is clicked.'))
                    .add(new rkl.RKPortalBuilder.Attachments('Attachments', 'Attachments'))
                )
        );
        return currentPortal.toJS();
    }
}