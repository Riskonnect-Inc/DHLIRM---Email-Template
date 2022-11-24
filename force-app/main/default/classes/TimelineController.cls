/*===========================================================================
     Added to RK base RMIS product as  05/26/2015
   ===========================================================================*/
    
public class TimelineController {

    public String jsonTLW {get; private set;}
    public String header1 {get; private set;}
    public String header2 {get; private set;}
    
    public TimelineController(){
        
        String objectId = System.currentPageReference().getParameters().get('Id');
        String fieldAPI = System.currentPageReference().getParameters().get('field');
        

        if((fieldAPI==null && fieldAPI=='') || (objectId==null && objectId=='')){
            System.debug('Needs to throw exception');
        }
        
        List<String> objectInfo = GetSchemaInfoFromRecordId(objectId).split('!~!');
        system.debug(objectInfo);
        header1 = '';
        header2 = '';
        if(objectInfo.size()==2){
            header1 = objectInfo[1]+':';

            al.SOQLBuilder soql = new al.SOQLBuilder()
                .selectx(new List<String>{'Name'})
                .fromx(objectInfo[0])
                .wherex((new al.FieldCondition('Id').equals(objectId)));
    
            List<SObject> results = Database.query(soql.toSOQL());
            if(results.size()==1){
                header2 = (results[0].get('Name')+ '');
            }
        }
        
        al.SOQLBuilder soql = new al.SOQLBuilder()
            .selectx(new List<String>{'Timeline_Event_date_time__c','Timeline_Event_Date__c','Color_Code__c','Label__c','Description__c','Photo__c'})
            .fromx('Timeline__c')
            .wherex((new al.FieldCondition(fieldAPI).equals(objectId)));

        List<SObject> results = Database.query(soql.toSOQL());
        
        
        if(results.size()==0){
            System.debug('Needs to throw exception');
        }
        
        Map<Datetime,List<dataWrapper>> sortingMap = new Map<Datetime,List<dataWrapper>>();
        for(SObject event : results){
            Datetime eventDate;
            Boolean dtType;
            if(event.get('Timeline_Event_date_time__c')!=null){
                eventDate = (Datetime)event.get('Timeline_Event_date_time__c');
                dtType = true;
            } else{
                eventDate = Datetime.newInstance((Date)event.get('Timeline_Event_Date__c'), Time.newInstance(0,0,0,0));
                dtType = false;
            }
            if(sortingMap.containsKey(eventDate)){
                sortingMap.get(eventDate).add(new dataWrapper(event, dtType));
            } else{
                sortingMap.put(eventDate,new List<dataWrapper>{new dataWrapper(event, dtType)});
            }
        }
        
        List<Datetime> sortedVals = new List<Datetime>(sortingMap.keySet());
        sortedVals.sort();
        
        List<List<timeLineWrapper>> tLW = new List<List<timeLineWrapper>>();
        for(Datetime dt : sortedVals){
            List<timeLineWrapper> innerListDT = new List<timeLineWrapper>();
            List<timeLineWrapper> innerListD = new List<timeLineWrapper>();
            for(dataWrapper dw : sortingMap.get(dt)){
                SObject so = dw.dataVal;
                if(dw.dtType){
                    innerListDT.add(new timeLineWrapper(dt.format(),(String)so.get('Label__c'),(String)so.get('Description__c'),(String)so.get('Photo__c'),(String)so.get('Color_Code__c')));
                } else{
                    innerListD.add(new timeLineWrapper(dt.date().format(),(String)so.get('Label__c'),(String)so.get('Description__c'),(String)so.get('Photo__c'),(String)so.get('Color_Code__c')));
                }
                
            }
            if(innerListD.size()>0){
                tLW.add(innerListD);
            }
            if(innerListDT.size()>0){
                tLW.add(innerListDT);
            }
            
        }

        jsonTLW = JSON.serialize(tLW);
    }
    
    private class dataWrapper{
        SObject dataVal;
        Boolean dtType;
        private dataWrapper(SObject so, Boolean b){
            dataVal = so;
            dtType = b;
        }
    }
    
    public class timeLineWrapper{
        public String eventDateTime{get; set;}
        public String label{get; set;}
        public String color{get; set;}
        public String description{get; set;}
        public String pic{get; set;}
        
        public timeLineWrapper(String e, String l, String d, String p, String c){
            eventDateTime = e;
            label = l;
            description = d;
            color = c==null?'#555':c;
            pic = p==null?'':p.escapeJava();
        }
    }
    
    private static String GetSchemaInfoFromRecordId(String recordId){
        if(recordId == null){
            return '';
        }
        
        String prefix = recordId.substring(0,3);
        
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe(); 
        for(Schema.SObjectType sObjType : globalDescribe.Values())
        {
            Schema.DescribeSObjectResult objectDescribe = sObjType.getDescribe();
            if(objectDescribe.getKeyPrefix()!=null && objectDescribe.getKeyPrefix().equals(prefix)){
                return objectDescribe.getName()+'!~!'+objectDescribe.getLabel();
            }
        }
        return '';
    }
}