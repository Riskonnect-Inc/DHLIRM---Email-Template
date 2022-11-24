/*===========================================================================
     Added to RK base RMIS product as 06/01/2015
    ===========================================================================*/
/*
 * USE CASES:
 * 1. Unbatched, for Properties < 1000
 * PropertyValuesUtil.createPropertyValues(pvc);
 * PropertyValuesUtil.instance().makeAdjustments();
 * PropertyValuesUtil.instance().readyRenewal();
 * // ... fire off batches to email
 *
 * 2. Batched, create Properties
 * PropertyValuesUtil.createPropertyValues(pvc, batchedProperties);
 * PropertyValuesUtil.instance().makeAdjustments();
 *
 * 3. Batched, ready renewal
 * PropertyValuesUtil.init(pvc, batchedValues).readyRenewal();
 *
 */
public class PropertyValuesUtil {
    private Property_Value_Control__c pvc = null;
    private Map<Id, Property__c> properties = null;
    private Map<Id, Property_Value__c> propertyValues = null;
    private Map<Id, Property_Value__c> currentValues = null;
    
    public class PVU_Init_Exception extends Exception {}
    
    private static List<Schema.FieldSetMember> getFields() {
        return SObjectType.Property_Value__c.FieldSets.Adjusted_Values.getFields();
    }
    
    /*private static List<Property_Value__c> getPriorPropertyValues(List<Id> priorPropValIds) {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, Name FROM Property_Value__c where id IN '+ '(\'' + String.join(priorPropValIds, '\',\'') + '\')';
        return Database.query(query);
    }*/
    
    private static PropertyValuesUtil instance = null;
    
    public static void unbatchedUtil(Property_Value_Control__c pvc) {
        
        List<Property_Values_Email__c> propEmail = new List<Property_Values_Email__c>();
        Set<String> emailSet = new Set<String>();
        List<String> toAddressList ;
        
        createPropertyValues(pvc);
        instance.makeAdjustments();
        instance.readyRenewal();
        
        update instance.properties();
        update instance.propertyValues();
        
        pvc.Status__c = 'In Progress';
        pvc.total_property_values_assigned__c = instance.properties().size();
        update pvc;
        
        //Do we need to check something to make sure on the success before sending out emails? 
        //Or we could just assume that everything went on well if we have reached this part of the code
        
        /* Below code handles email notification part. 
         *  step 1: Delete all records in the Property_Values_Email__c
         *  step 2: Iterate over the properties to get a set of unique email IDs
         *  step 3: Insert one Property_Values_Email__c record for each unique email ID
         */ 
         
        if(pvc.Email_Option__c == 'One per person'){
            propEmail = [select id from Property_Values_Email__c];
            delete propEmail;
            List<Property_Values_Email__c> pvEmailToInsert = new List<Property_Values_Email__c>();
            for(Property__c p : instance.properties()){
                emailSet.add(p.values_collection_email__c);
            }
            toAddressList = new List<String>(emailSet);
            for(String eAddress : toAddressList){
                Property_Values_Email__c pEmail = new Property_Values_Email__c();
                pEmail.Evaluation_Date__c = pvc.Evaluation_Date__c;
                pEmail.Values_Collection_Email__c = eAddress;
                //pEmail.Email_text__c = pvc.Email_Text__c;
                pEmail.property_value_control__c = pvc.id;
                pvEmailToInsert.add(pEmail);
            }
            insert pvEmailToInsert;
        }else if(pvc.Email_Option__c == 'One per property'){
            for(Property__c p : instance.properties()){
                p.Values_Collection_Email_Flag__c = true;
            }
            update instance.properties();           
        }
    }
    
    public static void createPropertyValues(Property_Value_Control__c pvc) {
        List<Property__c> props = [select id, values_collection_email__c, Prior_Property_Value__c, current_property_value__c  from property__c where Values_Collection_Flag__c = true];
        createPropertyValues(pvc, props);
    }
    
    public static void createPropertyValues(Property_Value_Control__c pvc, List<Property__c> props) {
        List<Property_Value__c> propVals = new List<Property_Value__c>();
        for(property__c p : props){
            property_value__c pv = new property_value__c();
            pv.property__c = p.id;
            pv.values_collection_email__c = p.values_collection_email__c;
            pv.evaluation_date__c = pvc.evaluation_date__c; 
            pv.property_value_control__c = pvc.Id;
            
            propVals.add(pv);
        }
        
        insert propVals;
        
        if(instance == null) {
            instance = new PropertyValuesUtil(pvc, propVals, props);
        }
        
       // return propVals;
    }
    
    public static PropertyValuesUtil instance() {
        return instance;
    }
    
    public static PropertyValuesUtil init(Property_Value_Control__c pvc, List<Property_Value__c> propVals) {
        if(instance == null) {
            instance = new PropertyValuesUtil(pvc, propVals);
        }
        return instance;
    }
    
    public PropertyValuesUtil(Property_Value_Control__c pvc, List<Property_Value__c> propVals) {
        this(pvc, propVals, null);
    }

    public PropertyValuesUtil(Property_Value_Control__c pvc, List<Property_Value__c> propVals, List<Property__c> props) {
        this.pvc = pvc;
        propertyValues = new Map<Id, Property_Value__c>(propVals);
        if(props != null) {
            properties = new Map<Id, Property__c>();
        }
    }

    public List<Property_Value__c> propertyValues() {
        return propertyValues.values();
    }

    public List<Property__c> properties() {
        if(properties == null || properties.size() == 0) {
            List<Property__c> props = [select id, values_collection_email__c, Prior_Property_Value__c, current_property_value__c  from property__c where Values_Collection_Flag__c =true];
            properties = new Map<Id, Property__c>(props);
            return props;
        } else {
            return properties.values();
        }
    }
    
     private static List<Property_Value__c> getCurrentPropertyValues(List<Id> currentPropValIds) {
    system.debug('srs currentPropValIds = '+currentPropValIds);
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : getFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, Name FROM Property_Value__c where id IN '+ '(\'' + String.join(currentPropValIds, '\',\'') + '\')';
        system.debug('srs7 = '+Database.query(query));
        return Database.query(query);
    }

    public List<Property_Value__c> currentValues() {
        if(properties == null || properties.size() == 0) {
            properties();
            system.debug('srs creating props');
        }
    
        if(currentValues == null || currentValues.size() == 0) {
            Set<String> ids = new Set<String>();
            system.debug('srs creating prop');
            
            for(Property__c prop : properties.values()) {
            system.debug('srs8 ='+properties.values());
                if(prop.current_property_value__c != null) {
                    ids.add(prop.current_property_value__c);
                }
            }
            currentValues = new Map<Id, Property_Value__c>(getCurrentPropertyValues(new List<String>(ids)));
            system.debug('srs currentValues = '+currentValues);
        }
        return currentValues.values();
    }
    
    public void makeAdjustments() {
        Double adjustmentRate = pvc.adjustment_rate__c;
        if(adjustmentRate != null) {
            currentValues();
            for(Property_Value__c pv : propertyValues.values()) {
                system.debug('srs still not there');
                Property__c prop = properties.get(pv.property__c);
                Property_Value__c cur = currentValues.get(prop.current_property_value__c);
                if(cur != null) {
                    system.debug('srs well done');
                    for(Schema.FieldSetMember f : getFields()) {
                        String thisField = f.getFieldPath();
                        Object o = cur.get(thisField);
                        if(o != null && o instanceof Decimal) {
                            Decimal val = (Decimal)o;
                            pv.put(thisField, (Integer)(val + val * adjustmentRate / 100.0));
                        } else if(o != null && o instanceof Double) {
                            Double val = (Double)o;
                            pv.put(thisField, (Integer)(val + val * adjustmentRate / 100.0));
                        } else if(o != null && o instanceof Integer) {
                            Integer val = (Integer)o;
                            pv.put(thisField,(Integer) (val + val * adjustmentRate / 100.0));
                        } else if(o != null && o instanceof Long) {
                            Long val = (Long)o;
                            pv.put(thisField, (Integer)(val + val * adjustmentRate / 100.0));
                        }
                        
                        system.debug('SRS pv adjusted vals = '+pv.get(thisField));
                    }
                }
            }
            
            //update propertyValues.values();
        } 
    }
    
    public void readyRenewal() {
        properties();
        for(Property_Value__c pv : propertyValues.values()) {
            pv.Renewal_Build_Complete__c = true;
            
            Property__c prop = properties.get(pv.property__c);
            prop.prior_property_value__c = prop.current_property_value__c;
            prop.current_property_value__c = pv.id;            
        }
    }
    
    public void resetRenewal() {
        properties();
        for(Property_Value__c pv : propertyValues.values()) {
            Property__c prop = properties.get(pv.property__c);
            if(pv.id == prop.current_property_value__c) {
                prop.current_property_value__c = prop.prior_property_value__c;  
                prop.prior_property_value__c = null;
            }
        }
    }
    
}