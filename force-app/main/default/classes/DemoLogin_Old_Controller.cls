public class DemoLogin_Old_Controller {

    public String userLastName {get; set;}
    public Integer userYearofBirth {get; set;}
    public Integer userMonthofBirth {get; set;}
    public Integer userDayofBirth {get; set;}

    public String message {get; set;}


    public PageReference checkValidity(){
        if(authViaCookie()){
            return Page.DemoPortalLanding_Old;
        } else {
            return null;
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
                List<Contact> employees = [SELECT Id FROM Contact WHERE Id=:cookieVals[0]];
                if(employees.size()==1){
                   return true;
                }
            }
        }

        return false;
    }

    private Blob encryptCookie(String val){
        return Crypto.encrypt('AES128',Blob.valueOf('INeedSixTeenChar'),Blob.valueOf('INeedSixTeenChar'),Blob.valueOf(val));
    }
    private String decryptCookie(Blob val){
        return Crypto.decrypt('AES128',Blob.valueOf('INeedSixTeenChar'),Blob.valueOf('INeedSixTeenChar'),val).toString();
    }

    public PageReference validateSubmit() {
        this.message = null;
        date dob = date.newInstance(userYearofBirth, userMonthofBirth, userDayofBirth);

        List<Contact> employees = [SELECT Id FROM Contact WHERE LastName=:userLastName and Birthdate=:dob];
        if (employees.size() == 0) {
            this.message = 'Invalid name or date of birth';
        } else if (employees.size() > 1) {
            this.message = 'An unknown error occurred, contact your system administrator for more information';
        }

        if (this.message == null) {
            String cookieToken = employees.get(0).id +'!,!'+ String.valueOf(DateTime.now());
            encryptCookie(cookieToken);
            cookieToken = EncodingUtil.base64Encode(encryptCookie(cookieToken));
            //cookieToken = EncodingUtil.urlEncode(encryptCookie(cookieToken), 'UTF-8');
            Cookie myCookie = new Cookie('TokenRK',cookieToken,null,-1,true);
            ApexPages.currentPage().setCookies(new Cookie[]{myCookie});
            PageReference portalHomePage = Page.DemoPortalLanding_Old;
            return portalHomePage;
        } else {
            PageReference errorPage = Page.DemoLogin_Old;
            return errorPage;
        }
    }
}