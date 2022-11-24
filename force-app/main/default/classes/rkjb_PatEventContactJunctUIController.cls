global with sharing class rkjb_PatEventContactJunctUIController extends rkl.RKPortalController_2{
    public Object config {get; private set;}
    public String dropBackAnchor {get; private set;}

    public rkjb_PatEventContactJunctUIController(){this(null);}
    public rkjb_PatEventContactJunctUIController(rkl.JS_Search ign) {
        init();
    }

    public void init(){
        
        Map<String, Object> junctionInfo = new Map<String, Object>{//Junction
            'objectApi'=> 'Contact_Roles__c',
            'editFieldSet'=> 'junctionEditFields',
            'leftSideParentField'=> 'Patient_Event__c',
            'rightSideParentField'=> 'Contact__c',
            'duplicateCheck' => true
        };

        Map<String, Object> leftSideInfo = new Map<String, Object>{//Config
            
            
            'results'=> 'junctionResults',
            'baseCondition'=> ''
        };

        Map<String, Object> rightSideInfo = new Map<String, Object>{//Control
            
             'filters'=> 'junctionFilters', 
            'results'=> 'junctionResults',
            'baseCondition'=> ''
        };

        rkl.JunctionSerializer js = new rkl.JunctionSerializer(new Map<String, Map<String, Object>>{
            'junction' => junctionInfo,
            'left' => leftSideInfo,
            'right' => rightSideInfo
        });

        String recordId = System.currentPagereference().getParameters().get('id');

        js.addId(recordId);

        config = JSON.serialize(js.build());

        String lookupField;

        String idObjectApi = ((Id)recordId).getSobjectType().getDescribe().getName();
        String leftObjectApi = String.valueOf(rkl.DescribeHandler.getFieldDescribe('Contact_Roles__c', 'Patient_Event__c').getReferenceTo()[0]);
        if(idObjectApi == leftObjectApi){
            lookupField = 'Patient_Event__c';
        } else{
            lookupField = 'Contact__c';
        }

        sObject[] anchorFetch = [SELECT DurableId FROM FieldDefinition WHERE EntityDefinitionId = 'Contact_Roles__c' AND QualifiedApiName =: lookupField];
        if(anchorFetch.size()==1){
            String[] dId = ((String)anchorFetch[0].get('DurableId')).split('\\.');
            dropBackAnchor = '#'+recordId+'_'+dId[1]+'_target';
        } else{
            dropBackAnchor = '';
        }

        

    }
    


        @RemoteAction
        global static Object retrieveTemplate(Map<String, Object> config) {

            //Pull template name from config and do something with it
            String templateName = (String)config.get('templateName');

            // Template Definitions
            
            
                                
                if(templateName == 'Contact_Roles__c') {
                    return rkl.RKPBuilder.createBuilder('junctionEditFields', 'Contact_Roles__c')
                        .fieldsetSection('junctionEditFields', 'junctionEditFields')
                        .finalize();
                }
                
            return null;
        }
    

    /* 
    junctionData
    {
        "objectApi": "Contact_Roles__c",
        "blockDuplicated": true,
        "name": "PatEventContactJunctUI",
        "editFieldSet": "junctionEditFields",
        "left.lookupField": "Patient_Event__c",
        "left.objectApi": "Patient_Event__c",
        "left.filterFieldset": "",
        "left.resultFieldset": "junctionResults",
        "left.criteriaOn": false,
        "left.criteria": "",
        "left.creationAllowed": false,
        "left.creationFieldset": "",
        "left.creationRecordType": "",
        "right.lookupField": "Contact__c",
        "right.objectApi": "Contact",
        "right.filterFieldset": "junctionFilters",
        "right.resultFieldset": "junctionResults",
        "right.criteriaOn": false,
        "right.criteria": "",
        "right.creationAllowed": false,
        "right.creationFieldset": "",
        "right.creationRecordType": ""
    }
    junctionData
    */

}