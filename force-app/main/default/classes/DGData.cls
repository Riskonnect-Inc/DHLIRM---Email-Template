/*===========================================================================
     Added to RK base RMIS product as 05/29/2013
    ===========================================================================*/
    
global class DGData {
    
    // MU - 3/6/2013 - Initial code
    // AD - 3/6/2013 - Additional changes
    // This class performs a web service call out to the Reed webservice to return disability guidelines
    // data based on ICD9 Code parameters.
     
    public rkme.JSON2.Variant rootDuration;
    public rkme.JSON2.Variant rootPredictive;  
    public rkme.JSON2.Variant rootMonographDetails;      
    public String licenseKey = '070f527a-fb0d-4517-9ae9-467f7474c51a'; //'070f527a-fb0d-4517-9ae9-467f7474c51a'; 
   
    public DGData(String monographName) { 
       //Using stage key our key still does not work for this service
       //String licenseKey = '377713f0-af6b-4495-a650-24f68f870086'; 
        
       String reqBody = new rkme.HtmlBuilder()
            .addChildNode('MonographRequest')
                .attr('xmlns', 'http://MDGuidelines.WebService')
                .addChildNode('SessionId')
                    .text(licenseKey)
                    .parent(2)
                .addChildNode('MonographName')
                    .text(monographName)
                    .parent(2)
                .addChildNode('SectionName')
                    .attr('nil', 'true')
                    .parent()                    
                .rootDoc(); 
         
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        
        //Using stage endpoint for now during testing
        req.setEndpoint('http://www.mdguidelines.com/WebService_JSON/MonographRequest');
        req.setBody(reqBody);
        //System.debug('Request Body: ' + reqBody);
        Http http = new Http();   
        if(Test.isRunningTest()) {
        
        } else {
            HTTPResponse res = http.send(req);   
            rootMonographDetails = rkme.JSON2.parse(res.getBody());
            System.debug('Monogragh Data: ' + res.getBody());
        }
    } 
  
    public DGData(String icd9Code, String icdType, String jobClass) {
       String[] j = jobClass.split(' ');
       if (j.size() >=2) jobClass = j[0] + j[1];     
            
       String reqBody = new rkme.HtmlBuilder()
            .addChildNode('DisabilityDurationRequest')
                .attr('xmlns', 'http://MDGuidelines.WebService')
                .addChildNode('LicenseKey')
                    .text(licenseKey)
                    .parent(2)
                .addChildNode('ICD9Code')
                    .text(icd9Code)
                    .parent(2)
                .addChildNode('Factor')
                    .attr('nil', 'true')
                    .parent()
                .addChildNode('JobClass')
                    .text(jobClass.toUpperCase())
                    .parent(2)
                .rootDoc();
        
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        req.setEndpoint('http://www.mdguidelines.com/WebService_JSON/PhysiologicalDurationRequest');
        req.setBody(reqBody);
        System.debug(reqBody);
         
        Http http = new Http();   
        String response;
        if(Test.isRunningTest()) {
            response='{"DisabilityDurationResponse":{"DurationsRecordCount":0,"RelatedMonographsRecordCount":0,"DurationTables":null,"RelatedMonographUrlElements":[],"TransactionMessage":{"TransactionId":null,"Message":"Successful Transaction","Expired":false,"LicenseExpirationDate":"04/30/2014","Transactions":{"TransactionsInLicense":100000,"TransactionsUsed":2,"TransactionsLeft":99998},"ErrorCode":-1,"ErrorCodeDescription":null,"ErrorCodeCustomDescription":null}}}';
        } else {
            HTTPResponse res = http.send(req);   
            System.debug(res.getBody());
            response = res.getBody();
        }
        rootDuration = rkme.JSON2.parse(response);  
    }
    
    public DGData(String icd9Code, String icdType, String jobClass, String co1, String co2, String co3, 
                  String co4, String co5, String age, String gender, String postal, String wc, String domestic, String yearIncurred) {  
       
       String[] j = jobClass.split(' ');
       if (j.size() >=2) jobClass = j[0] + j[1];
       
       String reqBody = new rkme.HtmlBuilder()
            .addChildNode('PredictiveModelRequest')
                .attr('xmlns', 'http://MDGuidelines.WebService')
                .addChildNode('LicenseKey')
                    .text(licenseKey)
                    .parent(2)
                .addChildNode('ICD9Code')
                    .text(icd9Code)
                    .parent(2)
                .addChildNode('Comorbid1Code')
                    .text(co1)
                    .parent(2)   
                .addChildNode('Comorbid2Code')
                    .text(co2)
                    .parent(2) 
                .addChildNode('Comorbid3Code')
                    .text(co3)
                    .parent(2)   
                .addChildNode('Comorbid4Code')
                    .text(co4)
                    .parent(2) 
                .addChildNode('Comorbid5Code')
                    .text(co5)
                    .parent(2)    
                .addChildNode('Age')
                    .text(age)
                    .parent(2) 
                .addChildNode('JobClass')
                    .text(jobClass.toUpperCase())
                    .parent(2)                    
                .addChildNode('Gender')
                    .text(gender.toUpperCase())
                    .parent(2) 
                .addChildNode('PostalCodeFirstDigit')
                    .text(postal)
                    .parent(2)                    
                .addChildNode('YearIncurred')
                    .text(yearIncurred)
                    .parent(2)                    
                .addChildNode('WorkersComp')
                    .text(wc.toUpperCase())
                    .parent(2)
                .addChildNode('Domestic')
                    .text(domestic.toUpperCase())
                    .parent(2)                                                                                                                                                                             
                .rootDoc();
        System.debug('Req Body: ' + reqBody);
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('content-type', 'application/x-www-form-urlencoded');
        req.setEndpoint('http://www.mdguidelines.com/WebService_JSON/NormativeDurationForWebSiteRequest');
        req.setBody(reqBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);   
        rootPredictive = rkme.JSON2.parse(res.getBody());             
    }
    
    public MonographDetails loadMonographDetails() {
        rkme.JSON2.JObject root = rootMonographDetails.objProp('MonographResponse');
            MonographDetails monograpgDetailsModel = new MonographDetails(root.stringProp('MonographName'));
            
        for (rkme.JSON2.Variant section: root.arrayProp('SectionElements').vals) {
            rkme.JSON2.JObject sectionObj = ((rkme.JSON2.JObject) section);
            monograpgDetailsModel.sectionElements.add(new SectionElement(
                sectionObj.stringProp('SectionId'),
                sectionObj.stringProp('SectionName'),
                sectionObj.stringProp('SectionContent')));
        }

        rkme.JSON2.Variant ill = root.prop('Illustrations');
        if (ill.isNull || ill.isUndefined) {
            // You must handle this case….
        } else {
            //rkme.JSON2.JArray illArray = (rkme.JSON2.JArray) ill;
            //for (rkme.JSON2.Variant i: illArray.vals) {
                rkme.JSON2.JObject iObj = (rkme.JSON2.JObject) ill;
                monograpgDetailsModel.illustrations.add(new Illustration(iObj.stringProp('IllustrationId'), iObj.stringProp('IllustrationUrl')));
            //}
        }
        
        return monograpgDetailsModel;
    }        
    
    public PredictiveModel loadPredictiveModel() {
        rkme.JSON2.JObject root = rootPredictive.objProp('PredictiveModelResponse');
        PredictiveModel preModel = new PredictiveModel(
            root.stringProp('TrendGraphsElement.TrendGraphDensityElement.GraphUrl'),
            root.stringProp('TrendGraphsElement.TrendGraphCumulativeElement.GraphUrl'),
            root.decimalProp('ICD9Value'),
            root.decimalProp('Comorbid1Value'),
            root.decimalProp('Comorbid2Value'),
            root.decimalProp('Comorbid3Value'),
            root.decimalProp('AgeValue'),
            root.decimalProp('GenderValue'),
            root.decimalProp('JobClassValue'),
            root.decimalProp('PredictiveValue'),
            root.decimalProp('GeographicValue'),
            root.decimalProp('WorkersCompValue'),
            root.decimalProp('YearIncurredValue'),
            root.decimalProp('ForeignIndicatorValue'));
            
        for (rkme.JSON2.Variant phy: root.arrayProp('PhysiologicalFactorsElement').vals) {
            rkme.JSON2.JObject phyObj = ((rkme.JSON2.JObject) phy);
            preModel.phyFactors.add(new PhyFactor(
                phyObj.stringProp('FactorDetail'),
                phyObj.decimalProp('Minimum'),
                phyObj.decimalProp('Maximum'),
                phyObj.decimalProp('Optimum')));
        }
        
        for (rkme.JSON2.Variant top: root.arrayProp('TopicsElement').vals) {
            rkme.JSON2.JObject topObj = ((rkme.JSON2.JObject) top);
            preModel.topics.add(new Topic(
                topObj.stringProp('TopicName'),
                topObj.stringProp('TopicUrl')));
        }
    
        return preModel;
    }    
    
    public DurationTable[] loadDurationTables() {
        DurationTable[] durTables = new DurationTable[]{};
        
        for (rkme.JSON2.Variant dur: rootDuration.arrayProp('DisabilityDurationResponse.DurationTables').vals) {
            String factor = dur.stringProp('Factor');
            DurationTable durTable = new DurationTable(factor, dur.stringProp('MedicalCode'), dur.stringProp('MedicalCodeDescription'));
            durTables.add(durTable);
            for (rkme.JSON2.Variant j: dur.arrayProp('JobClassDurationLevelTables').vals) {
                JobClass job = new JobClass(j.decimalProp('MinimumDuration'), j.decimalProp('MaximumDuration'), j.decimalProp('OptimumDuration'));
                durTable.jobs.add(job);
            }          
        }
        
        return durTables;
    }
    
    public Monograph[] loadMonograph() {
        Monograph[] monographInfo = new Monograph[]{};
        
        for (rkme.JSON2.Variant m: rootDuration.arrayProp('DisabilityDurationResponse.RelatedMonographUrlElements').vals) {
            Monograph mon = new Monograph(m.stringProp('MonographId'), m.stringProp('Monograph'), m.stringProp('MedicalCode'), m.stringProp('MonographUrl'));
            monographInfo.add(mon);         
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
        public Decimal icd9Value {get;set;}
        public Decimal comorbid1Value {get;set;}
        public Decimal comorbid2Value {get;set;}
        public Decimal comorbid3Value {get;set;}
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
        
        public PredictiveModel(String trendGraphDensityUrl, String trendGraphCumulativeUrl, Decimal icd9Value, Decimal comorbid1Value,
                               Decimal comorbid2Value, Decimal comorbid3Value, Decimal ageValue, Decimal genderValue,
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
        public Illustration[] illustrations {get;set;}
        
        public MonographDetails(String monographName) {
            this.monographName = monographName;
            this.sectionElements = new SectionElement[]{};
            this.illustrations = new Illustration[]{};              
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

   public class Illustration {
        public String illustrationId {get;set;}
        public String illustrationUrl {get;set;}  
        
        public Illustration (String illustrationId, String illustrationUrl) {
            this.illustrationId = illustrationId;
            this.illustrationUrl = illustrationUrl;
        }               
   }

}