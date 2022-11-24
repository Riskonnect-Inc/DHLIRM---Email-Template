/*
 * Mike Ulveling
 */

var rkon_me = {
    availableListContainerSel: '#available-fields',
    availableListSel: '#available-fields ol',
    activatedListContainerSel: '#activated-fields',
    activatedListSel: '#activated-fields ol',
    flashFxColor: 'rgb(255,238,170)', 
    initialized: false,
    
    initLists: function () {
        $(rkon_me.availableListSel).selectable({filter: 'li'});
        $(rkon_me.activatedListSel).sortable({items: 'li', containment: 'parent', distance: 3}).disableSelection();
        // this.initialActivatedFields should be a map of activated-fieldName to iits order (as an integer):
        var initFields = this.initialActivatedFields ? this.initialActivatedFields : {},
            availItems = $(rkon_me.availableListSel).children('li');
        availItems.each(
            function () {
                // activate the initial selections:
                if (initFields[$(this).attr('fieldName')]) {
                    $(this).addClass('rkon-me-activated');
                }
            }).sort(
                function (el1, el2) {
                    var f1 = $(el1).attr("fieldLabel").toLowerCase(),
                        f2 = $(el2).attr("fieldLabel").toLowerCase();
                    return f1 === f2 ? 0 : (f1 > f2 ? 1 : -1);
                }).detach().appendTo(rkon_me.availableListSel);
        this.refreshActivatedList({flashFx:false});
        // finally, sort the initial activated selections according to their order:
        $(rkon_me.activatedListSel).children('li').sort(
            function (li1, li2) {
                var o1 = initFields[$(li1).attr("fieldName")].order,
                    o2 = initFields[$(li2).attr("fieldName")].order;
                return o1 === o2 ? 0 : (o1 > o2 ? 1 : -1);
            }).detach().appendTo(rkon_me.activatedListSel);
        
        $(rkon_me.activatedListSel).on('click', '.ui-icon-circle-close',
            function () {
                var $li = $(this).closest('li'),
                    fieldName = $li.attr('fieldName');
                $li.fadeOut(500, 
                    function () {
                        var $availItem = $(rkon_me.availableListSel).children('li[fieldName=' + fieldName + ']'),
                            oldBg;
                        $availItem.removeClass('rkon-me-activated')._flashFx();
                        rkon_me.refreshActivatedList();
                    });
            });
        this.initialized = true;
    },
    
    // call this on a jQuery set:
    _flashFx: function () {
        return this.each(
            function () {
                var $this = $(this),
                    data = $this.data('rkon-me-flash');
                
                $this.addClass('rkon-flash-fx').delay(0).switchClass('rkon-flash-fx', '', 1500);
                $this.find('.rkon-me-fieldName').addClass('rkon-flash-fx').delay(0).switchClass('rkon-flash-fx', '', 1500);
                /*
                if (!data) {
                    data = {oldBg: $this.css('background-color')};
                    $this.data('rkon-me-flash', data);
                }
                $this.css('background-color', rkon_me.flashFxColor).delay(1000).animate({backgroundColor: data.oldBg}, 1000, 
                    function () {
                        this.style.removeProperty ? this.style.removeProperty('background-color') : 
                                (this.style.removeAttribute ? this.style.removeAttribute('backgroundColor') : null);
                    });
                    */
            });
    },
    
    refreshActivatedList: function (options) {
        // first, build a map fieldName to $(<li>) for all items currently in the activated list:
        var prevActiveFields = {},
            $activeList = $(rkon_me.activatedListSel),
            opts = $.extend({flashFx:true}, options);
        $activeList.children('li').each(
            function () {
                var $activeItem = $(this);
                prevActiveFields[$activeItem.attr('fieldName')] = $activeItem;
            });
        $(rkon_me.availableListSel).children('li').each(
            function () {
                var $availItem = $(this),
                    fieldName = $availItem.attr('fieldName'),
                    fieldLabel = $availItem.attr('fieldLabel'),
                    nowActive = $availItem.hasClass('rkon-me-activated'),
                    $prevActiveItem = prevActiveFields[$availItem.attr('fieldName')],
                    $newItem;
                if (nowActive && !$prevActiveItem) {
                    $newItem = $('<li/>').attr('fieldName', fieldName).
                        append($('<div/>').
                            append($('<span/>').addClass('ui-icon ui-icon-arrowthick-2-n-s')).
                            append($('<span/>').addClass('ui-icon ui-icon-circle-close')).
                            append($('<span/>').addClass('rkon-me-fieldLabel').text(fieldLabel)).
                            append($('<span/>').addClass('rkon-me-fieldName').text('[' + fieldName + ']'))).
                        appendTo($activeList);
                    opts.flashFx ? $newItem._flashFx() : null;
                } else if (!nowActive && $prevActiveItem) {
                    $prevActiveItem.remove();
                }
            });
    },
    
    addSelections: function () {
        $(rkon_me.availableListSel).children('li.ui-selected').each(
            function () {
                //$li = $(this);
                $(this).addClass('rkon-me-activated').removeClass('ui-selected');
            });
        rkon_me.refreshActivatedList();
    },
    
    getState: function () {
        // map of fieldName to a column-details object:
        var state = {},
            index = 0;
        $(rkon_me.activatedListSel).children('li').each(
            function () {
                var $li = $(this);
                state[$li.attr('fieldName')] = {
                        order: ++index
                    };
            });
        return state;
    },
    
    submit: function (submitFunc) {
        submitFunc(JSON.stringify(rkon_me.getState()));
    }
};

$(document).ready(
    function () {
        $.fn._flashFx = rkon_me._flashFx;
        rkon_me.initLists();
    });
