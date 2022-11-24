/*===========================================================================
     Added to RK base RMIS product as 04/05/2016
    ===========================================================================*/
    
/* ==============================================================================================================================================
 * Mike Ulveling
 * 
 * This interface is only necessary because Apex/Visualforce is a pile of garbage. Specifically in this case, an Apex Component's attributes 
 * can't "see" inner classes for use in the "type" attribute, e.g. UIManagerUtils.DialogInstance. So in this case, the public interface of 
 * DialogInstance must be pulled out into this redundant outer-class interface, which IS visible to the Component attribute's type.
 * 
 * Note that this interface must be kept in sync with the public interface of UIManagerUtils.DialogInstance.
 * ==============================================================================================================================================
 */
global interface IDialogProps {
    UIManagerUtils.UIManager getUIManager();
    
    // this wouldn't be necessary if Visualforce merge expressions handled escaping properly:
    String getDoubleQuoteLiteral();
    
    String getDialogKeyName();
    
    String getDialogKey();
    String getDialogContentTokenDivHtml();
    String getDialogContentTokenSpanHtml();
    
    String getLoadActionName();
    String getOpenScript();
    String getLoadFinishedScript();
    
    String getSaveActionName();
    String getSaveScript();
    String getSaveFinishedScript();
    
    // builder methods:
    UIManagerUtils.DialogInstance setFixedWidth(Integer width);
    UIManagerUtils.DialogInstance setCalculatedWidth(String scriptFunctionPtr);
    UIManagerUtils.DialogInstance setTransitionalHeight(Integer height);
    UIManagerUtils.DialogInstance setOpenImmediate(Boolean openImmediate);
    UIManagerUtils.DialogInstance setKeepContentsInDom(Boolean keepInDom);
    UIManagerUtils.DialogPostbackAction getPostbackAction(UIManagerUtils.DialogPostbackActionKeys actionKey);
    
    String getOuterDivDomId();
    
    String getInnerDivDomId();
    
    String getTitleUpdateNodeDomId();
    
    String getScriptsNodeDomId();
    
    String getScriptsDivDomId();
    
    String getCloseDialogScript();
    
    String getReCenterDialogScript();

    FormUtils.InlineDialogStyleBinder getStyles();
    
    /*
    // TODO: deprecated; use getSaveFinishedScript()
    String getFireDialogSubmitFinishedScript();
    // TODO: deprecated; use getLoadFinishedScript()
    String getFireDialogContentsLoadedScript();
    // TODO: Deprecated; use getLoadActionName()
    String getDelayedOpenActionName();
    void noOp();
    */
}