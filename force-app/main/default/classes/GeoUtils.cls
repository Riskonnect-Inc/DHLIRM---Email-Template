/*===========================================================================
     Added to RK base RMIS product as 03/25/2013
    ===========================================================================*/
    
global with sharing class GeoUtils implements Database.Batchable<sObject>, Database.AllowsCallouts {
    String query;
    //These maps need to be changed into custom settings
    global static Map<String,List<String>> addressFields = new Map<String,List<String>> {
        'Property__c' => new List<String> {'Address_Line1__c', 'Address_Line2__c', 'City__c', 'State__c', 'Zip_Code__c', 'Country__c'}
    };
    global static Map<String,List<String>> coordFields = new Map<String,List<String>> {
        'Property__c' => new List<String> {'Latitude__c', 'Longitude__c'}
    };
    
    global GeoUtils(String query) {
        if (Test.isRunningTest()){
            query+= ' LIMIT 1';
        } 
        this.query=query;
    }
    
    global static List<String> fieldsToQuery(String objectName) {
        List<String> fields = new List<String>();
        fields.addAll(addressFields.get(objectName));
        fields.addAll(coordFields.get(objectName));
        return fields;
    }
    
    global static void populateMissingCoords(String objectName) {
        al.OrCondition orCond = new al.OrCondition();
        for(String field : coordFields.get(objectName)) {
            orCond.add(new al.FieldCondition(field).notEquals('null'));
        }
        String query = 'SELECT '+al.StringUtils.joinArray(fieldsToQuery(objectName),',')+
               ' FROM '+objectName+
               ' WHERE '+coordFields.get(objectName)[0]+'!=null OR '+coordFields.get(objectName)[1]+'!=null';
        //String query = new al.SOQLBuilder().selectx(fieldsToQuery(objectName)).
        //       fromx(objectName).
        //       wherex(orCond).toSOQL();
        System.debug('missing coords query: '+query);
        Id batchId = Database.executeBatch(new GeoUtils(query),1);
    }
    
    global static void updateCoords(String objectName, List<Id> idsToUpdate) {
        String query = 'SELECT '+al.StringUtils.joinArray(fieldsToQuery(objectName),',')+
               ' FROM '+objectName+
               ' WHERE Id IN (\''+al.StringUtils.joinArray(idsToUpdate, '\',\'')+'\')';
        //SOQLBuilder causes an internal salesforce error for some reason.
        //String query = new al.SOQLBuilder().selectx(fieldsToQuery(objectName)).
        //       fromx(objectName).
        //       wherex(new al.SetCondition('Id').inx(idsToUpdate)).toSOQL();
        System.debug('update Coords query: '+query);
        Id batchId = Database.executeBatch(new GeoUtils(query),1);
    }
    

    /*
     * These classes are used to deserialize the result of the JSON query to the
     * Google Geocoding API
     */
    global class GeocodeResult {
        public Result[] results;
        public String status;
        
        public GeocodeResult(String status) {
            this.results = new List<Result>();
        }
    }
    
    global class Result {
        public AddressComponent[] address_components;
        public String formatted_address;
        public Geom geometry;
        public String[] types;
        public String partial_match;
        
        public Result(String formatted_address, Geom geometry, String partial_match) {
            this.address_components = new List<AddressComponent>();
            this.formatted_address = formatted_address;
            this.geometry = geometry;
            this.types = new List<String>();
            this.partial_match = partial_match;
        }
    }
    
    global class AddressComponent {
        public String long_name;
        public String short_name;
        public String[] types;
        
        public AddressComponent(String long_name, String short_name) {
            this.long_name=long_name;
            this.short_name=short_name;
            this.types = new List<String>();
        }
    }
    
    global class Geom {
        public Coord location;
        public String location_type;
        public View viewport;
        public View bounds;
        
        public Geom(Coord location, String location_type, View viewport, View bounds) {
            this.location=location;
            this.location_type = location_type;
            this.viewport = viewport;
            this.bounds = bounds;
        }
    }
    
    global class Coord {
        global String lat;
        global String lng;
        
        global Coord(String lat, String lng) {
           this.lat = lat;
           this.lng = lng;
        }
    }
    
    global class View {
        public Coord northeast;
        public Coord southwest;
        
        public View(Coord northeast, Coord southwest) {
            this.northeast = northeast;
            this.southwest = southwest;
        }
    }
    
    // End Geocoding JSON classes

    global Database.QueryLocator start(Database.BatchableContext info){ 
        return Database.getQueryLocator(query); 
    }     
    
    global void execute(Database.BatchableContext info, List<sObject> scope){
        for(sObject obj : scope) {
            List<String> addressParts = new List<String>();
            for(String field : addressFields.get(obj.getSObjectType().getDescribe().getName())) {
                if(al.StringUtils.isNotBlank((String)obj.get(field))) {
                   addressParts.add((String)obj.get(field));
                }
            }
            Coord c = getCoordinates(addressParts);
            obj.put('Latitude__c', al.StringUtils.left(c.lat,12));
            obj.put('Longitude__c', al.StringUtils.left(c.lng,12));
        }
        update scope;
    }     

    global void finish(Database.BatchableContext info){     
    } 

    /* 
    Input list of address parts: street,  city,  state,  country. 
    Output: list of coordinates: latitude, longitude
    */ 
    global static Coord getCoordinates(String[] addressParts)
    { 
        String address = al.StringUtils.joinArray(addressParts, '+');
        address.replace(' ','+');
        if(address.length() == 0)
        {
            system.debug(Logginglevel.ERROR,
                'GeoUtilities getCoordinates no address provided. Return null');
            return null; 
        }
         
        String url = 'https://maps.googleapis.com/maps/api/geocode/json?sensor=false&address='+EncodingUtil.urlEncode(address,'UTF-8');
        Http h = new Http(); 
        HttpRequest req = new HttpRequest();
        
        req.setHeader('Content-type', 'application/x-www-form-urlencoded'); 
        req.setHeader('Content-length', '0'); 
        req.setEndpoint(url); 
        req.setMethod('GET');
        GeocodeResult geoRes;
        if (!Test.isRunningTest()){ 
            // Methods defined as TestMethod do not support Web service callouts
            HttpResponse res = h.send(req); 
            System.debug('GoogleHttpResponse '+res);
            geoRes = (GeocodeResult)JSON.deserialize(res.getBody(), GeocodeResult.class);
        }
        else {
            // dummy data
            geoRes = new GeocodeResult('OK');
            Result res = new Result('123 Main', new Geom(new Coord('-97','43'), 'ROOFTOP', new View(new Coord('-97','43'),new Coord('-97','43')), null), 'false');
            res.address_components.add(new AddressComponent('123 Main St', '123 Main'));
            geoRes.results.add(res);
        } 
        System.debug('GEORES '+geoRes);
        if(geoRes.results.size()>0) {
            return geoRes.results[0].geometry.location;
        } else {
            system.debug(Logginglevel.ERROR,
                'GeoUtilities getCoordinates no results. Return null');
            return null;
        }
    }  
    
    @isTest
    static void testGeoUtils() {
        Property__c p = new Property__c(Name='test', Property_ID__c='12345', Address_Line1__c='30 S Park Sq', City__c='Marietta', State__c='GA');
        insert p;
        Test.StartTest();
        populateMissingCoords('Property__c');
        Test.StopTest();
    }
}