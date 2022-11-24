trigger PDFGeneratorPE on Patient_Event__c (after insert, after update) {
    rkl.FormGenerator_Controller.triggerHandler(
        'Initial Reported Patient Event',
        'IM_Status__c',
        'Submitted',
        'Initial_PDF_Created__c',
        'PE',
        'Name'
    );

}