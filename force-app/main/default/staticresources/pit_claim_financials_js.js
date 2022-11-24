/****************************************************************
                        Added to RK base RMIS product as 03/25/2013        
*******************************************************************/
/*
 * Mike Ulveling
 *
 * jquery-ui datepicker and dialog (for instant date-error alerts) functionality, as well as blocking feedback for the refresh action
 */

var rk_pit = {
    
    save: function () {
        var val = $('#PIT-date').val(), dateVal;
        var type = $('input[name=type]:checked').val();
        var claim = $('input[name=claim]:checked').val();
        var selectedClaim = $('.claimSelect').val();
        try {
            dateVal = !val || /^\s*$/.test(val) ? null : $.datepicker.parseDate($('#PIT-format').val(), $.trim(val));
            val = dateVal == null ? null : $.datepicker.formatDate('yy-mm-dd', dateVal);
            if (dateVal > new Date()) {
                throw 'You must choose a date not in the future';
            }
            rk_pit.block('search');
            af_refreshPIT(val, type, claim, selectedClaim);
        } catch (e) { 
            $('#pit-date-error').text('' + e + ' [' + val + ']');
            $('#error-dialog').dialog("open");
        }
    },
    
    block: function (mode) {
        var $msg = $('.blockingContainer .messageContainer'),
            hideMsg = /none/i.test(mode);
        if (hideMsg) {
            $msg.addClass('none');
        } else {
            $msg.removeClass('none');
        }
        if (!mode || hideMsg) {
            mode = "load";
        }
        $('.blockingContainer').addClass("blocking").addClass(mode);
    },
    
    unblock: function() {
        $('.blockingContainer').removeClass("blocking load save search sort");
    },
    
    // fix first/last rows styles due to our 'apex:column breakBefore="true"' hacking:
    adjustRowStyles: function() {
    	var $rows;
        ($rows = $('table.rk-matrix > tbody > tr')).each(function(index, el) {
            $.fn[index == 0                ? "addClass" : "removeClass"].call($(this), "first");
            $.fn[index == $rows.size() - 1 ? "addClass" : "removeClass"].call($(this), "last");
        });
    }
    
};

$(document).ready(function () {
    $("#radio_3").prop("checked", true);
    $("#radio_4").prop("checked", true);
    $('.claimSelect').prop('disabled',true);
    //var val = $('#PIT-format').val(), dateVal;
    $('#PIT-date').datepicker({dateFormat:$('#PIT-format').val(), changeYear:true, yearRange:'c-20:c+00'});
    $('#error-dialog').dialog({modal:false, autoOpen:false, title:"Invalid Evaluation Date", width:350, dialogClass:'rkon-alert', minHeight:100, 
        show: 'fade', hide: 'fade', close:
        function () {
            rk_pit.unblock();
            $('#PIT-date').focus();
        }, open:
        function () {
            rk_pit.block('none');
        }});
});