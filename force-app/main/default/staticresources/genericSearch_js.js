//$('.dialogBoxes ... are used to close dialog boxes that I've created.


//if possible, you should do $root.find("selector")
//another thing is to not use for loops in favor of arr.forEach or $.each(arr
/****************************************************************
                        Added to RK base RMIS product as 03/25/2013    
     *******************************************************************/
;(function($) {
    "use strict";

    if(!window.rkl) {
        window.rkl = {};
    }
    if(!window.rkl.debug){
        window.rkl.debug = {
            logging : false,
            log : function(){
                if(this.logging && console && console.log){
                    console.log(arguments);
                }
            }
        };
    }
    if(!window.rkl.genericSearchs) {
        window.rkl.genericSearchs = {};
        $('<style>')
            .prop('type', 'text/css')
            .html("\
            .tooltip_UI {\
                border: 1px solid #888 !important;\
                background: #E2EEF7 !important;\
                font-family: inherit !important;\
                font-size: inherit !important;\
                padding: 2px !important;\
                padding-left: 4px !important;\
                padding-right: 4px !important;\
            }\
            .sfStyle.iu-dialog {\
                border: 1px solid #dddddd;\
                background: #f0f1f2;\
                color: #362b36;\
                font-family: ProximaNovaSoft-Regular,Calibri,'Gill Sans','Gill Sans MT',Candara,Segoe,'Segoe UI',Arial,sans-serif;\
            }\
            .sfStyle .ui-dialog-titlebar {\
                border: 0px;\
                background: #344a5f;\
                color: #ffffff;\
                font-weight: bold;\
                font-family: ProximaNovaSoft-Regular,Calibri,'Gill Sans','Gill Sans MT',Candara,Segoe,'Segoe UI',Arial,sans-serif;\
            }\
            .sfStyle .ui-dialog-title {\
                font-family: ProximaNovaSoft-Regular,Calibri,'Gill Sans','Gill Sans MT',Candara,Segoe,'Segoe UI',Arial,sans-serif;\
            }\
            .sfStyle .ui-button.ui-widget.ui-state-default.ui-corner-all.ui-button-icon-only.ui-dialog-titlebar-close {\
                border: 1px solid #2a94d6;\
                background: #fff;\
                font-weight: bold;\
                color: #000;\
            }\
            .sfStyle .ui-dialog-content {\
                border: 1px solid #dddddd;\
                background: #f0f1f2;\
                color: #362b36;\
                font-family: ProximaNovaSoft-Regular,Calibri,'Gill Sans','Gill Sans MT',Candara,Segoe,'Segoe UI',Arial,sans-serif;\
            }\
            ")
            .appendTo('head');
    }

    rkl.createGenericSearch = function(cntlData, depth, selectedCallBack){
        var genericSearch = {
            dialogDepth : depth,
            selectedCallBack : selectedCallBack,
            controllerData : cntlData,
            useORexclude : true,
            checkedMap : {},
            remoteActionDescribeInfo : {
                resultFields : {},
                lookupInfo : {},
                resultFieldOrder : [],
            },
            total : 0,
            offset : 0,
            pageSize : parseInt(cntlData.recordAmount),
            selectType : cntlData.selectType,
            $parentContainer : '',
            $resultsHeaders : '',
            $resultsData : '',
            $pagerTop : '',
            $pagerBtm : '',
            $searchDiv : '',
            $pageSizer : '',
            $errorMessage : '',

            buildSearch : function($parent){
                this.$parentContainer = $parent;
                this.buildSearchDom($parent);
                this.buildQueryArea(this.$searchDiv);
                this.buildPageSizer(this.$pageSizer);
                this.buildResultHeaders(this.$resultsHeaders,this.selectType);
                this.doSearch();
                return $parent;
            },
            buildSearchDom : function($parent){
                $parent
                    .addClass('bootstrap-sf1')
                    .css('padding','20px');
                var $sf1Wrapper = $('<div/>').addClass('panel panel-primary');
                var that = this;
                var parentApi = this.controllerData.objectApi;
                var $instDiv = $('<div id="'+parentApi+'_instructions" class="panel-heading"> </div>')
                    .html(this.controllerData.objectLabel);

                var $bodyDiv = $('<div/>')
                    .css('margin-left','10px')
                    .css('margin-right','10px');
                this.$searchDiv = $('<div id="'+parentApi+'_searchTable" class="panel-body"> </div>');

                var $searchButton = $('<a id="'+parentApi+'_searchButton" href="#" > </a>')
                    .addClass('btn btn-primary')
                    .css('color','#ffffff')
                    .click(function(){
                        that.$parentContainer.find('.selectSingleRecord.'+parentApi).hide();
                        that.checkedMap = {};
                        that.useORexclude = true;
                        that.updateToOffset(0)
                    })
                    .css('margin','5px')
                    .text('Search');
                var $selectButton = $('<a id="'+parentApi+'_selectButton" href="#" > </a>')
                    .addClass('btn btn-primary '+parentApi+' selectSingleRecord')
                    .css('color','#ffffff')
                    .click(function(){
                        var resultFields = that.remoteActionDescribeInfo.resultFields;
                        var objectApi = that.controllerData.objectApi;
                        var queryFilters = that.fetchSelectedRecordQueryInfo();//need to do something with this.
                        rkl.debug.log(resultFields);
                        rkl.debug.log(objectApi);
                        rkl.debug.log(queryFilters);
                        rkl.debug.log(0);
                        rkl.debug.log(1);
                        GenericSearch.getRecords(
                            resultFields,//that.selectedCallBack.fields,
                            [],
                            objectApi,
                            queryFilters,
                            0, 
                            1, 
                            function(resp) {
                                if(resp) {
                                    that.selectedCallBack.fun(resp, that.controllerData.resultFields);
                                }
                            },
                            {buffer: false, escape: true, timeout: 5000}
                        );
                        rkl.debug.log(that.checkedMap,'gs');
                    })
                    .css('margin','5px')
                    .text('Select')
                    .hide();

                var $upToHide =  $('<span class="glyphicon glyphicon-chevron-up"></span>')
                var $downToShow =  $('<span class="glyphicon glyphicon-chevron-down"></span>')
                var hideORshow = true;
                var $showHideButton = $('<button/>')
                    .addClass('btn btn-default btn-xs')
                    .append($upToHide)
                    .css('position','relative')
                    .css('top','7px')
                    .css('color','#AAA')
                    .click(function(){
                        hideORshow = !hideORshow;
                        $showHideButton.empty();
                        if(hideORshow){
                            that.$searchDiv.show();
                            $showHideButton.append($upToHide);
                        } else{
                            that.$searchDiv.hide();
                            $showHideButton.append($downToShow);
                        }
                        $showHideButton.blur();
                    })
                //glyphicon glyphicon-chevron-up
                var $queryHider = $('<div id="queryHider" class="text-center"> </div>')
                    .css('border-bottom','2px solid #888')
                    .css('margin-bottom','15px')
                    .append($showHideButton)

                var $buttonDiv = $('<div id="'+parentApi+'_buttons"> </div>')
                    .addClass('text-center')
                    .append($searchButton)
                    .append($selectButton);

                this.$pagerTop = $('<ul id="'+parentApi+'_pagerTop"> </ul>')
                    .addClass('pagination pagination-sm');

                this.$resultsHeaders = $('<thead id="'+parentApi+'_tblHead"> </thead>');
                this.$resultsData = $('<tbody id="'+parentApi+'_tblBody"> </tbody>');
                var $resultTable = $('<table id="'+parentApi+'_resultTable "> </table>')
                    .addClass('table table-striped');

                this.$pageSizer = $('<div id="'+parentApi+'_pageSizer"> </div>');

                this.$pagerBtm = $('<ul id="'+parentApi+'_pagerBtm"> </ul>')
                    .addClass('pagination pagination-sm');

                this.$errorMessage = $('<div/>');

                $parent.append($sf1Wrapper
                    .append($instDiv)
                    .append($bodyDiv
                        .append(this.$searchDiv)
                        .append($queryHider)
                        .append($buttonDiv)
                        .append(this.$pagerTop)
                        .append($resultTable
                            .append(this.$resultsHeaders)
                            .append(this.$resultsData)
                        )
                        .append(this.$pageSizer)
                        .append(this.$pagerBtm)
                        .append(this.$errorMessage)
                    )
                )

                return $parent;
            },
            buildPageSizer : function($parent){
                var gs = this;
                var buildSpecialRow = function (input){
                    var $selectedRow = $('<tr/>')
                    .append($('<td/>')
                        .css('background-color', '#f9f9f9')
                        .css('padding', '.1em')
                        .html('Display'))
                    .append($('<td/>')
                        .css('background-color', '#f9f9f9')
                        .css('padding', '.1em')
                        .css('text-align', 'center')
                        .html('<b>'+input+'</b>'))
                    .append($('<td/>')
                        .css('background-color', '#f9f9f9')
                        .css('padding', '.1em')
                        .html('records per page'))
                    return $selectedRow;
                };
                var buildNormalRow = function (input){
                    var $selectedRow = $('<tr/>')
                    .append($('<td/>'))
                    .append($('<td/>')
                        .css('background-color', 'white')
                        .css('color','#428bca')
                        .css('padding', '.1em')
                        .css('padding-left', '.5em')
                        .css('padding-right', '.5em')
                        .css('margin-left','3.27em')
                        .css('text-align', 'center')
                        .html('<b>'+input+'</b>'))
                    .append($('<td/>'))
                    return $selectedRow;

                };
                var buildRecordAmount = function(){
                    var divBody = $('<table/>')
                        .addClass('dialogBoxes '+gs.dialogDepth)
                    var options = [10,25,50,100,200];
                    var optionMap = {};
                    $.each(options, function(i,v){
                        optionMap[v] = v===gs.pageSize?buildSpecialRow(v):buildNormalRow(v)
                            .click(function(){
                                gs.pageSize = v;
                                gs.updateToOffset(0);
                                $('.dialogBoxes.'+gs.dialogDepth).dialog("close");
                            })
                            divBody.append(optionMap[v]);
                    })
                    optionMap[gs.pageSize].css('color','#000000');
                    return divBody;
                };

                var buildBaseCounter = function(){
                    var that = this;
                    //var tmp = buildRecordAmount;
                    var $infoSpan = $('<span/>');
                    if(gs.total === 0){
                        return $('<div/>');
                    }
                        var pageCounter = (parseInt(gs.offset)+parseInt(gs.pageSize))
                        $infoSpan
                            .text(gs.offset+1+'-'+ (pageCounter<gs.total?pageCounter:gs.total) +' of '+(gs.total>2000?'2000+':gs.total));
                    
                        
                    var $filterIcon = $('<span class="glyphicon glyphicon-chevron-up"></span>');
                    var $dialogCaret = $('<button/>')
                        .addClass('btn btn-default btn-xs')
                        .css('margin-left','5px')
                        .click(
                            function(){
                                buildRecordAmount().dialog({
                                    title: 'Number of Records',
                                    dialogClass: "sfStyle",
                                    draggable: false,
                                    position: { my: "left bottom", at: "left top", of: $infoSpan }
                                });
                            })
                        .append($filterIcon)
                    var $divBody = $('<div/>')
                        .append($infoSpan)
                        .append($dialogCaret)

                    return $divBody;
                };
                $parent.empty();
                return $parent.append(buildBaseCounter());
            },
            buildQueryArea : function($parent){
                var gs = this;
                var buildSplitArea = function(){
                    var qFilters = gs.controllerData.queryFilters;
                    if(qFilters.length%3==0){
                        $parent
                            .append( buildSearchAreaFieldCol(qFilters.slice(0,qFilters.length/3)) )
                            .append( buildSearchAreaFieldCol(qFilters.slice(qFilters.length/3,qFilters.length/3*2)) )
                            .append( buildSearchAreaFieldCol(qFilters.slice(qFilters.length/3*2,qFilters.length)) )
                    } else if(qFilters.length%3==1){
                        $parent
                            .append( buildSearchAreaFieldCol(qFilters.slice(0,(qFilters.length-1)/3+1)) )
                            .append( buildSearchAreaFieldCol(qFilters.slice((qFilters.length-1)/3+1,(qFilters.length-1)/3*2+1)) )
                            .append( buildSearchAreaFieldCol(qFilters.slice((qFilters.length-1)/3*2+1,qFilters.length)) )
                    } else if(qFilters.length%3==2){
                        $parent
                            .append( buildSearchAreaFieldCol(qFilters.slice(0,(qFilters.length-2)/3+1)) )
                            .append( buildSearchAreaFieldCol(qFilters.slice((qFilters.length-2)/3+1,(qFilters.length-2)/3*2+2)) )
                            .append( buildSearchAreaFieldCol(qFilters.slice((qFilters.length-2)/3*2+2,qFilters.length)) )
                    }
                };
                var buildSearchAreaFieldCol = function(input){
                    var $col = $('<div/>')
                        .css('width','400px')
                        .css('display','inline-block')
                        .css('vertical-align','top');
                    $.each(input,function(index,item){
                        var $row = $('<div>')
                            .append( buildQueryField(item) )
                            .appendTo($col)
                    })
                    return $col;
                };



                var buildQueryField = function(field){
                    if(field){
                        //this.remoteActionDescribeInfo.queryFields.push(field.fieldApi);
                        if(field.fieldType==='Boolean'){
                            return buildCheckBox(field.fieldLabel, field.fieldApi);
                        }
                        if(field.fieldType==='Combobox' || field.fieldType==='Picklist'){
                            return buildPickList(field.fieldLabel, field.fieldApi, field.picklistValues);
                        }
                        if(field.fieldType==='MultiPicklist'){
                            return buildMultiPick(field.fieldLabel, field.fieldApi, field.picklistValues);
                        }
                        if(field.fieldType==='Currency' || field.fieldType==='Double' || field.fieldType==='Integer' || field.fieldType==='Percent'){
                            return buildNumberBox(field.fieldLabel, field.fieldApi);
                        }
                        if(field.fieldType==='Date' || field.fieldType==='DateTime'){
                            return buildDateBox(field.fieldLabel, field.fieldApi);
                        }
                        if(field.fieldType==='Email' || field.fieldType==='Phone' || field.fieldType==='String' || field.fieldType==='TextArea' || field.fieldType==='URL'){
                            return buildTextInputBox(field.fieldLabel, field.fieldApi);
                        }
                        if(field.fieldType==='Reference'){
                            return buildLookupBox(field.fieldLabel, field.fieldApi);
                        }
                    }
                    
                    'DataCategoryGroupReference'
                    'EncryptedString'
                    'ID'
                    'Time'
                    return null;
                };
                var buildCheckOption = function(label, value, hiddenOperator){
                    var selectBlock = {};
                    selectBlock['$block'] = $('<div/>');
                    selectBlock['$checkBox'] = $('<input type="checkbox" name="'+label+'"class="'+hiddenOperator+'"></input>');
                    selectBlock['$label'] = $('<span style="padding-left: 10px">'+value+'<span>');
                    selectBlock['$block'].append(selectBlock['$checkBox']).append(selectBlock['$label']);
                    return selectBlock;
                };
                var buildRadioOption = function(label, value, hiddenOperator, LoadcheckedStatus){
                    var selectBlock = {};
                    selectBlock['$block'] = $('<div/>');
                    selectBlock['$checkBox'] = $('<input type="radio" name="'+label+'" class="'+hiddenOperator+'"></input>');
                    if(LoadcheckedStatus==true){
                        selectBlock['$checkBox'].prop('checked', true);
                    }
                    selectBlock['$label'] = $('<span style="padding-left: 10px">'+value+'<span>');
                    selectBlock['$block'].append(selectBlock['$checkBox']).append(selectBlock['$label']);
                    return selectBlock;
                };
                var buildOperatorWindow = function(input, label, goButtonLabel){
                    var info = {'options': input};
                    info['$dialogBox'] = $('<div/>').attr('title',label).addClass('dialogBoxes '+gs.dialogDepth);
                    var keys = Object.keys(input);
                    $.each(keys,function(index,item){
                        info['$dialogBox'].append(input[item]['$block'])
                    })
                    info['$goButton'] = $('<button/>')
                        .text(goButtonLabel)
                        .css('margin-top','20px')
                        .css('font-family','ProximaNovaSoft-Regular,Calibri,"Gill Sans","Gill Sans MT",Candara,Segoe,"Segoe UI",Arial,sans-serif')
                        .addClass('btn btn-default')
                    info['$dialogBox'].append(info['$goButton']);
                    return info;
                };
                var buildMultiSelectOperatorWindow = function(label){
                    var optionBoxes = {
                        'type':'date',
                        'Equal To' : buildRadioOption(label, 'Equal To','Equal_To',true),
                        'Not Equal To' : buildRadioOption(label, 'Not Equal To','Not_Equal_To'),
                        'Includes' : buildRadioOption(label, 'Includes','Includes'),
                        'Excludes' : buildRadioOption(label, 'Excludes','Excludes')
                    }
                    return buildOperatorWindow(optionBoxes, 'Operator', 'Apply')
                };
                var buildDateOperatorWindow = function(label){
                    var optionBoxes = {
                        'type':'date',
                        'Equal To' : buildRadioOption(label, 'Equal To','Equal_To',true),
                        'Greater Than' : buildRadioOption(label, 'Greater Than','Greater_Than'),
                        'Less Than' : buildRadioOption(label, 'Less Than','Less_Than'),
                        'Not Equal To' : buildRadioOption(label, 'Not Equal To','Not_Equal_To'),
                        'Greater or Equal' : buildRadioOption(label, 'Greater or Equal','Greater_Or_Equal'),
                        'Less or Equal' : buildRadioOption(label, 'Less or Equal','Less_Or_Equal'),
                        'Between' : buildRadioOption(label, 'Between','Between')
                    }
                    return buildOperatorWindow(optionBoxes, 'Operator', 'Apply')
                };
                var buildNumberOperatorWindow = function(label){
                    var optionBoxes = {
                        'Equal To' : buildRadioOption(label, 'Equal To','Equal_To',true),
                        'Greater Than' : buildRadioOption(label, 'Greater Than','Greater_Than'),
                        'Less Than' : buildRadioOption(label, 'Less Than','Less_Than'),
                        'Not Equal To' : buildRadioOption(label, 'Not Equal To','Not_Equal_To'),
                        'Greater or Equal' : buildRadioOption(label, 'Greater or Equal','Greater_Or_Equal'),
                        'Less or Equal' : buildRadioOption(label, 'Less or Equal','Less_Or_Equal')
                    }
                    return buildOperatorWindow(optionBoxes, 'Operator', 'Apply')
                };
                var buildTextOperatorWindow = function(label){
                    var optionBoxes = {
                        'Equal To' : buildRadioOption(label, 'Equal To','Equal_To',true),
                        'Not Equal To' : buildRadioOption(label, 'Not Equal To','Not_Equal_To'),
                        'Contains' : buildRadioOption(label, 'Contains','Contains'),
                        'Not Contains' : buildRadioOption(label, 'Not Contains','Not_Contains'),
                        'Starts With' : buildRadioOption(label, 'Starts With','Starts_With'),
                        'Ends With' : buildRadioOption(label, 'Ends With','Ends_With')
                    }
                    return buildOperatorWindow(optionBoxes, 'Operator', 'Apply')
                };
                var buildPicklistWindow = function(label, values){
                    var optionBoxes = {'type':'single'};
                    $.each(values,function(index,item){
                        optionBoxes[item] = buildRadioOption(label,item,item);
                    })
                    return buildOperatorWindow(optionBoxes, label, 'Insert Selected')
                };
                var buildMultiPicklistWindow = function(label, values){
                    var optionBoxes = {'type':'multi'};
                    $.each(values,function(index,item){
                        optionBoxes[item] = buildCheckOption(label,item,item);
                    })
                    return buildOperatorWindow(optionBoxes, label, 'Insert Selected')
                };
                var buildLookupPostSelectWindow = function(info){
                    info['$reviewDialogBox'].empty();
                    var $removeAllButton = $('<a href="#" > </a>')
                    .addClass('btn btn-primary')
                    .css('color','#ffffff')
                    .css('margin','5px')
                    .click(function(){
                        info.selectedStorage = {};
                        info['$reviewDialogBox'].dialog('close');
                    })
                    .text('Remove All');
                    //info['$reviewDialogBox'].append($removeAllButton);
                    var $resultTable = $('<table> </table>')
                        .addClass('table table-striped')
                        .appendTo(info['$reviewDialogBox']);
                    var $resultsHeaders = $('<thead> </thead>').appendTo($resultTable);
                    var $resultsData = $('<tbody> </tbody>').appendTo($resultTable);

                    $resultsHeaders.append($removeAllButton);
                    $.each(info.cgs.controllerData.resultFields,function(index, item){
                        var $col = $('<th/>')
                            .text(item.fieldLabel);
                        $resultsHeaders.append($col);
                    });
                    $.each(Object.keys(info.selectedStorage),function(index, item){
                        var $row = $('<tr/>')
                        $resultsData.append($row);
                        var $delCell = $('<a href="#" > </a>')
                            .addClass('btn btn-primary')
                            .css('color','#ffffff')
                            .css('margin','5px')
                            .click(function(){
                                delete info.selectedStorage[item];
                                $row.hide();
                            })
                            .append($('<span class="glyphicon glyphicon-remove"></span>'))
                        $row.append($('<td/>').append($delCell));
                        $.each(info.cgs.controllerData.resultFields,function(index2, item2){
                            var $cell = $('<td/>')
                                .text(info.selectedStorage[item][item2.fieldApi]);
                            $row.append($cell);
                        });
                    });

                    console.log(info);

                    
                };
                var buildLookupWindow = function(label, api){

                    var info = {};
                    
                    info['$dialogBox'] = $('<div/>').attr('title',label+' Lookup').addClass('lookupDialog dialogBoxes '+gs.dialogDepth);
                    info['selectedStorage'] = {};
                    info['$reviewDialogBox'] = $('<div/>').attr('title','Selected '+label).addClass('reviewDialog dialogBoxes '+gs.dialogDepth);
                    info['$blocker'] = $('<div/>').addClass('ui-widget-overlay ui-front initLoadScreen');
                    
                    var lookupInfo = {};
                    lookupInfo.fun = function(result, firstField){
                                    rkl.debug.log('res',result);

                                    if(result.records.length===1){
                                        if(!info['selectedStorage'][result.records[0]['Id']]){
                                            info['selectedStorage'][result.records[0]['Id']]=result.records[0];
                                            var firstVals = firstField[0].fieldApi;
                                            info['selectedStorage'][result.records[0]['Id']].namedKeyGS = firstVals;
                                            rkl.debug.log(firstVals);
                                            var existingVal = gs.$parentContainer.find('.'+api+'.'+gs.controllerData.objectApi+'.from').val();
                                            if(existingVal.trim()==''){
                                                gs.$parentContainer.find('.'+api+'.'+gs.controllerData.objectApi+'.from').val(result.records[0][firstVals]);
                                            } else{
                                                gs.$parentContainer.find('.'+api+'.'+gs.controllerData.objectApi+'.from').val(existingVal+', '+result.records[0][firstVals]);
                                            }
                                            info['cgs'].useORexclude = true;
                                            info['cgs'].checkedMap = {};
                                            info['cgs'].$resultsData.find('input').prop('checked',false);
                                            info['cgs'].$parentContainer.find('.selectSingleRecord').hide();
                                            info['$dialogBox'].dialog('close');
                                            info['$blocker'].detach();
                                        } else{
                                            alert('This record has already been selected.');//BANANA Need to come back here and make a proper dialog.
                                        }
                                    } else{
                                        rkl.debug.log('Something weird happened with grabbing your record.');
                                    }
                                }
                    info['cgs'] = rkl.createGenericSearch(
                            gs.controllerData.childLookups[api],
                            (gs.dialogDepth+1),
                            lookupInfo);
                    info['cgs'].buildSearch(info['$dialogBox']);
                    return info;
                };
                var buildBaseBox = function(input){
                    var $block = $('<span/>');
                    var $label = $('<label/>')
                        .addClass('control-label')
                        .css('display','block')
                        .css('margin-top','5px').css('margin-bottom','2px')
                        .text(input.label)
                        .appendTo($block);

                    var $input = $('<input type="text" class="'+input.styleClass+' '+gs.controllerData.objectApi+' from" />');
                    if(input.type && input.type=='date'){
                        $input.datepicker({
                            appendText: '(' + 'mm/dd/yy' + ')',
                        });
                    } else if(input.type && input.type==='numbers'){
                        $input.keydown(function(e){
                            //stackoverflow - http://stackoverflow.com/questions/469357/html-text-input-allow-only-numeric-input
                            // Allow: backspace, delete, tab, escape, enter and .
                            if ($.inArray(e.keyCode, [46, 8, 9, 27, 13, 110, 190]) !== -1 ||
                                 // Allow: Ctrl+A
                                (e.keyCode == 65 && (e.ctrlKey || e.metaKey) === true) ||
                                 // Allow: Ctrl+C
                                (e.keyCode == 67 && (e.ctrlKey || e.metaKey) === true) ||
                                 // Allow: Ctrl+X
                                (e.keyCode == 88 && (e.ctrlKey || e.metaKey) === true) ||
                                 // Allow: home, end, left, right
                                (e.keyCode >= 35 && e.keyCode <= 39)) {
                                     // let it happen, don't do anything
                                     return;
                            }
                            // Ensure that it is a number and stop the keypress
                            if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105)) {
                                e.preventDefault();
                            }
                        });
                    } else if(input.type && input.type==='lookup'){
                        $input.keydown(function(e){
                            if ($.inArray(e.keyCode, [9, 27, 13, 110]) !== -1 ||
                                (e.keyCode == 65 && (e.ctrlKey || e.metaKey) === true) ||
                                (e.keyCode == 88 && (e.ctrlKey || e.metaKey) === true) ||
                                (e.keyCode >= 35 && e.keyCode <= 39)){
                                     return;
                            } /*else if($.inArray(e.keyCode, [46, 8]) !== -1){
                                $(e.currentTarget).val('');
                                input.lookupBox['cgs'].checkedMap = {};
                                input.lookupBox['cgs'].useORexclude = true;
                                input.lookupBox['cgs'].updateToOffset(0);
                            } */else{
                                e.preventDefault();
                            }
                        });
                    } else if(input.type && input.type==='checkbox'){
                        $input.keydown(function(e){
                            if ($.inArray(e.keyCode, [9, 27, 13, 110]) !== -1 ||
                                (e.keyCode == 65 && (e.ctrlKey || e.metaKey) === true) ||
                                (e.keyCode == 88 && (e.ctrlKey || e.metaKey) === true) ||
                                (e.keyCode >= 35 && e.keyCode <= 39)){
                                     return;
                            } else if($.inArray(e.keyCode, [46, 8]) !== -1){
                                $(e.currentTarget).val('');
                            } else{
                                e.preventDefault();
                            }
                        });
                    }
                    var $mid =  $('<span class="glyphicon glyphicon-minus"></span>')
                        .css('padding-right', '2px')
                        .css('padding-left', '2px');
                    var $input2 = $('<input type="text" class="'+input.styleClass+' '+gs.controllerData.objectApi+' to" />')
                        .datepicker({
                            appendText: '(' + 'mm/dd/yy' + ')',
                        });
                    if(input.filterBox){
                        var $filterIcon = $('<span class="glyphicon glyphicon-filter"></span>')
                        var saveFunction = function(){
                            var checkedVal = $('input:radio[name="'+input.label+'"]').filter(":checked").attr('class');
                            $filterButton.tooltip({
                                content: ''+checkedVal.replace(/_/g,' '),
                                items: $filterButton,
                                tooltipClass: 'tooltip_UI',
                                position: {my: "left top+5", at:"left bottom"}
                            });
                            $filterButton.attr('name',checkedVal);
                            if(checkedVal==='Between'){
                                $block.append($mid);
                                $block.append($input2);
                            } else{
                                $mid.detach()
                                $input2.detach()
                            }
                            input.filterBox['$dialogBox'].dialog("close");
                            //Have to call blur on button to fix a weird Chrome Issue where when the Dialog
                            //  closes the buttons focus is called.
                            
                            
                        };
                        input.filterBox['$goButton'].click( saveFunction );
                        var $filterBox = input.filterBox['$dialogBox'];
                        var filterDialogOpen = false;
                        var $filterButton = $('<button/>')
                            .addClass('btn btn-default btn-sm '+gs.controllerData.objectApi+' '+input.styleClass)
                            .append($filterIcon)
                            .click(function(){
                                if(!filterDialogOpen){
                                    var openBoxed = $('.dialogBoxes.'+gs.dialogDepth).dialog("close");
                                    $filterBox.dialog({
                                        draggable: false,
                                        dialogClass: "sfStyle",
                                        close: function( event, ui ){
                                            $filterButton.blur();
                                            filterDialogOpen = false;
                                        },
                                        position: { my: "left center", at: "right center", of: $input }
                                    });
                                    filterDialogOpen = true;
                                } else{
                                    saveFunction();
                                }
                            });
                        $filterButton.tooltip({
                            content: 'Equal To',
                            items: $filterButton,
                            tooltipClass: 'tooltip_UI',
                            position: {my: "left top+5", at:"left bottom"}
                        })
                        $block.append($filterButton)
                        $input.css('margin-left', '5px');
                    } else{
                        $input.css('margin-left', '40px');//35px
                    }
                    $block.append($input);
                    if(input.pickBox){
                        var $pickIcon = $('<span class="glyphicon glyphicon-chevron-right"></span>')
                            .css('color','grey')
                        if(input.pickBox.options.type==='single'){
                            input.pickBox['$goButton'].click(function(){
                                $input.val($pickBox.find('input:radio[name="'+input.label+'"]').filter(":checked").attr('class'));
                                input.pickBox['$dialogBox'].dialog("close");
                            });
                        } else{
                            input.pickBox['$goButton'].click(function(){
                                var selected = $pickBox.find('input:checkbox[name="'+input.label+'"]').filter(":checked");
                                var fieldValue = '';
                                $.each(selected,function(index,item){
                                    fieldValue += $pickBox.find(item).attr('class')+', '
                                });
                                $input.val(fieldValue.substring(0,(fieldValue.length-2)));
                                input.pickBox['$dialogBox'].dialog("close");
                            });
                        }
                        var $pickBox = input.pickBox['$dialogBox'];
                        var $pickButton = $('<button/>')
                            .addClass('btn btn-default btn-sm')
                            .css('margin-left','5px')
                            .append($pickIcon)
                            .click(function(){
                                var openBoxed = $('.dialogBoxes.'+gs.dialogDepth).dialog("close");
                                if($input.val()===''){
                                    $pickBox.find('input:checkbox[name="'+input.label+'"]').attr('checked',false);
                                    $pickBox.find('input:radio[name="'+input.label+'"]').attr('checked',false);
                                }
                                $pickBox.dialog({
                                    draggable: false,
                                    dialogClass: "sfStyle",
                                    close: function( event, ui ){
                                        $pickButton.blur();
                                    },
                                    position: { my: "left center", at: "right center", of: $input }
                                });
                            });
                        $block.append($pickButton);
                    }
                    if(input.lookupBox){
                        //"'+input.styleClass+' '+gs.controllerData.objectApi+' from"
                        var $hiddenIDbox = input.lookupBox['$hiddenIDbox'];
                        $block.append($hiddenIDbox);
                        var $searchIcon = $('<span class="glyphicon glyphicon-search"></span>');
                        var buildReviewBox = buildLookupPostSelectWindow;
                        $input.click(function(){
                            if(Object.keys(input.lookupBox['selectedStorage']).length>0){
                                var openBoxed = $('.dialogBoxes.'+gs.dialogDepth).dialog('close');
                                var $blocker = input.lookupBox['$blocker'];
                                $('body').append($blocker);
                                var winHeight = $(window).height();
                                var winWidth = $(window).width();
                                input.lookupBox['$reviewDialogBox'].dialog({
                                    draggable: false,
                                    dialogClass: "sfStyle",
                                    height: (winHeight*.9),
                                    open : function( event,ui ) {buildReviewBox(input.lookupBox);},
                                    close: function( event, ui ) {
                                        var newVal = '';
                                        $.each(input.lookupBox['selectedStorage'],function(index,item){
                                            newVal+= ', '+item[item.namedKeyGS];
                                        });
                                        $input.val(newVal.substring(2));
                                        $blocker.remove();
                                    },
                                    width: (winWidth*.9),
                                    position: { my: "left top", at: "left+"+(winWidth*.1/2)+"px top+"+(winHeight*.1/2)+"px", of: $('body') }
                                });
                            }
                        });
                        var $searchBox = input.lookupBox['$dialogBox']
                        var $searchButton = $('<button/>')
                            .addClass('btn btn-default btn-sm')
                            .css('margin-left','5px')
                            .append($searchIcon)
                            .click(function(){
                                var openBoxed = $('.dialogBoxes.'+gs.dialogDepth).dialog('close');
                                var $blocker = input.lookupBox['$blocker'];
                                $('body').append($blocker);
                                var winHeight = $(window).height();
                                var winWidth = $(window).width();
                                $searchBox.dialog({
                                    draggable: false,
                                    dialogClass: "sfStyle",
                                    height: (winHeight*.9),
                                    open : function( event,ui ) { $searchBox.find('.btn').blur(); },
                                    close: function( event, ui ) { $searchButton.blur(); $blocker.remove();},
                                    width: (winWidth*.9),
                                    position: { my: "left top", at: "left+"+(winWidth*.1/2)+"px top+"+(winHeight*.1/2)+"px", of: $('body') }
                                });
                            });
                        $block.append($searchButton);
                    }
                    
                    return $block;
                };
                var buildTextInputBox = function(label, styleClass){
                    var filterBox = buildTextOperatorWindow(label);
                    var input = {
                        type:'text',
                        label:label,
                        styleClass:styleClass,
                        filterBox:filterBox
                    };
                    return buildBaseBox(input);
                    //return buildBaseBox(label, styleClass, filterBox);
                };
                var buildLookupBox = function(label, styleClass){
                    var lookupBox = buildLookupWindow(label,styleClass);
                    var input = {
                        type:'lookup',
                        label:label,
                        styleClass:styleClass,
                        lookupBox:lookupBox
                    };
                    gs.remoteActionDescribeInfo.lookupInfo[styleClass] = input;
                    return buildBaseBox(input);
                };
                var buildCheckBox = function(label, styleClass){
                    var pickBox = buildPicklistWindow(label, ['True','False']);
                    var input = {
                        type:'checkbox',
                        label:label,
                        styleClass:styleClass,
                        pickBox:pickBox
                    };
                    return buildBaseBox(input);
                };
                var buildPickList = function(label, styleClass, options){
                    var filterBox = buildTextOperatorWindow(label);
                    var pickBox = buildPicklistWindow(label, options);
                    var input = {
                        type:'text',
                        label:label,
                        styleClass:styleClass,
                        filterBox:filterBox,
                        pickBox:pickBox
                    };
                    return buildBaseBox(input);
                    //return buildBaseBox(label, styleClass, filterBox, pickBox);
                };
                var buildMultiPick = function(label, styleClass, options){
                    var filterBox = buildMultiSelectOperatorWindow(label);
                    var pickBox = buildMultiPicklistWindow(label, options);
                    var input = {
                        type:'text',
                        label:label,
                        styleClass:styleClass,
                        filterBox:filterBox,
                        pickBox:pickBox
                    };
                    return buildBaseBox(input);
                };
                var buildNumberBox = function(label, styleClass){
                    var filterBox = buildNumberOperatorWindow(label);
                    var input = {
                        type:'numbers',
                        label:label,
                        styleClass:styleClass,
                        filterBox:filterBox
                    };
                    return buildBaseBox(input);
                    //return buildBaseBox(label, styleClass, filterBox);
                };
                var buildDateBox = function(label, styleClass){
                    var filterBox = buildDateOperatorWindow(label);
                    var input = {
                        type:'date',
                        label:label,
                        styleClass:styleClass,
                        filterBox:filterBox
                    };
                    return buildBaseBox(input);
                    //return buildBaseBox(label, styleClass, filterBox);
                };

                return $parent.append(buildSplitArea());
            },
            buildResultHeaders : function($parent,selectable){
                var gs = this;
                var buildResultHeaderDom = function(){
                    $parent.empty();
                    if(selectable==="Multi"){
                        var selectAllCheck = false;
                        var $selectAllBox = $('<input id="selectAllBox" type="checkbox"></input>')
                            .click(function(){
                                gs.selectAll(!selectAllCheck);
                                selectAllCheck = !selectAllCheck;
                            });
                        $parent.append($('<th style="padding:8px;"></th>').append($selectAllBox));
                    }
                    if(selectable==="Single"){
                        $parent.append($('<th style="padding:8px;"></th>'));
                    }
                    var $clearFilters = $('<th style=""></th>');
                    $.each(gs.controllerData.resultFields,function(index,item){
                        $parent.append(buildResultHeader(item.fieldLabel, item.fieldApi, $clearFilters));
                        gs.remoteActionDescribeInfo.resultFields[item.fieldApi] = item.fieldType;
                    });
                    $parent.append($clearFilters);
                    return $parent;
                };

                var buildResultHeader = function(label, api, endCol){
                    var col = $('<th/>');
                    var st = $('<a>'+label+'</a>')
                        .addClass(api)
                        .attr('href','#')
                        .click(function(){
                            setDir(col, api);
                            messWithHeaders(endCol);
                            gs.updateToOffset(0);
                        });
                    col.append(st);
                    return col;
                };

                var flipDir = function(input, api){
                    if(input[api]=='ASC'){
                        input[api]='DSC'
                    } else{
                        input[api]='ASC'
                    }
                    return input;
                };

                var messWithHeaders = function(endCol){
                    var headerAPIs = Object.keys(gs.remoteActionDescribeInfo.resultFields);
                    var orderAPIs = gs.remoteActionDescribeInfo.resultFieldOrder;
                    $.each(headerAPIs,function(index,item){
                        var headerLink = $('a.'+item);
                        headerLink.children('span').remove()
                    });
                    $.each(orderAPIs,function(index,item){
                        var field = Object.keys(item);
                        var headerLink = $('a.'+field[0]);
                        var $orderIcon;
                        if(item[field[0]]=='ASC'){
                            $orderIcon = $('<span class="glyphicon glyphicon-sort-by-attributes">'+(index+1)+'</span>');
                        } else{
                            $orderIcon = $('<span class="glyphicon glyphicon-sort-by-attributes-alt">'+(index+1)+'</span>');
                        }
                        $orderIcon.css('position','relative');
                        $orderIcon.css('left','10px');
                        headerLink.append($orderIcon);
                    });
                    if(orderAPIs.length>0){
                        var $bodyDiv = $('<div title="Remove Sort"></div>')
                            .tooltip()
                            .click(function(){
                                gs.remoteActionDescribeInfo.resultFieldOrder=[];
                                messWithHeaders(endCol);
                                endCol.empty();
                                gs.updateToOffset(0);
                            });
                        var $sortIcon = $('<span class="glyphicon glyphicon-sort-by-attributes"></span>')
                            .css('font-size', '0.9em')
                            .css('position', 'relative')
                            .css('right', '5px')
                            .css('top', '-2px')
                            .css('color', '#428bca');
                        var $banIcon = $('<span class="glyphicon glyphicon-ban-circle"></span>')
                            .css('font-size', '1.25em')
                            .css('position', 'relative')
                            .css('left', '10px')
                            .css('color', 'red')
                            .css('opacity', '0.25');
                        $bodyDiv.append($banIcon).append($sortIcon);
                        endCol.empty();
                        endCol.append($bodyDiv);
                    }
                };
                var buildRemoteActionMap = function(k,v){
                    var retVal = { };
                    retVal[k] = v;
                    return retVal;
                };
                var setDir = function(col, api){
                    //limiting to 3 deep;
                    var fOrder = gs.remoteActionDescribeInfo.resultFieldOrder;
                    var newFOrder = [];
                    var placeHolder = -1;

                    $.each(fOrder,function(index,item){
                        if(item[api]){
                            placeHolder = index;
                        } else{
                            newFOrder.push(item);
                        }
                    });
                    if(placeHolder!=-1){
                        newFOrder.push(flipDir(fOrder[placeHolder],api));
                    } else{
                        if(newFOrder.length==3){
                            newFOrder.splice(0,1);
                        }
                        newFOrder.push(flipDir(buildRemoteActionMap(api,'DSC'),api));
                        
                    }
                    gs.remoteActionDescribeInfo.resultFieldOrder = newFOrder;
                };

                return buildResultHeaderDom();
            },
            selectAll : function(input){
                var resultBoxes = this.$resultsData.children().children().children('input')
                if(input===true){
                    this.checkedMap = {};
                    this.useORexclude = false;
                    resultBoxes.prop('checked',true);
                } else{
                    this.checkedMap = {};
                    this.useORexclude = true;
                    resultBoxes.prop('checked',false);
                }
            },
            checkedStatus : function(id){
                if(this.checkedMap[id]){
                    return true;
                }
                return false;
            },
            setCheckedStatus : function(id){
                if(this.checkedMap[id]){
                    delete this.checkedMap[id];
                } else{
                    this.checkedMap[id] = id;
                }
            },
            setSelectedStatus : function(id){
                this.checkedMap = {};
                this.checkedMap[id] = id;
                this.$parentContainer.find('.selectSingleRecord.'+this.controllerData.objectApi).show();
            },
            
            doSearch : function(){
                this.updateToOffset(0);
            },
            
            
            fetchQueryInfo : function(){
                var that = this;
                var queryInfo = {};
                var opMap = {
                    undefined:'',
                    '':'',
                    'Equal_To':'',
                    'Not_Equal_To':'!=',
                    'Includes':'I',
                    'Excludes':'E',
                    'Greater_Than':'>',
                    'Less_Than':'<',
                    'Greater_Or_Equal':'>=',
                    'Less_Or_Equal':'<=',
                    'Contains':'C',
                    'Not_Contains':'!C',
                    'Starts_With':'SW',
                    'Ends_With':'EW'
                };
                $.each(this.controllerData.queryFilters, function(index,item){
                    var fieldVal = that.$parentContainer.find('[type="text"].'+that.controllerData.objectApi+'.'+item.fieldApi).val();
                    if(fieldVal!='' && fieldVal!=undefined){
                        if(that.$parentContainer.find('.btn.'+that.controllerData.objectApi+'.'+item.fieldApi).attr('name')==='Between'){
                            queryInfo[item.fieldApi] = [];
                            queryInfo[item.fieldApi].push(
                                {'op':'>=',
                                'val':that.$parentContainer.find('[type="text"].'+that.controllerData.objectApi+'.from.'+item.fieldApi).val(),
                                'type':item.fieldType}
                            );
                            queryInfo[item.fieldApi].push(
                                {'op':'<=',
                                'val':that.$parentContainer.find('[type="text"].'+that.controllerData.objectApi+'.to.'+item.fieldApi).val(),
                                'type':item.fieldType}
                            );
                        } else{
                            queryInfo[item.fieldApi] = [];
                            if(item.fieldType==="Reference"){
                                var mapKeys = Object.keys(that.remoteActionDescribeInfo.lookupInfo[item.fieldApi].lookupBox.selectedStorage);
                                fieldVal = mapKeys.join();
                            }
                            queryInfo[item.fieldApi].push(
                                {'op':opMap[that.$parentContainer.find('.btn.'+that.controllerData.objectApi+'.'+item.fieldApi).attr('name')],
                                'val':fieldVal,
                                'type':item.fieldType}
                            );
                        }
                    }
                });
                $.each(this.controllerData.lockedFilters, function(index,item){
                    if(queryInfo[item.fieldApi]){
                        queryInfo[item.fieldApi].push(
                            {'op':item.fieldOp,
                            'val':item.fieldValue,
                            'type':item.fieldType}
                        );
                    } else{
                        queryInfo[item.fieldApi] = [];
                        queryInfo[item.fieldApi].push(
                            {'op':item.fieldOp,
                            'val':item.fieldValue,
                            'type':item.fieldType}
                        );
                    }
                });
                return queryInfo;
            },
            fetchSelectedRecordQueryInfo : function(){
                var key = Object.keys(this.checkedMap);
                if(key.length===1){
                    return {  'Id':[{
                            'op':'',
                            'val':this.checkedMap[key],
                            'type':'Id'
                            }] }
                }
            },
            
            
            updateToOffset : function(newOffset) {
                var resultFields = this.remoteActionDescribeInfo.resultFields;
                var resultOrders = this.remoteActionDescribeInfo.resultFieldOrder;
                var objectApi = this.controllerData.objectApi;
                var queryFilters = this.fetchQueryInfo();
                var that = this;
                that.$errorMessage.empty();
                rkl.debug.log(objectApi,resultFields,queryFilters,newOffset,this.pageSize);
                GenericSearch.getRecords(
                    resultFields,
                    resultOrders,
                    objectApi,
                    queryFilters,
                    newOffset, 
                    this.pageSize, 
                    function(resp,evt) {
                        if(resp && evt && evt.status) {
                            rkl.debug.log('resp',resp);
                            var oldOffset = that.offset;
                            that.offset = resp.offset;
                            that.total = resp.total>2000?(2001):resp.total;
                            
                            that.$resultsData.empty();
                            that.$pagerTop.empty();
                            that.$pagerBtm.empty();
                            var amountPickerDialog = that.buildPageSizer(that.$pageSizer);
                            if(resp.records.length === 0) {
                                //need to dynamicly change colSpan
                                $('<tr><td colspan="100">No records found</td></tr>').appendTo(that.$resultsData);
                                return;
                            }
                            
                            var addCell = function($row, content) {
                                if(!content) {
                                    content = '';
                                }
                                var $cell = $('<td></td>').append(content).appendTo($row);
                            }
                            var addCellWLink = function($row, content, id) {
                                if(!content) {

                                    content = ' ';
                                }
                                content = $('<a>'+content+'</a>')
                                        .attr('href','/' + id)
                                        .css('color','#362b36')
                                var $cell = $('<td></td>').append(content).appendTo($row);
                            }
                            var headerFields = Object.keys(that.remoteActionDescribeInfo.resultFields);
                            $.each(resp.records, function(i, rec) {
                                var $row = $('<tr></tr>').appendTo(that.$resultsData);
                                if(that.selectType==="Multi"){
                                    var beenChecked = that.checkedStatus(rec['Id']);
                                    var $checkBox = $('<input/>')
                                        .attr('type','checkbox')
                                        .attr('class',rec['Id'])
                                        .click(function() {
                                            that.setCheckedStatus(rec['Id']);
                                        });

                                    if(that.useORexclude === true){
                                        $checkBox.attr('checked',beenChecked);
                                    } else{
                                        $checkBox.attr('checked',!beenChecked);
                                    }

                                    addCell($row,$checkBox);
                                } else if(that.selectType==="Single"){
                                    var beenChecked = that.checkedStatus(rec['Id']);
                                    var $checkBox = $('<input/>')
                                        .attr('type','radio')
                                        .attr('name','lookup_'+that.controllerData.objectApi)
                                        .attr('class',rec['Id'])
                                        .click(function() {
                                            that.setSelectedStatus(rec['Id']);
                                        });
                                    $checkBox.attr('checked',beenChecked);

                                    addCell($row,$checkBox);
                                }
                                
                                addCellWLink($row, rec[headerFields[0]], rec['Id']);
                                for(var i=1;i<headerFields.length;i++){
                                    addCell($row, rec[headerFields[i]]);
                                }
                                var $clearFilters = $('<div/>')
                                    .css('width','20px');
                                addCell($row,$clearFilters)
                            });
                             
                            var pages = Math.ceil(that.total / that.pageSize);
                            var addPage = function(pg, active) {
                                var item = $('<li></li>');
                                if(active) {
                                    item.addClass('active');
                                }
                                if(pg.text()==81)
                                    rkl.debug.log(pg);
                                item.append(pg);
                                item.appendTo(that.$pagerTop);
                                item.clone(true).appendTo(that.$pagerBtm);
                            };
                            if((that.offset/that.pageSize)-2>0){
                                addPage($('<a href="#">&laquo;&laquo;</a>')
                                    .click(function() {
                                        if(that.offset - that.pageSize >= 0) {
                                            that.updateToOffset(0);
                                        }
                                    })
                                );
                            }
                            if(that.offset - that.pageSize >= 0) {
                                addPage($('<a href="#">&laquo;</a>')
                                    .click(function() {
                                        that.updateToOffset(that.offset - that.pageSize);
                                    })
                                );
                            }
                            $.each(new Array(pages), function(p, o) {
                                var pg = $('<a>' + (p+1) + '</a>')
                                    .attr('href', '#')
                                    .click(function() {
                                        that.updateToOffset(that.pageSize * p);
                                    });
                                if((that.offset/that.pageSize)-2==p){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                } else if((that.offset/that.pageSize)-1==p){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                } else if((that.offset/that.pageSize)-0==p){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                } else if((that.offset/that.pageSize)+1==p && p*that.pageSize<2000){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                } else if((that.offset/that.pageSize)+2==p && p*that.pageSize<2000){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                } else if((that.offset/that.pageSize)-2<0 && (that.offset/that.pageSize)+3==p){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                } else if((that.offset/that.pageSize)-1<0 && (that.offset/that.pageSize)+4==p){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                } else if((((that.total-that.pageSize)-(that.total%that.pageSize)))-that.offset<that.pageSize*1 && ((that.offset)/that.pageSize)-4==p){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                } else if((((that.total+that.pageSize)-(that.total%that.pageSize)))-that.offset<that.pageSize*2 && ((that.offset)/that.pageSize)-3==p){
                                    addPage(pg, (that.offset === (that.pageSize * p)));
                                }
                                
                            });
                            if(that.offset + that.pageSize <= that.total-that.pageSize) {
                                addPage($('<a href="#">&raquo;</a>')
                                    .click(function() {
                                        that.updateToOffset(that.offset + that.pageSize);
                                    })
                                );
                            }
                            if(((that.total-(that.total%that.pageSize)))-that.offset>that.pageSize*3){
                                addPage($('<a href="#">&raquo;&raquo;</a>')
                                    .click(function() {
                                        if(that.offset + that.pageSize <= that.total) {
                                            that.updateToOffset((that.total-(that.total>2000?that.pageSize:0))-(that.total%that.pageSize));
                                        }
                                    })
                                );
                            }
                            if(that.total<resp.total){
                                that.$errorMessage.empty();
                                var $recordMessage = $('<div/>')
                                    .html('A maximum of 2000 records can be returned.<br/>'+(resp.total<30001?resp.total:'30000+')+' records matched your filter criteria.')
                                    .css('color','red')
                                    .css('font-style','italic')
                                that.$errorMessage.append($recordMessage);
                            }
                        } else{
                            that.$resultsData.empty()
                            rkl.debug.log(evt);
                            $('<tr><td colspan="100">Bad Query : '+evt.message+'</td></tr>').appendTo(that.$resultsData);
                            return;
                        }
                    }, 
                    {buffer: false, escape: true, timeout: 5000}
                );
            }
        }
        rkl.genericSearchs[genericSearch.controllerData.objectApi] = genericSearch;
        return genericSearch;
    }

})(jQuery);