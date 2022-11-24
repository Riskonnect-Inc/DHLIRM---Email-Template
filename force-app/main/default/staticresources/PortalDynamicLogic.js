/*
*  General Handling and Validation Functions
*/

var arrayToLowerCase = function(stringArray) {
    for(var i = 0; i < stringArray.length; i++) {
        if (typeof stringArray[i] === 'string') {
            stringArray[i] = stringArray[i].toLowerCase().trim();
        }   	
    }
    return stringArray;
};

var timeFormat24 = function (timeField){
    timeField.format('99:99')
    .hasValidValue(function() {
        var val = timeField.$input.val();
        return val === '' || rkl.portal.util.isMilitaryTime(val);
    })
    ._attachOnChange(function() {
        timeField._clearError();
        if(timeField.hasValidValue()) {
            timeField.store();
        } else {
            timeField.setErrorLabel('Invalid time format');
        }
    });
};

var maxDate = function (dateField, dateValue){
    dateField.$input.data('kendoDatePicker').max(dateValue);
    
};
var hideShow = function(srcSec, srcFields, showFun, showFields) {
    
    srcFields = arrayToLowerCase(srcFields); 
    showFields = arrayToLowerCase(showFields);
    var hideShowFunc = function() {
        var parentsVisible = true;
        $.each(srcFields, function(i, f) {
            if (typeof f === 'string') {             
                if (!srcSec.fields(f).visible()) {               
                	parentsVisible = false;
                	return false; 
                }
            } else if (!f.visible) {
                parentsVisible = false;
                return false;
            }
        })
        
        var actionField = srcFields.slice(-1)[0];
        var show;
        if (typeof actionField === 'string') {
            show = parentsVisible && showFun(srcSec.sobject().get(actionField).value());
        } else {
            show = parentsVisible && showFun(actionField.sfield.value());
        }
        
        $.each(showFields, function(i, f) {
            if (typeof f === 'string') {
            	srcSec.fields(f).visible(show);
            } else {
                f.visible(show);
            }
            
        });
    };
    $.each(srcFields, function(i, f) {
        if (typeof f === 'string') {
            srcSec.sobject().get(f).on('localChange', hideShowFunc);
        } else {
            f.sfield.on('localChange', hideShowFunc);
        }
    })
    hideShowFunc();
}
var hideShowTwoFields = function(srcSec, srcFields1, srcFields2, showFun1, showFun2, condition, showFields) {
    var allSrcFields = srcFields1.concat(srcFields2);
    var hideShowFunc = function() {
        var parentsVisibleFirstSet = true;
        var parentsVisibleSecondSet = true;
        $.each(srcFields1, function(i, f) {
            if(!srcSec.fields(f).visible() ) {
                parentsVisibleFirstSet = false;
                return false;
            }
        });
        
        $.each(srcFields2, function(i, f) {
            if(!srcSec.fields(f).visible() ) {
                parentsVisibleSecondSet = false;
                return false;
            }
        });
        if(condition === 'OR'){
            var show1 = (parentsVisibleFirstSet)&& showFun1(srcSec.sobject().get(srcFields1.slice(-1)[0]).value());
            var show2 = (parentsVisibleSecondSet) && showFun2(srcSec.sobject().get(srcFields2.slice(-1)[0]).value());
        }else if(condition === 'AND'){
            var show1 = (parentsVisibleFirstSet && parentsVisibleSecondSet)&& showFun1(srcSec.sobject().get(srcFields1.slice(-1)[0]).value());
            var show2 = (parentsVisibleFirstSet && parentsVisibleSecondSet) && showFun2(srcSec.sobject().get(srcFields2.slice(-1)[0]).value());
        }
        
        $.each(showFields, function(i, f) {
            if (condition === 'OR') {
                if (show1 === true || show2 === true) {
                    f.show();
                } else {
                    f.hide();
                }
            } else if (condition === 'AND') {
                if (show1 === true && show2 === true) {
                    f.show();
                }
                else {
                    f.hide();
                }
            }
        });
    };
    
    $.each(allSrcFields, function(i, f) {
        srcSec.sobject().get(f).on('localChange', hideShowFunc);
    });
    hideShowFunc();
};

var is = function(x) {
    return function(v) {
        if (typeof v === 'string') {  //default for strings is case insensitive
            return x.toUpperCase() === v.toUpperCase();
        } else {
            return v === x;
        }
        
    }
}

var isOneOf = function(x) {
    return function(v) {
        var valueFound = false;
        $.each(x, function(i, ix) {
            if (typeof v === 'string' & typeof ix === 'string') { //case insensitive
                v = v.toUpperCase();
                ix = ix.toUpperCase();
            }
            if(v === ix) {
                valueFound = true;
                return false;
            }
        })
        return valueFound;
    };
}

var isEitherOr = function(x, y) {
    var isX = is(x);
    var isY = is(y);
    return function(v) {
        return isX(v) || isY(v);
    };
}

var isNot = function(x) {
    return function(v) {
        return v !== x;
    }
}

var isAny = function(){
    return function(v){
        return v!==null && v!=="";
    }
}

var ifMultiPickIncludes = function(value) {
    return function(valueString) {
        if (!valueString) {
            return false;
        } else {
            value = value.toUpperCase();             //Case insensitive
            valueString = valueString.toUpperCase();
            return $.inArray(value, valueString.split(';')) >= 0;
        }
    };
};

var isYes = is('Yes');
var isNo = is('No');

var sectionStatus = function(sec, showFunc) {
    return function() {
        if(showFunc()) {
            if(sec.sobject().get('id').value()) return true;
            return 'disabled';
        }
        return false;
    };
};
// End General Handling and Validation section
