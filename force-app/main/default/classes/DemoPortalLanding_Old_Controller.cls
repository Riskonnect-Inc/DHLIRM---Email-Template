public class DemoPortalLanding_Old_Controller {

    public Contact employee {get; private set;}

    public String pageData {get; private set;}


    public DemoPortalLanding_Old_Controller(rkl.JS_Search ignore) {

    }

    private void init(){
    rkl.JS_Search.InLineSearches searchTable = new rkl.JS_Search.InLineSearches('Intake__c')
          .setResults('FIELDSET::Landing_Results')
          .setTypeChild('')
          .setEditAble(true)
          .setMyWhere(//new rkl.GS_Soql.andCondition( //im_status__c = 'Completed' and reporter__c = employee.ID
                      // Uncomment for real sites
                      //new rkl.GS_Soql.fieldCondition('reporter__c').equalToVal(employee.Id),
                      new rkl.GS_Soql.fieldCondition('im_status__c').notequalToVal('Completed'))
          ;

    pageData = JSON.serialize(new rkl.JS_Search(searchTable).pageData);
    }

    public PageReference checkValidity() {
        if(authViaCookie()){
            this.init();
            return null;
        } else {
            return Page.DemoLogin_Old;
        }
    }

    private Boolean authViaCookie(){
        Cookie cookieToken = ApexPages.currentPage().getCookies().get('TokenRK');
        if(cookieToken!=null){
            String cookieVal = decryptCookie(EncodingUtil.base64Decode(cookieToken.getValue()));
            List<String> cookieVals = cookieVal.split('!,!');
            Integer timeLengthValid = cookieToken.getMaxAge();//maybe should be hardcoded to avoid cookie tampering
            Datetime createdDate = Datetime.valueOfGmt(cookieVals[1]).addSeconds(timeLengthValid);
            if(createdDate<=Datetime.now()){
                List<Contact> contacts = [SELECT Id, Site_Access_Approved__c FROM Contact WHERE Id=:cookieVals[0]];
                if(contacts.size()==1 /*&& contacts[0].Site_Access_Approved__c==true*/){
                   this.employee = contacts[0];
                   return true;
                }
            }
        }

        return false;
    }

    private String decryptCookie(Blob val){
        return Crypto.decrypt('AES128',Blob.valueOf('INeedSixTeenChar'),Blob.valueOf('INeedSixTeenChar'),val).toString();
    }

}