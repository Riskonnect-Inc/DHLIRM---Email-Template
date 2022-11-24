/*===========================================================================
     Added to RK base RMIS product as 05/26/2015
    ===========================================================================*/
    
@isTest
private class gsSoqlTest {

    @isTest static void test_method_one() {
        List<rkl__PortalTestObject__c> queryObjects = new List<rkl__PortalTestObject__c>();
        queryObjects.add(new rkl__PortalTestObject__c(
            rkl__Checkbox_Field__c                  = true,
            rkl__Date_Field__c                      =  Date.newInstance(1990, 01, 20) ,
            rkl__Date_Time_Field__c                 =  Datetime.newInstance(1990, 01, 20, 18, 30, 05),   
            rkl__Email_Field__c                     = 'test@test.com',
            rkl__IM_Status__c                       = 'Hi there1',
            rkl__Multi_Select_Picklist_Field__c     = 'One;Two;Three',
            rkl__Number_Decimal__c                  = 123.32,
            rkl__Number_Digit__c                    = 1234,
            rkl__Number_Field__c                    = 12.234,
            rkl__Other_Lookup__c                    = null,
            rkl__Percent_Field__c                   = 11.11,
            rkl__Phone_Number_Field__c              = '7707707700',
            rkl__Picklist_Field__c                  = 'Hi'
        ));
        queryObjects.add(new rkl__PortalTestObject__c(
            rkl__Checkbox_Field__c                  = true,
            rkl__Date_Field__c                      = Date.newInstance(1990, 01, 21) ,
            rkl__Date_Time_Field__c                 = Datetime.newInstance(1990, 01, 20, 18, 35, 05),
            rkl__Email_Field__c                     = 'test@tester.com',
            rkl__IM_Status__c                       = 'Hi there2',
            rkl__Multi_Select_Picklist_Field__c     = 'One;Two',
            rkl__Number_Decimal__c                  = 123.32,
            rkl__Number_Digit__c                    = 1234,
            rkl__Number_Field__c                    = 13.234,
            rkl__Other_Lookup__c                    = null,
            rkl__Percent_Field__c                   = 11.11,
            rkl__Phone_Number_Field__c              = '7707707700',
            rkl__Picklist_Field__c                  = 'Hi'
        ));
        queryObjects.add(new rkl__PortalTestObject__c(
            rkl__Checkbox_Field__c                  = false,
            rkl__Date_Field__c                      = Date.newInstance(1990, 01, 22) ,
            rkl__Date_Time_Field__c                 = Datetime.newInstance(1990, 01, 21, 18, 35, 05),
            rkl__Email_Field__c                     = 'test@test.com',
            rkl__IM_Status__c                       = 'Hi there3',
            rkl__Multi_Select_Picklist_Field__c     = 'One;Three',
            rkl__Number_Decimal__c                  = 123.32,
            rkl__Number_Digit__c                    = 1234,
            rkl__Number_Field__c                    = 14.234,
            rkl__Other_Lookup__c                    = null,
            rkl__Percent_Field__c                   = 11.11,
            rkl__Phone_Number_Field__c              = '7707707700',
            rkl__Picklist_Field__c                  = 'Hi'
        ));
        queryObjects.add(new rkl__PortalTestObject__c(
            rkl__Checkbox_Field__c                  = true,
            rkl__Date_Field__c                      =Date.newInstance(1990, 01, 23) ,
            rkl__Date_Time_Field__c                 = Datetime.newInstance(1990, 01, 22, 18, 30, 05),
            rkl__Email_Field__c                     = 'test@test.com',
            rkl__IM_Status__c                       = 'Hi there4',
            rkl__Multi_Select_Picklist_Field__c     = 'One;Two;Three',
            rkl__Number_Decimal__c                  = 123.32,
            rkl__Number_Digit__c                    = 1234,
            rkl__Number_Field__c                    = 12.234,
            rkl__Other_Lookup__c                    = null,
            rkl__Percent_Field__c                   = 11.11,
            rkl__Phone_Number_Field__c              = '7707707700',
            rkl__Picklist_Field__c                  = 'Bye'
        ));
        insert queryObjects;

        gsSoql test = new gsSoql();
        test.selectFields('Name');
        test.selectFields(new Set<String>{'rkl__Checkbox_Field__c','rkl__Number_Decimal__c','rkl__IM_Status__c'});
        test.selectCount();
        test.selectCount('test');
        test.selectFields()
            .selectCount()
            .selectCount('test')
            .soql();
        test.selectFields()
            .deselectCount()
            .add(new Set<String>{'rkl__Checkbox_Field__c','rkl__Number_Decimal__c','rkl__IM_Status__c'})
            .add(new List<String>{'rkl__Checkbox_Field__c','rkl__Number_Decimal__c','rkl__IM_Status__c'});
        test.selectFields(new List<String>{'rkl__Checkbox_Field__c','rkl__Number_Decimal__c','rkl__IM_Status__c'});
        test.fromObject('rkl__PortalTestObject__c');
        System.assertEquals('rkl__PortalTestObject__c',test.fromObject().obj);
        List<Sobject> results = Database.query(test.soql());
        System.assertEquals(4,results.size(),'Should bring back all 4 results');
        test.orderBy('rkl__Picklist_Field__c');
        test.orderBy('rkl__IM_Status__c',false,false);
        test.selectFields().add('rkl__Picklist_Field__c');
        results = Database.query(test.soql());
        System.assertEquals('Bye',(String)results[0].get('rkl__Picklist_Field__c'),'');
        System.assertEquals('Hi there3',(String)results[1].get('rkl__IM_Status__c'),'');
        test.limitRecords('2');
        test.offsetRecords('2');
        results = Database.query(test.soql());
        System.assertEquals('Hi there2',(String)results[0].get('rkl__IM_Status__c'),'');
        Boolean didFail=false;
        try{
            test.limitRecords('2q1');
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        didFail=false;
        try{
            test.offsetRecords('2q1');
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        didFail=false;
        try{
            test.offsetRecords('2001');
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        System.assertEquals(2,test.limitRecords().lim);
        System.assertEquals(2,test.offsetRecords().offset);
        System.assertEquals(1,test.orderBy().orderByFields.size());
        List<gsSoql.orderByField> tmpOB = test.orderBy().orderByFields;
        didFail=false;
        try{
            test.orderBy().add(tmpOB);
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        didFail=false;
        try{
            test.orderBy().add(tmpOB[0]);
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        didFail=false;
        try{
            test.orderBy().add('rkl__IM_Status__c');
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        didFail=false;
        try{
            test.orderBy().add('rkl__IM_Status__c',false);
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        didFail=false;
        try{
            test.orderBy().add('rkl__IM_Status__c',false,false);
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        didFail=false;
        try{
            test.orderBy().add(new List<String>{'rkl__Picklist_Field__c','rkl__Picklist_Field__c'});
        }catch(gsSoql.gsSoqlBuilderException e){
            didFail = true;
        }
        System.assert(didFail,'Should have failed');
        test.orderBy().clear();
        System.assertEquals(0,test.orderBy().orderByFields.size());
        test.orderBy(new List<String>{'rkl__Picklist_Field__c','rkl__IM_Status__c'});
        test.orderBy('rkl__Picklist_Field__c',false);
        test.orderBy().clear();
        test.limitRecords().clear();
        test.offsetRecords().clear();

        Boolean trueBool = true;
        Boolean falseBool = false;
        gsSoql.fieldCondition boolTrue1 = new gsSoql.fieldCondition('rkl__Checkbox_Field__c').equalToVal(trueBool);
        gsSoql.fieldCondition boolFalse1 = new gsSoql.fieldCondition('rkl__Checkbox_Field__c').equalToVal(falseBool);
        gsSoql.fieldCondition boolTrue2 = new gsSoql.fieldCondition('rkl__Checkbox_Field__c').equalToVar('trueBool');
        gsSoql.fieldCondition boolFalse2 = new gsSoql.fieldCondition('rkl__Checkbox_Field__c').equalToVar('falseBool');

        test.whereC(boolTrue1);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(boolFalse1);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(boolTrue2);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(boolFalse2);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');

        Date dat = Date.newInstance(1990, 01, 21) ;
        List<Date> lDate = new List<Date>{Date.newInstance(1990, 01, 21),Date.newInstance(1990, 01, 22)};
        gsSoql.fieldCondition dateEqu = new gsSoql.fieldCondition('rkl__Date_Field__c').equalToVal(dat);
        gsSoql.fieldCondition dateNEqu = new gsSoql.fieldCondition('rkl__Date_Field__c').notEqualToVal(dat);
        gsSoql.fieldCondition dateGT = new gsSoql.fieldCondition('rkl__Date_Field__c').greaterThanVal(dat);
        gsSoql.fieldCondition dateLT = new gsSoql.fieldCondition('rkl__Date_Field__c').lessThanVal(dat);
        gsSoql.fieldCondition dateGTE = new gsSoql.fieldCondition('rkl__Date_Field__c').greaterThanEqualVal(dat);
        gsSoql.fieldCondition dateLTE = new gsSoql.fieldCondition('rkl__Date_Field__c').lessThanEqualVal(dat);
        gsSoql.fieldCondition dateIN = new gsSoql.fieldCondition('rkl__Date_Field__c').inVal(lDate);
        gsSoql.fieldCondition dateNIN = new gsSoql.fieldCondition('rkl__Date_Field__c').notInVal(lDate);
        gsSoql.fieldCondition dateEqu2 = new gsSoql.fieldCondition('rkl__Date_Field__c').equalToVar('dat');
        gsSoql.fieldCondition dateNEqu2 = new gsSoql.fieldCondition('rkl__Date_Field__c').notEqualToVar('dat');
        gsSoql.fieldCondition dateGT2 = new gsSoql.fieldCondition('rkl__Date_Field__c').greaterThanVar('dat');
        gsSoql.fieldCondition dateLT2 = new gsSoql.fieldCondition('rkl__Date_Field__c').lessThanVar('dat');
        gsSoql.fieldCondition dateGTE2 = new gsSoql.fieldCondition('rkl__Date_Field__c').greaterThanEqualVar('dat');
        gsSoql.fieldCondition dateLTE2 = new gsSoql.fieldCondition('rkl__Date_Field__c').lessThanEqualVar('dat');
        gsSoql.fieldCondition dateIN2 = new gsSoql.fieldCondition('rkl__Date_Field__c').inVar('lDate');
        gsSoql.fieldCondition dateNIN2 = new gsSoql.fieldCondition('rkl__Date_Field__c').notInVar('lDate');

        test.whereC(dateEqu);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dateNEqu);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dateGT);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dateLT);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dateGTE);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dateLTE);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dateIN);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dateNIN);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dateEqu2);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dateNEqu2);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dateGT2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dateLT2);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dateGTE2);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dateLTE2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dateIN2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dateNIN2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');

        Datetime dateT =  Datetime.newInstance(1990, 01, 20, 18, 35, 05);
        List<Datetime> lDateT = new List<Datetime>{Datetime.newInstance(1990, 01, 20, 18, 35, 05),Datetime.newInstance(1990, 01, 21, 18, 35, 05)};
        gsSoql.fieldCondition dateTEqu = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').equalToVal(dateT);
        gsSoql.fieldCondition dateTNEqu = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').notEqualToVal(dateT);
        gsSoql.fieldCondition dateTGT = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').greaterThanVal(dateT);
        gsSoql.fieldCondition dateTLT = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').lessThanVal(dateT);
        gsSoql.fieldCondition dateTGTE = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').greaterThanEqualVal(dateT);
        gsSoql.fieldCondition dateTLTE = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').lessThanEqualVal(dateT);
        gsSoql.fieldCondition dateTIN = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').inVal(lDateT);
        gsSoql.fieldCondition dateTNIN = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').notInVal(lDateT);
        gsSoql.fieldCondition dateTEqu2 = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').equalToVar('dateT');
        gsSoql.fieldCondition dateTNEqu2 = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').notEqualToVar('dateT');
        gsSoql.fieldCondition dateTGT2 = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').greaterThanVar('dateT');
        gsSoql.fieldCondition dateTLT2 = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').lessThanVar('dateT');
        gsSoql.fieldCondition dateTGTE2 = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').greaterThanEqualVar('dateT');
        gsSoql.fieldCondition dateTLTE2 = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').lessThanEqualVar('dateT');
        gsSoql.fieldCondition dateTIN2 = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').inVar('lDateT');
        gsSoql.fieldCondition dateTNIN2 = new gsSoql.fieldCondition('rkl__Date_Time_Field__c').notInVar('lDateT');

        //test.whereC(dateTEqu);
        //results = Database.query(test.soql());
        //System.assertEquals(1,results.size(),'');
        //test.whereC(dateTNEqu);
        //results = Database.query(test.soql());
        //System.assertEquals(3,results.size(),'');
        //test.whereC(dateTGT);
        //results = Database.query(test.soql());
        //System.assertEquals(2,results.size(),'');
        //test.whereC(dateTLT);
        //results = Database.query(test.soql());
        //System.assertEquals(1,results.size(),'');
        //test.whereC(dateTGTE);
        //results = Database.query(test.soql());
        //System.assertEquals(3,results.size(),'');
        //test.whereC(dateTLTE);
        //results = Database.query(test.soql());
        //System.assertEquals(2,results.size(),'');
        //test.whereC(dateTIN);
        //results = Database.query(test.soql());
        //System.assertEquals(2,results.size(),'');
        //test.whereC(dateTNIN);
        //results = Database.query(test.soql());
        //System.assertEquals(2,results.size(),'');
        //test.whereC(dateTEqu2);
        //results = Database.query(test.soql());
        //System.assertEquals(1,results.size(),'');
        //test.whereC(dateTNEqu2);
        //results = Database.query(test.soql());
        //System.assertEquals(3,results.size(),'');
        //test.whereC(dateTGT2);
        //results = Database.query(test.soql());
        //System.assertEquals(2,results.size(),'');
        //test.whereC(dateTLT2);
        //results = Database.query(test.soql());
        //System.assertEquals(1,results.size(),'');
        //test.whereC(dateTGTE2);
        //results = Database.query(test.soql());
        //System.assertEquals(3,results.size(),'');
        //test.whereC(dateTLTE2);
        //results = Database.query(test.soql());
        //System.assertEquals(2,results.size(),'');
        //test.whereC(dateTIN2);
        //results = Database.query(test.soql());
        //System.assertEquals(2,results.size(),'');
        //test.whereC(dateTNIN2);
        //results = Database.query(test.soql());
        //System.assertEquals(2,results.size(),'');

        Integer ints = 13;
        List<Integer> intL = new List<Integer>{10,12};
        gsSoql.fieldCondition intsEqu = new gsSoql.fieldCondition('rkl__Number_Field__c').equalToVal(ints);
        gsSoql.fieldCondition intsNEqu = new gsSoql.fieldCondition('rkl__Number_Field__c').notEqualToVal(ints);
        gsSoql.fieldCondition intsGT = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanVal(ints);
        gsSoql.fieldCondition intsLT = new gsSoql.fieldCondition('rkl__Number_Field__c').lessThanVal(ints);
        gsSoql.fieldCondition intsGTE = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanEqualVal(ints);
        gsSoql.fieldCondition intsLTE = new gsSoql.fieldCondition('rkl__Number_Field__c').lessThanEqualVal(ints);
        gsSoql.fieldCondition intsIN = new gsSoql.fieldCondition('rkl__Number_Field__c').inVal(intL);
        gsSoql.fieldCondition intsNIN = new gsSoql.fieldCondition('rkl__Number_Field__c').notInVal(intL);
        gsSoql.fieldCondition intsEqu2 = new gsSoql.fieldCondition('rkl__Number_Field__c').equalToVar('ints');
        gsSoql.fieldCondition intsNEqu2 = new gsSoql.fieldCondition('rkl__Number_Field__c').notEqualToVar('ints');
        gsSoql.fieldCondition intsGT2 = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanVar('ints');
        gsSoql.fieldCondition intsLT2 = new gsSoql.fieldCondition('rkl__Number_Field__c').lessThanVar('ints');
        gsSoql.fieldCondition intsGTE2 = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanEqualVar('ints');
        gsSoql.fieldCondition intsLTE2 = new gsSoql.fieldCondition('rkl__Number_Field__c').lessThanEqualVar('ints');
        gsSoql.fieldCondition intsIN2 = new gsSoql.fieldCondition('rkl__Number_Field__c').inVar('intL');
        gsSoql.fieldCondition intsNIN2 = new gsSoql.fieldCondition('rkl__Number_Field__c').notInVar('intL');

        test.whereC(intsEqu);
        results = Database.query(test.soql());
        System.assertEquals(0,results.size(),'');
        test.whereC(intsNEqu);
        results = Database.query(test.soql());
        System.assertEquals(4,results.size(),'');
        test.whereC(intsGT);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(intsLT);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(intsGTE);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(intsLTE);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(intsIN);
        results = Database.query(test.soql());
        System.assertEquals(0,results.size(),'');
        test.whereC(intsNIN);
        results = Database.query(test.soql());
        System.assertEquals(4,results.size(),'');
        test.whereC(intsEqu2);
        results = Database.query(test.soql());
        System.assertEquals(0,results.size(),'');
        test.whereC(intsNEqu2);
        results = Database.query(test.soql());
        System.assertEquals(4,results.size(),'');
        test.whereC(intsGT2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(intsLT2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(intsGTE2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(intsLTE2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(intsIN2);
        results = Database.query(test.soql());
        System.assertEquals(0,results.size(),'');
        test.whereC(intsNIN2);
        results = Database.query(test.soql());
        System.assertEquals(4,results.size(),'');

        Double dubs = 13.234;
        List<Double> dubL = new List<Double>{13.234,12.234};
        gsSoql.fieldCondition dubsEqu = new gsSoql.fieldCondition('rkl__Number_Field__c').equalToVal(dubs);
        gsSoql.fieldCondition dubsNEqu = new gsSoql.fieldCondition('rkl__Number_Field__c').notEqualToVal(dubs);
        gsSoql.fieldCondition dubsGT = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanVal(dubs);
        gsSoql.fieldCondition dubsLT = new gsSoql.fieldCondition('rkl__Number_Field__c').lessThanVal(dubs);
        gsSoql.fieldCondition dubsGTE = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanEqualVal(dubs);
        gsSoql.fieldCondition dubsLTE = new gsSoql.fieldCondition('rkl__Number_Field__c').lessThanEqualVal(dubs);
        gsSoql.fieldCondition dubsIN = new gsSoql.fieldCondition('rkl__Number_Field__c').inVal(dubL);
        gsSoql.fieldCondition dubsNIN = new gsSoql.fieldCondition('rkl__Number_Field__c').notInVal(dubL);
        gsSoql.fieldCondition dubsEqu2 = new gsSoql.fieldCondition('rkl__Number_Field__c').equalToVar('dubs');
        gsSoql.fieldCondition dubsNEqu2 = new gsSoql.fieldCondition('rkl__Number_Field__c').notEqualToVar('dubs');
        gsSoql.fieldCondition dubsGT2 = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanVar('dubs');
        gsSoql.fieldCondition dubsLT2 = new gsSoql.fieldCondition('rkl__Number_Field__c').lessThanVar('dubs');
        gsSoql.fieldCondition dubsGTE2 = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanEqualVar('dubs');
        gsSoql.fieldCondition dubsLTE2 = new gsSoql.fieldCondition('rkl__Number_Field__c').lessThanEqualVar('dubs');
        gsSoql.fieldCondition dubsIN2 = new gsSoql.fieldCondition('rkl__Number_Field__c').inVar('dubL');
        gsSoql.fieldCondition dubsNIN2 = new gsSoql.fieldCondition('rkl__Number_Field__c').notInVar('dubL');

        test.whereC(dubsEqu);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dubsNEqu);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dubsGT);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dubsLT);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dubsGTE);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dubsLTE);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dubsIN);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dubsNIN);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dubsEqu2);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dubsNEqu2);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dubsGT2);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(dubsLT2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dubsGTE2);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(dubsLTE2);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dubsIN2);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(dubsNIN2);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');

        String str1 = 'Hi there1';
        String str2 = 'Hi there%';
        List<String> strL = new List<String>{'Hi there1','Hi there3'};
        gsSoql.fieldCondition strEqu = new gsSoql.fieldCondition('rkl__IM_Status__c').equalToVal(str1);
        gsSoql.fieldCondition strNEqu = new gsSoql.fieldCondition('rkl__IM_Status__c').notEqualToVal(str1);
        gsSoql.fieldCondition strSW = new gsSoql.fieldCondition('rkl__IM_Status__c').startsWithVal(str1);
        gsSoql.fieldCondition strEW = new gsSoql.fieldCondition('rkl__IM_Status__c').endsWithVal(str1);
        gsSoql.fieldCondition strCon = new gsSoql.fieldCondition('rkl__IM_Status__c').containsVal(str1);
        gsSoql.fieldCondition strLike = new gsSoql.fieldCondition('rkl__IM_Status__c').likeVal(str2);
        gsSoql.fieldCondition strIN = new gsSoql.fieldCondition('rkl__IM_Status__c').inVal(strL);
        gsSoql.fieldCondition strNIN = new gsSoql.fieldCondition('rkl__IM_Status__c').notInVal(strL);
        gsSoql.fieldCondition strEquL = new gsSoql.fieldCondition('rkl__IM_Status__c').equalToVar('str1');
        gsSoql.fieldCondition strNEquL = new gsSoql.fieldCondition('rkl__IM_Status__c').notEqualToVar('str1');
        gsSoql.fieldCondition strSWL = new gsSoql.fieldCondition('rkl__IM_Status__c').startsWithVar('str1');
        gsSoql.fieldCondition strEWL = new gsSoql.fieldCondition('rkl__IM_Status__c').endsWithVar('str1');
        gsSoql.fieldCondition strConL = new gsSoql.fieldCondition('rkl__IM_Status__c').containsVar('str1');
        gsSoql.fieldCondition strLikeL = new gsSoql.fieldCondition('rkl__IM_Status__c').likeVar('str2');
        gsSoql.fieldCondition strINL = new gsSoql.fieldCondition('rkl__IM_Status__c').inVar('strL');
        gsSoql.fieldCondition strNINL = new gsSoql.fieldCondition('rkl__IM_Status__c').notInVar('strL');

        test.whereC(strEqu);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strNEqu);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(strSW);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strEW);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strCon);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strLike);
        results = Database.query(test.soql());
        System.assertEquals(4,results.size(),'');
        test.whereC(strIN);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(strNIN);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(strEquL);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strNEquL);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(strSWL);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strEWL);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strConL);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strLikeL);
        results = Database.query(test.soql());
        System.assertEquals(4,results.size(),'');
        test.whereC(strINL);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(strNINL);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');

        String strP = 'one;two';
        List<String> strPL = new List<String>{'one','two'};
        gsSoql.fieldCondition strPEqu = new gsSoql.fieldCondition('rkl__Multi_Select_Picklist_Field__c').equalToVal(strP);
        gsSoql.fieldCondition strPNEqu = new gsSoql.fieldCondition('rkl__Multi_Select_Picklist_Field__c').notEqualToVal(strP);
        gsSoql.fieldCondition strPSW = new gsSoql.fieldCondition('rkl__Multi_Select_Picklist_Field__c').includesVal(strPL);
        gsSoql.fieldCondition strPEW = new gsSoql.fieldCondition('rkl__Multi_Select_Picklist_Field__c').excludesVal(strPL);
        gsSoql.fieldCondition strPEqu2 = new gsSoql.fieldCondition('rkl__Multi_Select_Picklist_Field__c').equalToVar('strP');
        gsSoql.fieldCondition strPNEqu2 = new gsSoql.fieldCondition('rkl__Multi_Select_Picklist_Field__c').notEqualToVar('strP');

        test.whereC(strPEqu);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strPNEqu);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');
        test.whereC(strPSW);
        results = Database.query(test.soql());
        System.assertEquals(4,results.size(),'');
        test.whereC(strPEW);
        results = Database.query(test.soql());
        System.assertEquals(0,results.size(),'');

        test.whereC(strPEqu2);
        results = Database.query(test.soql());
        System.assertEquals(1,results.size(),'');
        test.whereC(strPNEqu2);
        results = Database.query(test.soql());
        System.assertEquals(3,results.size(),'');


        gsSoql.fieldCondition a1 = new gsSoql.fieldCondition('rkl__Date_Field__c').greaterThanEqualVal(Date.newInstance(1990, 01, 21));
        gsSoql.fieldCondition a2 = new gsSoql.fieldCondition('rkl__Checkbox_Field__c').equalToVal(true);
        gsSoql.fieldCondition o1 = new gsSoql.fieldCondition('rkl__Number_Field__c').greaterThanEqualVal(13);
        gsSoql.fieldCondition o2 = new gsSoql.fieldCondition('rkl__Number_Field__c').equalToVal(12.234);
        gsSoql.fieldCondition o3 = new gsSoql.fieldCondition('rkl__IM_Status__c').equalToVal('Hi there 1');
        List<gsSoql.fieldCondition> fConL = new List<gsSoql.fieldCondition>{a1,a2};
        gsSoql.orCondition orConE = new gsSoql.orCondition();
        gsSoql.orCondition orCon = new gsSoql.orCondition(o1, o2);
        orCon.add(o3);
        gsSoql.andCondition andConE = new gsSoql.andCondition();
        gsSoql.andCondition andCon = new gsSoql.andCondition(a1, a2);
        andCon.add(orCon);
        test.whereC(andCon);
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        test.whereC(new gsSoql.notCondition(andCon));
        results = Database.query(test.soql());
        System.assertEquals(2,results.size(),'');
        andCon.add(fConL);
        System.debug(test.whereC());

        


        System.assertEquals(4,test.selectFields().fields.size());
        test.selectFields().clear();
        System.assertEquals(0,test.selectFields().fields.size());
    }
    
    /*
    rkl__Checkbox_Field__c                  = true,
    rkl__Date_Field__c                      = Date.parse('01/20/1990'),
    rkl__Date_Time_Field__c                 = Datetime.parse('01/20/1990 6:30 PM'),
    rkl__Email_Field__c                     = 'test@test.com',
    rkl__IM_Status__c                       = 'Hi there1',
    rkl__Multi_Select_Picklist_Field__c     = 'One;Two;Three',
    rkl__Number_Decimal__c                  = 123.32,
    rkl__Number_Digit__c                    = 1234,
    rkl__Number_Field__c                    = 12.234,
    rkl__Other_Lookup__c                    = null,
    rkl__Percent_Field__c                   = 11.11,
    rkl__Phone_Number_Field__c              = '7707707700',
    rkl__Picklist_Field__c                  = 'Hi'
    */
    
}