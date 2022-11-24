/*
 * Mike Ulveling
 * 
 */
/****************************************************************
        Added to RK base RMIS product as 03/25/2013       
*******************************************************************/

function NestedUIManager() {
    this.construct();
}
NestedUIManager.prototype = new BaseUIManager();
NestedUIManager.instance = null;

NestedUIManager.prototype.construct = function () {
    BaseUIManager.prototype.construct.apply(this, Array.prototype.slice.apply(arguments));
    NestedUIManager.instance = this;
}

NestedUIManager.prototype.$scrollable = function () {
    return $(this.scrollWidget.domNode);
}

;
(function () {
    dojo.addOnLoad(
        function () {
            var ui = NestedUIManager.instance,
                rootPane   = dojo.widget.createWidget('RootSmartLayoutContainer', {widgetId: "mainWindow"}, $('<div/>').appendTo($('body'))[0]),
                scrollPane = dojo.widget.createWidget('ContentPane', { // create the scroll container
                                widgetId: "clientContentPane",
                                layoutAlign: "client", scroll: "xy", hCellAlign: "fill", vCellAlign: "fill",
                                margin: ui.props ? ui.props.scrollContentsMargin : "0 0 0 0"
                            }, $('<div/>')[0]),
                contentPane, vfPageContentNode;
            ui.scrollWidget = scrollPane;
            rootPane.addChild(scrollPane);
            // get our Visualforce Page's core contents root-node, detach it from the document, and remove all its <script> nodes (so they 
            // won't get executed again upon re-attachment of the contents):
            (vfPageContentNode = $('#contentWrapper').detach()).find('script').remove();
            
            contentPane = dojo.widget.createWidget('ContentPane', {layoutAlign:"client"}, $('<div/>').append(vfPageContentNode)[0]);
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
                        marginTop: 4,
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
