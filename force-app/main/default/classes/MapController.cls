/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
global with sharing class MapController {

    private final Property__c property;

    global MapController(ApexPages.StandardController controller)
    {
        this.property = (Property__c)controller.getRecord();
    }

    public String getPropertyId()
    {
        return (String)this.property.Id;
    }

    static Map<String, String> fieldToAttr = new Map<String, String> {
        'Id' => 'id',
        'Name' => 'name',
        'Latitude__c' => 'lat',
        'Longitude__c' => 'lng',
        'Address_Line1__c' => 'address',
        'Address_Line2__c' => 'address2',
        'City__c' => 'city',
        'State__c' => 'state',
        'Zip_Code__c' => 'postal',
        'Country__c' => 'country'
    };

    global static String getPropertiesXml(List<Property__c> properties) {
        XmlStreamWriter w = new XmlStreamWriter();
        w.writeStartElement(null, 'markers', null);
        String url = '';

        for (Property__c prop : properties) {
            w.writeStartElement(null, 'marker', null);
            
            for (String key : fieldToAttr.keySet()) {
                w.writeAttribute(null, null, fieldToAttr.get(key), prop.get(key) != null ? (String)prop.get(key) : '');
            }

            //url = '<a href=/00OA0000004Yh03?pv0=' + String.valueOf(prop.Id).subString(0,15) + ' target=_blank>Property Information</a>';
            url = '<a href=www.riskonnect.com target=_blank>Property Information</a>';

            w.writeAttribute(null, null, 'web', url);
            w.writeAttribute(null, null, 'phone', '');
            w.writeAttribute(null, null, 'hours1', '');
            w.writeAttribute(null, null, 'hours2', '');
            w.writeAttribute(null, null, 'hours3', '');
            w.writeEndElement();
        }
        
        w.writeEndElement();

        String output = w.getXmlString();
        w.close();

        return output;
    }
    
    public static Integer PropertyLimit;

    @RemoteAction
    global static String getProperties(Boolean dummy) {
        List<Property__c> properties = Database.query(new al.SOQLBuilder()
                                                      .selectx(fieldToAttr.keySet())
                                                      .fromx('Property__c').toSOQL() 
                                                      + (PropertyLimit != null ? ' LIMIT ' + PropertyLimit : ''));
        return getPropertiesXml(properties);
    }
    
    @RemoteAction
    global static String getProperty(Id propertyId) {
        List<Property__c> properties = Database.query(new al.SOQLBuilder()
                                                      .selectx(fieldToAttr.keySet())
                                                      .fromx('Property__c')
                                                      .wherex(new al.FieldCondition('Id').equals(propertyId))
                                                      .toSOQL());
        return getPropertiesXml(properties);
    }
    
    @isTest(SeeAllData=true)
    static void testMapController() {
        Property__c p = new Property__c(Name='test',
                                        Property_ID__c='12345',
                                        Address_Line1__c='30 S Park Sq',
                                        City__c='Marietta', State__c='GA');
        insert p;

        ApexPages.StandardController sc = new ApexPages.StandardController(p);
        MapController mc = new MapController(sc);
        
        MapController.PropertyLimit = 20;
        String properties = getProperties(false);
        System.Debug('Properties:' + properties);

        String property = getProperty(p.Id);
        System.Debug('Property:' + property);
        String myId = mc.getPropertyId();
        System.Assert(myId != null);
    }
}