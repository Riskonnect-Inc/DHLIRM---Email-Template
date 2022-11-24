/*
 * Mike Ulveling
 * 
 */
/****************************************************************
        Added to RK base RMIS product as 05/29/2013       
*******************************************************************/

function StandaloneUIManager() {
    this.construct();
}
StandaloneUIManager.prototype = new BaseUIManager();
StandaloneUIManager.instance = null;

StandaloneUIManager.prototype.construct = function () {
    BaseUIManager.prototype.construct.apply(this, Array.prototype.slice.apply(arguments));
    StandaloneUIManager.instance = this;
}

StandaloneUIManager.prototype.$scrollable = function () {
    return $(this.scrollWidget.domNode);
}

;
(function () {
    dojo.addOnLoad(
        function () {
            if (BaseUIManager.bypassInit) {
                return;
            }
            var ui = StandaloneUIManager.instance,
                // detach our Visualforce Page's core content nodes (i.e. the current direct children of the body element):
                $vfContents = $('body').children().detach(),
                rootPane   = dojo.widget.createWidget('RootSmartLayoutContainer', {widgetId: "mainWindow"}, $('<div/>').appendTo($('body'))[0]),
                scrollPane = dojo.widget.createWidget('ContentPane', { // create the scroll container
                                widgetId: "clientContentPane",
                                layoutAlign: "client", scroll: "xy", hCellAlign: "fill", vCellAlign: "fill",
                                margin: ui.props ? ui.props.scrollContentsMargin : "0 0 0 0"
                            }, $('<div/>')[0]),
                contentPane;
            ui.scrollWidget = scrollPane;
            rootPane.addChild(scrollPane);
            // remove all <script> nodes from the Visualforce page's contents, so they won't get executed again upon subsequent re-attachment of the contents:
            $vfContents.find('script').add($vfContents.filter('script')).remove();
            contentPane = dojo.widget.createWidget('ContentPane', {layoutAlign:"client"}, $('<div/>').append($vfContents)[0]);
            scrollPane.addChild(contentPane);
            ui.rootLayout = rootPane;
            // create the uiManager shell's widgets:
            
            if (ui.widgets.statusMessage) {
                var widgetProps = ui.widgets.statusMessage;
                widgetProps.widget = BaseUIManager.newWidgetWithTemplate(rootPane, 'VForceStatusBox', widgetProps);
            }
            if (ui.widgets.submitBlockingPane) {
                var widgetProps = ui.widgets.submitBlockingPane;
                widgetProps.widget = BaseUIManager.newWidgetWithoutTemplate(rootPane, 'IframeBackingWidget', widgetProps);
            }
            if (ui.widgets.timedStatusMessage) {
                var widgetProps = ui.widgets.timedStatusMessage;
                widgetProps.widget = BaseUIManager.newWidgetWithTemplate(rootPane, 'TimedStatusBox', widgetProps);
            }
            if (ui.widgets.dialogs) {
                // if we have dialgs on this page, then create the dialog-controls widget on-the-fly:
                var dialogControlsProps = ui.widgets.dialogControls = {
                    mixins: {
                        layoutAlign: "stack",
                        hCellAlign: "center",
                        vCellAlign: "top",
                        marginTop: 8,
                        zIndex: 502,
                        widgetId: "dialogControlsWidget"
                    },
                    widgetId: "dialogControlsWidget",
                    innerHtml: "<div />",
                    innerHtmlDojoAttachPoint: "contentPlaceholder"
                };
                dialogControlsProps.widget = BaseUIManager.newWidgetWithTemplate(rootPane, 'DialogControls', dialogControlsProps);
                // TODO: add a check for the dialog script file's existence...
                for (var dialogKey in ui.widgets.dialogs) {
                    var dialogProps = ui.widgets.dialogs[dialogKey];
                    // set a reference to the dojo widget - for use by the DialogManager
                    dialogProps.widget = BaseUIManager.newWidgetWithoutTemplate(rootPane, 'VForceDialog', dialogProps);
                }
            }
            rootPane._layout();
        });
})();
