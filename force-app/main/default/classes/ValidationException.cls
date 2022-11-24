/*===========================================================================
     Added to RK base RMIS product as  04/05/2016
   ===========================================================================*/
    
global class ValidationException extends Exception {
    public String messagesTitle = null;
    public Boolean isMessagesTitleHtml = false;
    public Boolean useInitialMessage = true;
    public Object[] multipartMessages = new Object[] {};
    
    global ValidationException setUseInitialMessage(Boolean use) {
        this.useInitialMessage = use;
        return this;
    }
    
    global ValidationException setMessagesTitle(String messagesTitle, Boolean isMessagesTitleHtml) {
        this.messagesTitle = messagesTitle;
        this.isMessagesTitleHtml = isMessagesTitleHtml;
        return this;
    }
    
    global ValidationException addMessage(String msg) {
        multipartMessages.add(msg);
        return this;
    }
    
    global ValidationException addMessage(String component, String summary) {
        multipartMessages.add(new CoreLangUtils.MessageTuple(component, summary));
        return this;
    }
    
    global ValidationException addMessage(CoreLangUtils.MessageTuple msg) {
        multipartMessages.add(msg);
        return this;
    }
    
    global void transferMessages(ControllerAction invokedAction) {
        if (this.messagesTitle != null) {
            invokedAction.setErrorTitle(this.messagesTitle, this.isMessagesTitleHtml);
        }
        if (this.useInitialMessage && al.StringUtils.isNotBlank(this.getMessage())) {
            invokedAction.addError(this.getMessage());
        }
        if (multipartMessages.size() > 0) {
            for (Object msg: this.multipartMessages) {
                if (msg instanceof String) {
                    invokedAction.addError((String) msg);
                } else if (msg instanceof CoreLangUtils.MessageTuple) {
                    invokedAction.addError((CoreLangUtils.MessageTuple) msg);
                } else {
                    invokedAction.addError(String.valueOf(msg));
                }
            }
        }
    }
}