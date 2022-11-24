/*===========================================================================
     Added to RK base RMIS product as  4/05/2016
 ===========================================================================*/
  
/*
 * This has no purpose other than to cut the Apex/Visualforce compiler's meat into smaller chunks so it doesn't choke
 */
global interface scpControllerInterface {
    
    Boolean getHasFailure();
    scpAggregations getAggregations();
    FieldsetGridFactory getFieldsetGridFactory();
    
}