/*===========================================================================
     Added to RK base RMIS product as 04/05/2016
    ===========================================================================*/
    
global interface IUIController {
    UIManagerUtils.UIManager uiManager();
    ControllerAction.Bindings getActionBindings();
    ControllerAction.Bindings createActionBindings();
    PageReference invoke(String actionKey);
    void onActionBegin(ControllerAction invokedAction);
    void onBeforeCommit(ControllerAction invokedAction);
    void doCommit(ControllerAction invokedAction);
    void onCommitSuccess(ControllerAction invokedAction);
    void onCommitFailure(ControllerAction invokedAction);
    void onActionEnd(ControllerAction invokedAction);
    IUIController getSelf();
    FormUtils.FormStyleBinder getStyles();
    String getCompleteErrorSummary();
    String getActionErrorSummary();
    String getPlatformErrorSummary();
    String getErrorTitle();
    Boolean getHasPlatformError();
    Boolean getHasActionError();
    Boolean getHasAnyError();
    Integer getErrorCount();
    String getCurrentTab();
}