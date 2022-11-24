/*===========================================================================
     Added to RK base RMIS product as 07/31/2015
 ===========================================================================*/
global class CheckPrinting2 {

    webservice static String runBatch(String ppID) {
        Database.executeBatch(new CheckPrintingBatch(ppID), 1);
        return 'good';
    }
    
    global class CheckBuildException extends Exception{}

    global virtual class baseClass{
        global Boolean isBlankStr(String i){if(i==null || i==''){return true;}else{return false;}}
        global Boolean isBlank(Object i){if(i==null){return true;}else{return false;}}
        global Boolean isTruthy(Boolean i){if(i==null || i==false){return false;}else{return true;}}
    }
    global class CheckOrder extends baseClass{
        global List<Check> checks {get;private set;}
        global Boolean pdfBackground {get;private set;}
        global Boolean returnPDF {get;private set;}
        global Boolean testing {get;private set;}
        global String token {get;private set;}
        global String signature {get;private set;}
        global String firstCkNum {get;set;}
        global String lastCkNum {get;set;}
        global CheckOrder(String t, List<Check> cks){
            if(!isBlankStr(t)){
                token = t;
            } else{
                throw new CheckBuildException('Token can\'t be empty');
            }
            if(cks!=null && cks.size()>0){
                checks = cks;
            } else{
                checks = new List<Check>();
            }
        }
        global CheckOrder(String t,Boolean rPDF,Boolean pdfB,Boolean test,List<Check> cks){
            this(t,cks);
            setReturnPDF(rPDF);
            setPDFbackground(pdfB);
            setTesting(test);
        }
        global CheckOrder setReturnPDF(Boolean rPDF){
            if(!isBlank(rPDF)){
                returnPDF = rPDF;
            } else{
                throw new CheckBuildException('Return PDF can\'t be null');
            }
            return this;
        }
        global CheckOrder setPDFbackground(Boolean pdfB){
            if(!isBlank(pdfB)){
                pdfBackground = pdfB;
            } else{
                throw new CheckBuildException('PDF Background can\'t be null');
            }
            return this;
        }
        global CheckOrder setTesting(Boolean test){
            if(!isBlank(test)){
                testing = test;
            } else{
                throw new CheckBuildException('Testing can\'t be null');
            }
            return this;
        }
        private String buildSignature(String input){
            System.debug(input);
            String qString = EncodingUtil.urlEncode(input,'UTF-8');
            System.debug(qString);
            qString = qString.replaceAll('%3D', '=');
            qString = qString.replaceAll('%26', '&');
            //qString = qString.replaceAll(' ', '+');
            System.debug(qString);
            Blob hash = Crypto.generateMac('hmacSHA256',Blob.valueOf(qString),Blob.valueOf('%ut@*7=_b3gE?wH!^=6!c3z+zu7g3r'));
            String hash64 = EncodingUtil.base64Encode(hash);
            System.debug(hash64);
            return hash64;
        } 
        global String toJSON(){
            String output = '{"checks":[';
            for(Integer i=0;i<checks.size();i++){
                output += checks[i].toJSON();
                if(i<checks.size()-1){
                    output += ',';
                }
            }
            output += ']';
            output += ',"pdf_background": '+(isTruthy(pdfBackground)?'1':'0');
            output += ',"return_pdf": '+(isTruthy(returnPDF)?'1':'0');
            output += ',"test": '+(isTruthy(testing)?'1':'0');
            output += ',"token": "'+token+'"';
            signature = buildSignature(toPHPObj());
            output += ',"signature": "'+signature+'"';
            output += '}';
            return output;
        }
        global String toPHPObj(){
            String output = '';
            for(Integer i=0;i<checks.size();i++){
                output += checks[i].toPHPObj('checks['+i+']');
                if(i<checks.size()-1){
                    output += '&';
                }
            }
            output += '&pdf_background='+(isTruthy(pdfBackground)?'1':'0');
            output += '&return_pdf='+(isTruthy(returnPDF)?'1':'0');
            output += '&test='+(isTruthy(testing)?'1':'0');
            output += '&token='+token;
            return output;
        }
    }
    global class Check extends baseClass{
        global Decimal amount {get;private set;}
        global String bankAccount {get;private set;}
        global String bankRouting {get;private set;}
        global String checkNumber {get;private set;}
        global Date myDate {get;private set;}
        global String memo {get;private set;}
        global String note {get;private set;}
        global String template {get;private set;}
        global Person payee {get;private set;}
        global Payer myPayer {get;private set;}
        global Check(Decimal a,String ba,String br,String cn,Person pe,Payer pr){
            if(!isBlank(a) && a>0){
                amount = a;
            } else{
                throw new CheckBuildException('Amount must be greater than zero');
            }
            if(!isBlankStr(ba)){
                bankAccount = ba;
            } else{
                throw new CheckBuildException('Bank Account # can\'t be empty');
            }
            if(!isBlank(br)){
                bankRouting = br;
            } else{
                throw new CheckBuildException('Bank Routing # can\'t be empty');
            }
            /*if(!isBlank(cn) && cn>=0){
                checkNumber = cn;
            } else{
                throw new CheckBuildException('Check # can\'t be less than zero');
            }*/
            if(!isBlankStr(cn)){//} && cn>=0){
                checkNumber = cn;
            } else{
                throw new CheckBuildException('Check # can\'t be less than zero');
            }
            if(!isBlank(pe)){
                payee = pe;
            } else{
                throw new CheckBuildException('Check must have a payee');
            }
            if(!isBlank(pr)){
                myPayer = pr;
            } else{
                throw new CheckBuildException('Check must have a payer');
            }
            myDate = Date.today();
        }
        global Check(Decimal a,String ba,String br,String cn,Person pe,Payer pr,Date d,String m,String n,String t){
            this(a,ba,br,cn,pe,pr);
            setDate(d);
            setMemo(m);
            setNote(n);
            setTemplate(t);
        }
        global Check setDate(Date d){
            if(!isBlank(d)){
                myDate = d;
            } else{
                throw new CheckBuildException('Date can\'t be null');
            }
            return this;
        }
        global Check setMemo(String m){
            if(!isBlankStr(m)){
                memo = m;
            } else{
                throw new CheckBuildException('Memo can\'t be empty');
            }
            return this;
        }
        global Check setNote(String n){
            if(!isBlankStr(n)){
                note = n;
            } else{
                throw new CheckBuildException('Note can\'t be empty');
            }
            return this;
        }
        global Check setTemplate(String t){
            if(!isBlankStr(t)){
                template = t;
            } else{
                throw new CheckBuildException('Template can\'t be empty');
            }
            return this;
        }
        global String toJSON(){
            String output = '{';
            output += '"amount":"'+amount+'",';
            output += '"bank_account":"'+bankAccount+'",';
            output += '"bank_routing":"'+bankRouting+'",';
            output += '"check_number":"'+checkNumber+'"';
            if(myDate!=null){
                String tmpDate = DateTime.newInstance(myDate, Time.newInstance(0,0,0,0)).formatGMT('MM\\/d\\/yyyy');
                output += ',"date":"'+tmpDate+'"';
            } else {
                output += ',"date":"'+DateTime.now();
            }
            if(memo!=null){
                output += ',"memo":"'+memo+'"';
            }
            if(note!=null){
                output += ',"note":"'+note+'"';
            }
            output += ','+payee.toJSON()+'';
            output += ','+myPayer.toJSON()+'';
            if(template!=null){
                output += ',"template":"'+template+'"';
            }
            output += '}';
            return output;
        }
        global String toPHPObj(String preKey){
            String output = preKey+'[amount]='+amount;
            output+= '&'+preKey+'[bank_account]='+bankAccount;
            output+= '&'+preKey+'[bank_routing]='+bankRouting;
            output+= '&'+preKey+'[check_number]='+checkNumber;
            if(myDate!=null){
                String tmpDate = DateTime.newInstance(myDate, Time.newInstance(0,0,0,0)).formatGMT('MM/d/yyyy');
                //tmpDate = tmpDate.replaceAll('\\\\\\/', '%5C%2F');
                output+= '&'+preKey+'[date]='+tmpDate;
            } else {
                output += '&'+preKey+'[date]='+DateTime.now();
            }
            if(memo!=null){
                output+= '&'+preKey+'[memo]='+memo;
            }
            if(note!=null){
                output+= '&'+preKey+'[note]='+note;
            }
            output+= '&'+payee.toPHPObj(preKey);
            output+= '&'+myPayer.toPHPObj(preKey);
            if(template!=null){
                output+= '&'+preKey+'[template]='+template;
            }
            return output;
        }
    }
    global virtual class Person extends baseClass{
        global String name {get;private set;}
        global Address myAddress {get;private set;}
        global String city {get;private set;}
        global String state {get;private set;}
        global String zip {get;private set;}
        global Person(String n,Address a,String c,String s,String z){
            if(!isBlankStr(n)){
                name=n;
            } else{
                throw new CheckBuildException('The name can\'t be empty');
            }
            if(!isBlank(a)){
                myAddress=a;
            } else{
                throw new CheckBuildException('The address can\'t be empty');
            }
            if(!isBlankStr(c)){
                city=c;
            } else{
                throw new CheckBuildException('The city can\'t be empty');
            }
            if(!isBlankStr(s)){
                state=s;
            } else{
                throw new CheckBuildException('The state can\'t be empty');
            }
            if(!isBlankStr(z)){
                zip=z;
            } else{
                throw new CheckBuildException('The zip can\'t be empty');
            }
        }
        global virtual String toJSON(){
            String output = '"payee":{';
            output += myAddress.toJSON()+',';
            output += '"city":"'+city+'",';
            output += '"name":"'+name+'",';
            output += '"state":"'+state+'",';
            output += '"zip":"'+zip+'"}';
            return output;
        }
        global virtual String toPHPObj(String preKey){
            String output = myAddress.toPHPObj(preKey+'[payee]');
            output+= '&'+preKey+'[payee][city]='+city;
            output+= '&'+preKey+'[payee][name]='+name;
            output+= '&'+preKey+'[payee][state]='+state;
            output+= '&'+preKey+'[payee][zip]='+zip;
            return output;
        }
    }
    global class Payer extends Person{
        global String signer {get;private set;}
        global Payer(String n,Address a,String c,String s,String z,String sign){
            super(n,a,c,s,z);
            if(!isBlankStr(sign)){
                signer=sign;
            } else{
                throw new CheckBuildException('The signer can\'t be empty');
            }
        }
        global override String toJSON(){
            String output = '"payer":{';
            output += myAddress.toJSON()+',';
            output += '"city":"'+city+'",';
            output += '"name":"'+name+'",';
            output += '"signer":"'+signer+'",';
            output += '"state":"'+state+'",';
            output += '"zip":"'+zip+'"}';
            return output;
        }
        global override String toPHPObj(String preKey){
            String output = myAddress.toPHPObj(preKey+'[payer]');
            output+= '&'+preKey+'[payer][city]='+city;
            output+= '&'+preKey+'[payer][name]='+name;
            output+= '&'+preKey+'[payer][signer]='+signer;
            output+= '&'+preKey+'[payer][state]='+state;
            output+= '&'+preKey+'[payer][zip]='+zip;
            return output;
        }
    }
    global class Address extends baseClass{
        global String line1 {get;private set;}
        global String line2 {get;private set;}
        global Address(String l1){
            if(!isBlankStr(l1)){
                line1 = l1;
            } else{
                throw new CheckBuildException('The address can\'t be empty');
            }
        }
        global Address(String l1, String l2){
            this(l1);
            if(!isBlankStr(l2)){
                line2 = l2;
            } else{
                line2=null;
            }
        }
        global String toJSON(){
            String output = '"address":{"line1":"';
            output += (line1+'"');
            if(line2!=null && line2!=''){
                output += ',"line2":"'+line2+'"}';
            } else{
                output += '}';
            }
            return output;
        }
        global String toPHPObj(String preKey){
            String output = preKey+'[address][line1]='+line1;
            if(!isBlankStr(line2)){
                output+= '&'+preKey+'[address][line2]='+line2;
            }
            return output;
        }
    }
    private class CTValidation{
        public String address1{get;private set;}
        public String address2{get;private set;}
        public String payeeName{get;private set;}
        public String city{get;private set;}
        public String state{get;private set;}
        public String zip{get;private set;}
        public Decimal amountTotal {get;private set;}
        private Id bankId{get;set;}
        public String note {get;set;}
        public String memo {get;set;}
        public CTValidation(String a1, String a2, String pn, String c, String s, String z, Id bi, Decimal a, String m, String n){
            this.address1 = a1;
            this.address2 = a2;
            this.payeeName = pn;
            this.city = c;
            this.state = s;
            this.zip = z;
            this.bankId = bi;
            this.amountTotal = a;
            this.memo = m;
            this.note = n;
        }
        public Boolean isEqual(CTValidation diff){
            note = 'Multiple';
            memo = 'Multiple';
            if(this.address1 != diff.address1){return false;}
            else if(this.address2 != diff.address2){return false;}
            else if(this.payeeName != diff.payeeName){return false;}
            else if(this.city != diff.city){return false;}
            else if(this.state != diff.state){return false;}
            else if(this.zip != diff.zip){return false;}
            else if(this.bankId != diff.bankId){return false;}
            return true;
        }
        public CTValidation addToAmountTotal(Decimal a){
            amountTotal += a;
            return this;
        }
    }
    
    global static List<CheckOrder> getMyCheckOrdersTester(){
        List<CheckOrder> checkOrders = new List<CheckOrder>();
        String tokenVal = 'j893hmavFj19_hFh6G2gjwHpqnBBsdf761j1zalhd3f';
        Address payerAddress = new Address('1111 south st','APT 1000');
        Payer mainPayer = new Payer('myBA.Company__c', payerAddress, 'myBA.City__c', 'GA', '#0039', 'myBA.Signature_Name__c');
        Person mainPayee = new Person('myCT.payeeName',payerAddress,'myCT.city','FL','123456');
        Check mainCheck = new Check(100.00,'001234','4321','000123',mainPayee,mainPayer);
        mainCheck.setTemplate('checkomatic');
        mainCheck.setDate(date.today());
        Check mainCheck2 = new Check(101.00,'001234','4321','1234',mainPayee,mainPayer);
        mainCheck2.setTemplate('B7200');
        //checkomatic
        //
        CheckOrder fullCheckOrder = new CheckOrder(tokenVal,true,true,true,new List<Check>{mainCheck,mainCheck2});
        fullCheckOrder.firstCkNum = 'date--checkomatic';
        fullCheckOrder.lastCkNum = 'B7200';
        checkOrders.add(fullCheckOrder);
        return checkOrders;
    }

    global static List<CheckOrder> getMyCheckOrders(Id ppId){
        
        String tokenVal = 'j893hmavFj19_hFh6G2gjwHpqnBBsdf761j1zalhd3f';
        List<Payment_Processing__c> myPP = [SELECT Id, Bank_Account__c, Starting_Check_Number__c, Ending_Check_Number__c, Payment_Grouping__c FROM Payment_Processing__c WHERE Id =: ppId];
        List<Claim_Transaction__c> myCTs;
        Bank_Account__c myBA;
        if(myPP.size()==1){
            myCTs = [SELECT Id, Name, Claimant_Name__c, Amount__c, Check_Number__c, Payee_Address_Line_1__c, Payee_Address_Line_2__c, Payee__c, Alternate_Payee_Name__c,
                     Payee_City__c, Payee_State__c, Payee_Postal_Code__c, Bank_Account_Lookup__c, Invoice_Number__c, Date_Pay_Service_Begin__c,
                     Date_Pay_Service_End__c, Claim__r.Date_of_Loss__c, Claim__r.Name  FROM Claim_Transaction__c WHERE Payment_Batch__c =: ppId];
            List<Bank_Account__c> tmpBank = [SELECT Id, Address_1__c, Address_2__c, Bank_Account_Number__c, Bank_Routing_Number__c, City__c, Company__c, Country__c, Postal_Code__c, Signature_Name__c, State__c FROM Bank_Account__c WHERE Id =: myPP[0].Bank_Account__c];
            if(tmpBank.size()==1){
                myBA = tmpBank[0];
            }
        }
        if(myBA==null || myCTs.size()==0){
            throw new CheckBuildException('Your payment batch'+(myBA==null?' is missing its required bank account.':' has no claim transactions.'));
        }
        
        Address payerAddress = new Address(myBA.Address_1__c,myBA.Address_2__c);
        Payer mainPayer = new Payer(myBA.Company__c, payerAddress, myBA.City__c, myBA.State__c, myBA.Postal_Code__c, myBA.Signature_Name__c);
        //Map<String,List<Claim_Transaction__c>> checkTransactions = new Map<String,List<Claim_Transaction__c>>();
        Map<String,CTValidation> checkValidations = new Map<String,CTValidation>();
        for(Claim_Transaction__c ct : myCTs){
            if(ct.Check_Number__c==null || ct.Check_Number__c==''){
                throw new CheckBuildException('Claim transaction('+ct.Name+') does not have a check number.');
            }
            String payeeName = '';
            if(ct.Alternate_Payee_Name__c!= null && ct.Alternate_Payee_Name__c.trim()!=''){
                payeeName = ct.Alternate_Payee_Name__c.trim();
            } else{
                payeeName = ct.Payee__c;
            }
            String myMemo = 'Invoice:'+ct.Invoice_Number__c+' From:'+(ct.Date_Pay_Service_Begin__c!=null?ct.Date_Pay_Service_Begin__c.format():'')+' To:'+(ct.Date_Pay_Service_End__c!=null?ct.Date_Pay_Service_End__c.format():'');
            String myNote = ''+ct.Claim__r.Name+', '+ct.Claimant_Name__c+' '+(ct.Claim__r.Date_of_Loss__c!=null?ct.Claim__r.Date_of_Loss__c.format():'');
            CTValidation myValidation = new CTValidation(ct.Payee_Address_Line_1__c,ct.Payee_Address_Line_2__c,payeeName,ct.Payee_City__c,ct.Payee_State__c,ct.Payee_Postal_Code__c,ct.Bank_Account_Lookup__c,ct.Amount__c, myMemo, myNote);
            if(checkValidations.containsKey(ct.Check_Number__c)){
                if(checkValidations.get(ct.Check_Number__c).isEqual(myValidation)){
                    checkValidations.get(ct.Check_Number__c).addToAmountTotal(ct.Amount__c);
                    ct.Check_Status__c = 'Issued';
                    ct.Date_Check_Issued__c = Date.today();
                    //checkTransactions.get(ct.Check_Number__c).add(ct);
                } else{
                    throw new CheckBuildException('Claim transaction('+ct.Name+') does not have the same payee information as other claim transactions that have the same check number.');
                }
            } else{
                //checkTransactions.put(ct.Check_Number__c, new List<Claim_Transaction__c>{ct});
                checkValidations.put(ct.Check_Number__c, myValidation);
                ct.Check_Status__c = 'Issued';
                ct.Date_Check_Issued__c = Date.today();
            }
        }
        Map<Integer,List<Check>> checks = new Map<Integer,List<Check>>();
        List<CheckOrder> checkOrders = new List<CheckOrder>();
        checks.put(0,new List<Check>());
        Integer currentKey = 0;
        List<String> checkKeys = new List<String>(checkValidations.keySet());
        checkKeys.sort();
        for(String k : checkKeys){
            CTValidation myCT = checkValidations.get(k);
            Address payeeAddress = new Address(myCT.address1,myCT.address2);
            Person mainPayee = new Person(myCT.payeeName,payeeAddress,myCT.city,myCT.state,myCT.zip);
            if(checks.get(currentKey).size()>=50){
                CheckOrder fullCheckOrder = new CheckOrder(tokenVal,true,true,true,checks.get(currentKey));
                fullCheckOrder.firstCkNum = checks.get(currentKey)[0].checkNumber;
                fullCheckOrder.lastCkNum = checks.get(currentKey)[checks.get(currentKey).size()-1].checkNumber;
                checkOrders.add(fullCheckOrder);
                currentKey += 1;
                checks.put(currentKey,new List<Check>());
            }
            Check myCheck = new Check(myCT.amountTotal,myBA.Bank_Account_Number__c,myBA.Bank_Routing_Number__c,k,mainPayee,mainPayer);
            checks.get(currentKey).add(myCheck.setMemo(myCT.memo).setNote(myCT.note));
        }
        CheckOrder fullCheckOrder = new CheckOrder(tokenVal,true,true,true,checks.get(currentKey));
        fullCheckOrder.firstCkNum = checks.get(currentKey)[0].checkNumber;
        fullCheckOrder.lastCkNum = checks.get(currentKey)[checks.get(currentKey).size()-1].checkNumber;
        checkOrders.add(fullCheckOrder);
        System.debug(checkOrders);
        update myCTs;
        return checkOrders;
    }

}