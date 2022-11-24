/*===========================================================================
     Added to RK base RMIS product as  6/4/2013
     Author : json Bradley
   ===========================================================================*/
    

global class TimeDimensionDummyInsertIterable implements Iterator<Time_Dimension__c>, Iterable<Time_Dimension__c> {
    global Integer counter {get; set;}
    global TimeDimensionDummyInsertIterable(Integer numberToGenerate)
    {
        counter = numberToGenerate;
    }
    
    global boolean hasNext()
    {
        return counter > 0;
    }
    
    global Time_Dimension__c next()
    {
        return new Time_Dimension__c(Date_Key_Unique__c=String.valueOf(counter), Name='TimeDimDummy'+counter--);
    }
    
    global Iterator<Time_Dimension__c> Iterator()
    {
        return this;
    }
}