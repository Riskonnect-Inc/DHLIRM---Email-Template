/*
 * Mike Ulveling
 */
/****************************************************************
                        Added to RK base RMIS product as 03/25/2013
           *******************************************************************/

rkon_clmsrch = {
    initFilters: function () {
        // transfer filter elements from the inputs "bullpen" to the filter panel's designated table input-cells, in order:
        var $placeholderCells = $('table.filterElements').find('td .filterElementPlaceholder'),
            index = 0;
        $('.filterElementsBullpen').children('.filterElement').each(
            function () {
                $($placeholderCells.get(index)).append(this);
                return ++index < $placeholderCells.size();
            });
        //console.log('Transferred: ' + index + ' inputs');
        // initialize all date-range filters:
        $('.dateRangeContainer').rkonDateRange('init');
        var $hideShowLink = $('#hideShowCriteria');
        rkon_clmsrch.toggleFilters($hideShowLink[0], true);
        $hideShowLink.click(
            function () {
                rkon_clmsrch.toggleFilters($hideShowLink[0]);
            });
    },
    
    toggleFilters: function (el, bypassAnim) {
        var $el = $(el),
            data = $el.data('rkon_clmsrch.toggleFiltersState'),
            isInit = !data,
            animMethod;
        if (!data) {
            data = {
                shown: false // when called at initialization, we want to transition INTO the "shown" state
            };
            $el.data('rkon_clmsrch.toggleFiltersState', data);
        }
        if (data.shown) {
            animMethod = 'slideUp';
            $el.text('» Show Criteria');
        } else {
            animMethod = 'slideDown';
            $el.text('» Hide Criteria');
        }
        data.shown = !data.shown;
        if (!bypassAnim) {
            $.fn[animMethod].call($('.rkon-clmsrch-criteria, .pbBottomButtons'), 'slow');
        }
    }
};

// super-simple jQuery plugin for managing the date-range filter elements (e.g. loss-date):
(function ($) {
    $.rkonDateRange = {
        dataName: 'rkonDateRange',
        $instances: $(),
        animSpeed: 'slow'
    }
    
    var methods = {
            // To be called on the collection of date-range filter container elements - i.e. each of the 3 inputs element should be findable within 
            // this container, without ambiguities:
            init: function () {
                $.rkonDateRange.$instances = $.rkonDateRange.$instances.add(this);
                return this.each(function () {
                        var $this = $(this),
                            data = {
                                $container: $this.filter('.dateRangeContainer').add($this.find('.dateRangeContainer')).first(),
                                $rangeType: $this.find('select').first(),
                                $range: $this.find('.dateRangeInputs')
                            };
                        
                        // kill SFDC's crappy horrendous/stupid/crappy/broken/kludgy datepickers and substitute new inputs with jquery-ui's nice datepicker:
                        var $newDateInputs = $(), 
                            $formatTag = data.$container.find('*[jquiDatepickerFormat][jquiDatepickerYearRange]'),
                            dateFormat = $formatTag.attr('jquiDatepickerFormat'),
                            yearRange = $formatTag.attr('jquiDatepickerYearRange');
                        dateFormat = dateFormat ? dateFormat : 'mm/dd/yy';
                        yearRange = yearRange ? yearRange : 'c-10:c+10';
                        data.$container.find('.dateInput').each(
                            function () {
                                var $oldInput = $(this).find('input:not([type=hidden])'),
                                    $newInput;
                                $oldInput.add($(this).find('.dateFormat')).remove();
                                $newInput = $('<input type="text" />').attr('name', $oldInput.attr('name')).attr('id', $oldInput.attr('id')).val($oldInput.val()).appendTo(this);
                                $oldInput.hasClass('error') ? $newInput.addClass('error') : null;
                                $newDateInputs = $newDateInputs.add($newInput);
                            });
                        data.$beginDate = $($newDateInputs.get(0));
                        data.$endDate = $($newDateInputs.get(1));
                        $newDateInputs.datepicker({dateFormat:dateFormat, changeYear:true, yearRange:yearRange});
                        
                        $this.data($.rkonDateRange.dataName, data);
                        data.$rangeType.change(function () {
                            $this.rkonDateRange('refresh', true);
                        });
                        // the apex:inputField error messages are block-level and will ruin our layout - so, we remove them and relocate the 
                        // first message (they're all going to say "Invalid Date") to within an outer container, where it won't ruin the 
                        // flow of our layout:
                        data.$range.find('div.errorMsg').detach().first().appendTo(data.$container);
                    }).
                    rkonDateRange('refresh', false);
            },
            
            refresh: function (animate) {
                return this.each(function () {
                        var fadeSpeed = 'slow',
                            data = $(this).data($.rkonDateRange.dataName),
                            rangeType = data.$rangeType.val(),
                            $range = data.$range,
                            isCustomRange = /^Custom_Range$/i.test(rangeType);
                        $range[isCustomRange ? 'show' : 'hide'].apply($range, animate ? [fadeSpeed] : []);
                        if (!isCustomRange) {
                            // remove any lingering apex:inputField error messages and error styles:
                            var errorBlocks = data.$container.find('div.errorMsg'),
                                errorStyleds = data.$range.find(':input:visible.error'),
                                cleanup = function () {
                                    errorBlocks.remove();
                                    errorStyleds.removeClass('error');
                                };
                            if (animate) {
                                errorBlocks.fadeOut(fadeSpeed, cleanup);
                            } else {
                                cleanup();
                            }
                        }
                    });
            },
            
            beforeSave: function (animate) {
                return this.each(function () {
                        var data = $(this).data($.rkonDateRange.dataName),
                            rangeType = data.$rangeType.val();
                        if (!/^Custom_Range$/i.test(rangeType)) {
                            // clear out the date inputs if the rangeType is NOT 'Custom_Range':
                            data.$range.find(':input').val('');
                        }
                    });
            }
        };
    $.fn.rkonDateRange = function (method) {
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            return methods.init.apply(this, arguments);
        } else {
            $.error('Method-name [' + method + '] is undefined for jQuery.rkonDateRange');
        }
    };
})(jQuery);
