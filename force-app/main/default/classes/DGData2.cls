/*===========================================================================
     Added to RK base RMIS product as 04/262016
    ===========================================================================*/
    
global class DGData2 {
    
    // MU - 3/6/2013 - Initial code
    // AD - 3/6/2013 - Additional changes
    // This class performs a web service call out to the Reed webservice to return disability guidelines
    // data based on ICD9 Code parameters.
    
    public static final String SERVICE_ROOT = 'https://api.mdguidelines.com/api/';
    public static final String DURATION_SERVICE = SERVICE_ROOT + 'v2/durations';
    public static final String PREDICTIVE_SERVICE = SERVICE_ROOT + 'v2/predictivemodel';
    public static final String DOCUMENT_SERVICE = SERVICE_ROOT + 'v1/documents';
     
    public JsonMap[] rootDuration;
    public JsonMap rootPredictive;  
    public JsonMap rootMonographDetails;      
    public String licenseKey = '070f527a-fb0d-4517-9ae9-467f7474c51a'; //'070f527a-fb0d-4517-9ae9-467f7474c51a';
    
    public String jobClass;
    public String icdCode;
    public String icdCodeType;
    public String comorbid1;
    public String comorbid2;
    public String comorbid3;
    public String comorbid4;
    public String comorbid5;
    
    public static UrlBuilder UrlBldr(String service) {
        return new UrlBuilder(service);
    }
    
    public static JsonMap JMap(Object o) {
        return new JsonMap(o);
    }
    
    public static JsonMap[] JMapList(Object arr) {
        if(arr == null) {
            return new JsonMap[]{};
        }
        Object[] l = (Object[])arr;
        JsonMap[] amap = new JsonMap[]{};
        for(Object o : l) {
            amap.add(new JsonMap(o));
        }
        return amap;
    }
    
    public class JsonMap {
        private Map<String, Object> m;
        
        private JsonMap(Object amap) {
            m = (Map<String, Object>)amap;
        }
        
        public String[] slist(String k) {
            return (String[])m.get(k);
        }
        
        public JsonMap[] olist(String k) {
            return JMapList(m.get(k));
        }
        
        public JsonMap obj(String k) {
            return new JsonMap(m.get(k));
        }
        
        public String string(String k) {
            return String.valueOf(m.get(k));
        }
        
        public Decimal decimal(String k) {
            return (Decimal)m.get(k);
        }
    } 
        
    public class UrlBuilder {
        private String[] url;
        
        private UrlBuilder(String service) {
            url = new String[]{service};
        }
        
        public UrlBuilder param(String key, String value) {
            String concat = url.size() == 1 ? '?' : '&';
            url.add(concat);
            url.add(key);
            url.add('=');
            url.add(value);
            return this;
        }
        
        public String dun() {
            return String.join(url, '');
        }
    }
   
    public DGData2(String monographName) { 
       String reqUrl = UrlBldr(DOCUMENT_SERVICE)
           .param('documentUrl', monographName)
           .param('sections', '')
           .dun();
        
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('RG-LICENSE-KEY', licenseKey);
        req.setEndpoint(reqUrl);
        Http http = new Http();   

        if(Test.isRunningTest()) {
        
        } else {
            HTTPResponse res = http.send(req);
            System.debug(reqUrl);
            System.debug('Monogragh Data: ' + res.getBody());
            rootMonographDetails = JMap(JSON.deserializeUntyped(res.getBody()));
        }
    } 
  
    public DGData2(String icdCode, String icdCodeType, String jobClass) {
        this.jobClass = jobClass;
            
        String reqUrl = UrlBldr(DURATION_SERVICE)
           .param('medicalCodes', icdCode)
           .param('medicalCodeType', (icdCodeType == 'ICD-9') ? 'icd9cm' : 'icd10cm')
           .param('showTopics', 'true')
           .dun();
        
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('RG-LICENSE-KEY', licenseKey);
        req.setEndpoint(reqUrl);
        Http http = new Http();   

        String response;
        if(Test.isRunningTest()) {
            response='{"DisabilityDurationResponse":{"DurationsRecordCount":0,"RelatedMonographsRecordCount":0,"DurationTables":null,"RelatedMonographUrlElements":[],"TransactionMessage":{"TransactionId":null,"Message":"Successful Transaction","Expired":false,"LicenseExpirationDate":"04/30/2014","Transactions":{"TransactionsInLicense":100000,"TransactionsUsed":2,"TransactionsLeft":99998},"ErrorCode":-1,"ErrorCodeDescription":null,"ErrorCodeCustomDescription":null}}}';
        } else {
            HTTPResponse res = http.send(req);   
            System.debug(res.getBody());
            response = res.getBody();
        }
        rootDuration = JMapList(JSON.deserializeUntyped(response));
    }
    
    private static UrlBuilder addComorbid(UrlBuilder url, String comorbidParam, String comorbidValue) {
        if(String.isNotBlank(comorbidValue)) {
            url = url.param(comorbidParam, comorbidValue);
        }
        return url;
    }
    
    public DGData2(String icdCode, String icdCodeType, String jobClass, String co1, String co2, String co3, 
                  String co4, String co5, String age, String gender, String postal, String wc, String domestic, String yearIncurred) {  
       
        this.icdCode = icdCode;
        this.icdCodeType = this.icdCodeType;
        this.comorbid1 = co1;
        this.comorbid2 = co2;
        this.comorbid3 = co3;
                      
      UrlBuilder url = UrlBldr(PREDICTIVE_SERVICE)
            .param('primaryMedicalCode', icdCode)
            .param('medicalCodeType', (icdCodeType == 'ICD-9') ? 'icd9cm' : 'icd10cm')
            .param('gender', gender)
            .param('age', age)
            .param('jobClass', jobClass)
            .param('region', postal)
            .param('isWorkersComp', 'true')
            .param('matchWebsite', 'true')
            .param('includeDurations', 'true');
        
        url = addComorbid(url, 'comorbidCode1', co1);
        url = addComorbid(url, 'comorbidCode2', co2);
        url = addComorbid(url, 'comorbidCode3', co3);
        url = addComorbid(url, 'comorbidCode4', co4);
        url = addComorbid(url, 'comorbidCode5', co5);

        String reqUrl = url.dun();
                      
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('RG-LICENSE-KEY', licenseKey);
        req.setEndpoint(reqUrl);
        Http http = new Http();   

        HTTPResponse res = http.send(req);
    System.debug(res.getBody());
        rootPredictive = JMap(JSON.deserializeUntyped(res.getBody()));
    }
    
    public MonographDetails loadMonographDetails() {
        MonographDetails monograpgDetailsModel = new MonographDetails((String)rootMonographDetails.string('documentName'));
        
        JsonMap[] sections = rootMonographDetails.olist('sections');
        for (JsonMap section: sections) {
            monograpgDetailsModel.sectionElements.add(new SectionElement(
                section.string('section'),
                section.string('sectionUrl'),
                section.string('sectionText')));
        }

        return monograpgDetailsModel;
    }        
    
    public PredictiveModel loadPredictiveModel() {
        System.debug('Pred 1');
        PredictiveModel preModel = new PredictiveModel(
            '',
            '',
            icdCode,
            comorbid1,
            comorbid2,
            comorbid3,
            rootPredictive.decimal('ageModifier'),
            rootPredictive.decimal('genderModifier'),
            rootPredictive.decimal('jobClassModifier'),
            rootPredictive.decimal('totalPredictedDuration'),
            rootPredictive.decimal('regionModifier'),
            rootPredictive.decimal('workersCompModifier'),
            Date.today().year(),
            0);
            
        System.debug('Pred 2');
        JsonMap[] phyFactors = rootPredictive.obj('primaryDiagnosis').olist('durations');
        for (JsonMap phy: phyFactors) {
          System.debug('Pred 3');
            for(JsonMap jc : phy.olist('jobClasses')) {
            System.debug('Pred 4');
                if(jc.string('jobClass') == this.jobClass) {
              System.debug('Pred 5');
                preModel.phyFactors.add(new PhyFactor(
                    phy.string('factor'),
                    jc.decimal('minimum'),
                    jc.decimal('maximum'),
                    jc.decimal('optimum')));
                }
            System.debug('/Pred 4');
            }
          System.debug('/Pred 3');
        }
        
        return preModel;
    }    
    
    public DurationTable[] loadDurationTables() {
        DurationTable[] durTables = new DurationTable[]{};
        
        for (JsonMap pdur: rootDuration) {
            for(JsonMap dur : pdur.olist('durations')) {
              String factor = dur.string('factor');
              DurationTable durTable = new DurationTable(factor, pdur.string('code'), pdur.string('description '));
              durTables.add(durTable);
              for (JsonMap j: dur.olist('jobClasses')) {
                  JobClass job = new JobClass(j.decimal('minimum'), j.decimal('maximum'), j.decimal('optimum'));
                  durTable.jobs.add(job);
              }
            }
        }
        
        return durTables;
    }
    
    public Monograph[] loadMonograph() {
        Monograph[] monographInfo = new Monograph[]{};
        
        for (JsonMap dur : rootDuration) {
            for(JsonMap m : dur.olist('topics')) {
              Monograph mon = new Monograph(null, m.string('documentName'), icdCode, m.string('documentUrl'));
              monographInfo.add(mon);         
            }
        }       
            
        return monographInfo;
    }
    
    public class DurationTable {
        public String factor {get;set;}
        public String medCode {get;set;}
        public String medCodeDesc {get;set;}
        public JobClass[] jobs {get;set;}
                
        DurationTable (String factor, String medCode, String medCodeDesc) {
            this.factor = factor;
            this.medCode = medCode;
            this.medCodeDesc = medCodeDesc;
            this.jobs = new JobClass[]{};
        }
    }
    
    public class JobClass {
        public Decimal minVal {get;set;}
        public Decimal maxVal {get;set;}
        public Decimal optimum {get;set;}
        
        public JobClass (Decimal minVal, Decimal maxVal, Decimal optimum) {
            this.minVal = minVal;
            this.maxVal = maxVal;
            this.optimum = optimum;
        }
    }
    
    public class Monograph {
        public String monographId {get;set;}
        public String monograph {get;set;}
        public String medicalCode {get;set;}
        public String monographUrl {get;set;}
        
        public Monograph(String monographId, String monograph, String medicalCode, String monographUrl) {
            this.monographId = monographId;  
            this.monograph = monograph;
            this.medicalCode = medicalCode;
            this.monographUrl = monographUrl;       
        }
   }

   public class PredictiveModel {
        public String  icd9Value {get;set;}
        public String comorbid1Value {get;set;}
        public String comorbid2Value {get;set;}
        public String comorbid3Value {get;set;}
        public Decimal ageValue {get;set;}
        public Decimal genderValue {get;set;}
        public Decimal jobClassValue {get;set;}
        public Decimal predictiveValue {get;set;}
        public Decimal geographicValue {get;set;}
        public Decimal workersCompValue {get;set;}
        public Decimal yearIncurredValue {get;set;}
        public Decimal foreignIndicatorValue {get;set;}
        public Topic[] topics {get;set;}
        public PhyFactor[] phyFactors {get;set;}        
        public String trendGraphDensityUrl {get;set;}
        public String trendGraphCumulativeUrl {get;set;}        
        
        public PredictiveModel(String trendGraphDensityUrl, String trendGraphCumulativeUrl, String icd9Value, String comorbid1Value,
                               String comorbid2Value, String comorbid3Value, Decimal ageValue, Decimal genderValue,
                               Decimal jobClassValue, Decimal predictiveValue, Decimal geographicValue, Decimal workersCompValue,
                               Decimal  yearIncurredValue, Decimal  foreignIndicatorValue) {
            this.trendGraphDensityUrl = trendGraphDensityUrl;
            this.trendGraphCumulativeUrl = trendGraphCumulativeUrl;     
            this.topics = new Topic[]{};
            this.phyFactors = new PhyFactor[]{};   
            this.icd9Value = icd9Value;
            this.comorbid1Value = comorbid1Value; 
            this.comorbid2Value = comorbid2Value; 
            this.comorbid3Value = comorbid3Value;
            this.ageValue = ageValue; 
            this.genderValue = genderValue; 
            this.jobClassValue = jobClassValue;
            this.predictiveValue = predictiveValue;
            this.geographicValue = geographicValue;
            this.workersCompValue = workersCompValue;
            this.yearIncurredValue = yearIncurredValue;
            this.foreignIndicatorValue = foreignIndicatorValue;                 
        }   
   }
   
   public class PhyFactor {
        public String factorDetails {get;set;}
        public Decimal minVal {get;set;}
        public Decimal maxVal {get;set;}
        public Decimal optimum {get;set;}
        
        public PhyFactor (String factorDetails, Decimal minVal, Decimal maxVal, Decimal optimum) {
            this.factorDetails = factorDetails;
            this.minVal = minVal;
            this.maxVal = maxVal;
            this.optimum = optimum;
        }
   }
   
   public class Topic {
        public String name {get;set;}
        public String url {get;set;}    
        
        public Topic(String name, String url) {
            this.name = name;
            this.url = url;
        }
   }
   
   public class MonographDetails {
        public String monographName {get;set;}
        public SectionElement[] sectionElements {get;set;}
        
        public MonographDetails(String monographName) {
            this.monographName = monographName;
            this.sectionElements = new SectionElement[]{};
        }
   }
   
   public class SectionElement {
        public String sectionId {get;set;}
        public String sectionName {get;set;}
        public String sectionContent {get;set;}   
        
        public SectionElement (String sectionId, String sectionName, String SectionContent) {
            this.sectionId = sectionId;
            this.sectionName = sectionName;
            this.sectionContent = sectionContent;
        }               
   }
}