/****************************************************************
                        Added to RK base RMIS product as 06/11/2015       
*******************************************************************/
var addMessageListener = function(listener) {
    if (window.addEventListener) {
        window.addEventListener("message", listener);
    } else {
        window.attachEvent("onmessage", listener);
    }
};

var removeMessageListener = function(listener) {
    if (window.removeEventListener) {
        window.removeEventListener("message", listener);
    } else {
        window.detachEvent("onmessage", listener);
    }
};

addMessageListener(function(messageEvent) {
    if (messageEvent && messageEvent.data === "REFRESH PAGE NOW") {
        window.location.reload();
    }
});